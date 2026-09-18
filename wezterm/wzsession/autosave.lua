-- Per-tab autosave.
--
-- A tab is only ever autosaved after it has been saved (or restored) under a
-- name at least once. That binding is what makes autosave safe: a tab nobody
-- named is never written, so a fresh window cannot clobber a saved state --
-- the problem tmux-continuum works around with
-- delay_saving_environment_on_first_plugin_load.
--
-- wezterm offers no event for layout mutations and none for shutdown, so a
-- timer plus "window lost focus" is the best precision available. Changes made
-- within the last interval are lost if wezterm is killed.

local wezterm = require("wezterm")
local util = require("wzsession.util")
local capture = require("wzsession.capture")

local M = {}

M.defaults = {
	enabled = true,

	interval_seconds = 60,

	-- Anti-thrash floor between two writes of the same tab. Kept small on
	-- purpose: the focus trigger is often the last chance to save before
	-- wezterm is quit, and a large floor silently swallows that write.
	-- Rapid no-op focus changes are already stopped by the fingerprint check.
	min_interval_seconds = 2,

	-- Write even when the fingerprint is unchanged once the saved state is this
	-- old, so scrollback in a long-running tab does not go stale.
	max_stale_seconds = 600,

	-- Save when the window loses focus: the closest thing wezterm gives us to
	-- saving on the way out.
	on_blur = true,
}

M.opts = M.defaults
M.save_fn = nil

------------------------------------------------------------------ global state

-- wezterm.GLOBAL is userdata: a table written into it reads back as a userdata
-- proxy, so `type(x) == "table"` is false for it. Storing a JSON string instead
-- keeps this a plain Lua table on both sides, with no proxy semantics to get
-- wrong. The state is a handful of short strings, so the encode/decode is free.
local KEY = "wzsession_state"

local function blank()
	return { generation = 0, bound = {}, last_save = {}, last_fp = {} }
end

-- Used only if wezterm.GLOBAL is unavailable. Bindings then live for one config
-- generation instead of the process lifetime -- a graceful degradation rather
-- than a config that refuses to load.
local fallback = nil

local function normalise(g)
	if type(g) ~= "table" then
		return blank()
	end
	g.generation = tonumber(g.generation) or 0
	g.bound = type(g.bound) == "table" and g.bound or {}
	g.last_save = type(g.last_save) == "table" and g.last_save or {}
	g.last_fp = type(g.last_fp) == "table" and g.last_fp or {}
	return g
end

local function gget()
	if wezterm.GLOBAL == nil then
		return normalise(fallback)
	end
	local raw = wezterm.GLOBAL[KEY]
	if type(raw) ~= "string" or raw == "" then
		return blank()
	end
	local ok, parsed = pcall(wezterm.json_parse, raw)
	if not ok then
		wezterm.log_error("wzsession: could not parse autosave state, resetting")
		return blank()
	end
	return normalise(parsed)
end

local function gmutate(fn)
	local g = gget()
	local result = fn(g)
	if wezterm.GLOBAL == nil then
		fallback = g
		return result
	end
	local ok, encoded = pcall(wezterm.json_encode, g)
	if ok then
		wezterm.GLOBAL[KEY] = encoded
	else
		wezterm.log_error("wzsession: could not store autosave state: " .. tostring(encoded))
	end
	return result
end

--------------------------------------------------------------------- bindings

---Bind a tab to a session name. Called after a manual save and after a
---restore, and it is what switches autosave on for that tab.
---@param tab_id integer
---@param name string
function M.bind(tab_id, name)
	gmutate(function(g)
		g.bound[tostring(tab_id)] = name
		-- Force the next tick to write, so the binding takes effect promptly.
		g.last_fp[tostring(tab_id)] = nil
	end)
end

function M.unbind(tab_id)
	gmutate(function(g)
		local k = tostring(tab_id)
		g.bound[k] = nil
		g.last_save[k] = nil
		g.last_fp[k] = nil
	end)
end

---@return string|nil name this tab autosaves to
function M.bound(tab_id)
	return gget().bound[tostring(tab_id)]
end

---@return table<string, string> every live binding, tab_id -> name
function M.bindings()
	return gget().bound
end

------------------------------------------------------------------------ saving

---Save one bound tab if the guards allow it.
---@return boolean whether a write happened
local function save_tab(tab, name, reason, now)
	local key = tostring(tab:tab_id())
	local g = gget()

	local last = g.last_save[key] or 0
	if now - last < M.opts.min_interval_seconds then
		return false
	end

	local fp = capture.tab_fingerprint(tab)
	local changed = fp ~= g.last_fp[key]
	local stale = (now - last) >= M.opts.max_stale_seconds
	if not changed and not stale then
		return false
	end

	local ok, info = M.save_fn(name, tab)
	if not ok then
		wezterm.log_error(string.format("wzsession: autosave of '%s' failed: %s", name, tostring(info)))
		return false
	end

	gmutate(function(gg)
		gg.last_save[key] = now
		gg.last_fp[key] = fp
	end)
	wezterm.log_info(
		string.format(
			"wzsession: autosaved tab %s -> '%s' (%s, %s)",
			key,
			name,
			reason,
			changed and "changed" or "stale refresh"
		)
	)
	return true
end

---Walk every tab of every window, save the bound ones, and drop bindings whose
---tab has gone away so GLOBAL does not grow without bound.
---@param reason string
function M.tick(reason)
	if not M.save_fn then
		return 0
	end

	local now = os.time()
	local live, written = {}, 0

	local ok, windows = pcall(wezterm.mux.all_windows)
	if not ok or not windows then
		return 0
	end

	for _, win in ipairs(windows) do
		local tok, tabs = pcall(function()
			return win:tabs()
		end)
		if tok and tabs then
			for _, tab in ipairs(tabs) do
				local key = tostring(tab:tab_id())
				live[key] = true
				local name = M.bound(tab:tab_id())
				if name then
					local wrote = false
					local sok, serr = pcall(function()
						wrote = save_tab(tab, name, reason, now)
					end)
					if not sok then
						wezterm.log_error("wzsession: autosave error: " .. tostring(serr))
					elseif wrote then
						written = written + 1
					end
				end
			end
		end
	end

	gmutate(function(g)
		for key in pairs(g.bound) do
			if not live[key] then
				g.bound[key] = nil
				g.last_save[key] = nil
				g.last_fp[key] = nil
			end
		end
	end)

	return written
end

------------------------------------------------------------------------- setup

local function arm(generation)
	wezterm.time.call_after(M.opts.interval_seconds, function()
		-- A config reload bumps the generation and arms a fresh timer. Without
		-- this check the old timers keep running too, and every reload would
		-- multiply the number of concurrent savers.
		if gget().generation ~= generation then
			return
		end
		pcall(M.tick, "timer")
		arm(generation)
	end)
end

---@param opts table|nil
---@param save_fn fun(name: string, tab: any): boolean, string injected by init
function M.setup(opts, save_fn)
	M.opts = util.merge(M.defaults, opts)
	M.save_fn = save_fn

	if not M.opts.enabled then
		return M
	end

	local generation = gmutate(function(g)
		g.generation = g.generation + 1
		return g.generation
	end)

	arm(generation)

	if M.opts.on_blur then
		-- Duplicate handlers from earlier config reloads are harmless:
		-- min_interval_seconds collapses the extra calls.
		wezterm.on("window-focus-changed", function(window)
			local ok, focused = pcall(function()
				return window:is_focused()
			end)
			if ok and focused == false then
				pcall(M.tick, "blur")
			end
		end)
	end

	return M
end

return M
