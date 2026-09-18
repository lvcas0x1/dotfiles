-- wzsession -- named session save/restore for WezTerm.
--
-- Vendored deliberately: no wezterm.plugin.require, no external plugin
-- dependency, so nothing here can break when an upstream repository moves or
-- is archived. State lives on disk as JSON and therefore survives a reboot.

local wezterm = require("wezterm")
local act = wezterm.action

local util = require("wzsession.util")
local capture = require("wzsession.capture")
local restore = require("wzsession.restore")
local autosave = require("wzsession.autosave")

local M = {}

M.opts = {
	-- Scrollback can contain tokens, hostnames and command output, so state is
	-- kept out of the ~/.config git repository by default.
	dir = (os.getenv("HOME") or ".") .. "/.local/share/wezterm-session",
	max_scrollback_lines = 5000,
	register_command_palette = true,
	shell_command = true,
	restore_opts = {},

	-- Per-tab autosave. A tab is only autosaved once it has been saved or
	-- restored under a name; see autosave.lua.
	autosave = {},
}

M.autosave = autosave

local function state_path(name)
	return M.opts.dir .. util.separator .. util.slug(name) .. ".json"
end

local function notify(window, msg)
	wezterm.log_info("wzsession: " .. msg)
	if window then
		window:toast_notification("wzsession", msg, nil, 3000)
	end
end

--------------------------------------------------------------------- core API

---Save one tab under `name`. Pure: writes the file and nothing else, so the
---autosaver can call it on a timer without re-triggering bindings.
---@param name string
---@param tab MuxTab
function M.save(name, tab)
	if not name or name == "" then
		return false, "no session name given"
	end
	if not tab then
		return false, "no tab given"
	end
	local state = capture.tab_session_state(name, tab)
	local ok, err = util.write_json(state_path(name), state)
	if not ok then
		return false, err
	end
	local n = 0
	local pok, panes = pcall(function()
		return tab:panes()
	end)
	if pok and panes then
		n = #panes
	end
	return true, string.format("%d pane(s)", n)
end

---Save `tab` and switch autosave on for it.
function M.save_and_bind(name, tab)
	local ok, info = M.save(name, tab)
	if ok and tab then
		autosave.bind(tab:tab_id(), name)
	end
	return ok, info
end

---@return {name: string, saved_at: string|nil, path: string}[]
function M.list()
	local out = {}
	for _, path in ipairs(util.list_json(M.opts.dir)) do
		local state = util.read_json(path)
		out[#out + 1] = {
			name = (state and state.name) or util.basename(path),
			saved_at = state and state.saved_at or nil,
			path = path,
		}
	end
	return out
end

---Load `name` from disk and rebuild it.
---`restore_opts.gui_window` / `.mux_window` / `.pane` describe where it lands;
---the default target ("current_tab") needs all three.
function M.load(name, restore_opts)
	local state, err = util.read_json(state_path(name))
	if not state then
		return false, err
	end
	local ok, info, tab = restore.restore(state, util.merge(M.opts.restore_opts, restore_opts))
	if ok and tab then
		-- Restoring counts as naming the tab, so autosave takes over from here.
		autosave.bind(tab:tab_id(), name)
	end
	return ok, info
end

---Build the where-to-put-it options from a live window/pane pair.
local function target_of(window, pane)
	return {
		gui_window = window,
		mux_window = window and window:mux_window() or nil,
		pane = pane,
	}
end

function M.delete(name)
	local ok = os.remove(state_path(name))
	if not ok then
		return false, "could not remove " .. state_path(name)
	end
	return true
end

------------------------------------------------------------------- ui actions

---Prompt for a name, then save. Defaults to the current workspace name.
---Wrapped in a callback because the Mux does not exist while the config is
---being evaluated, and initial_value has to be read from it.
function M.save_action()
	return wezterm.action_callback(function(window, pane)
		window:perform_action(
			act.PromptInputLine({
				description = wezterm.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Text = "Save session as:" },
				}),
				initial_value = wezterm.mux.get_active_workspace(),
				action = wezterm.action_callback(function(inner_window, inner_pane, line)
					if not line or line == "" then
						return
					end
					local ok, info = M.save_and_bind(line, inner_pane:tab())
					if ok then
						notify(inner_window, string.format("saved '%s' (%s, autosave on)", line, info))
					else
						notify(inner_window, "save failed: " .. tostring(info))
					end
				end),
			}),
			pane
		)
	end)
end

local function session_choices()
	local choices = {}
	for _, s in ipairs(M.list()) do
		local label = s.name
		if s.saved_at then
			label = string.format("%-24s  %s", s.name, s.saved_at)
		end
		choices[#choices + 1] = { id = s.name, label = label }
	end
	return choices
end

---Pick a saved session and rebuild it.
function M.restore_action()
	return wezterm.action_callback(function(window, pane)
		local choices = session_choices()
		if #choices == 0 then
			notify(window, "no saved sessions in " .. M.opts.dir)
			return
		end
		window:perform_action(
			act.InputSelector({
				title = "Restore session",
				fuzzy = true,
				fuzzy_description = "Restore session: ",
				choices = choices,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if not id then
						return
					end
					local ok, info = M.load(id, target_of(inner_window, inner_pane))
					if ok then
						notify(inner_window, string.format("restored '%s' (%s)", id, tostring(info)))
					else
						notify(inner_window, "restore failed: " .. tostring(info))
					end
				end),
			}),
			pane
		)
	end)
end

function M.delete_action()
	return wezterm.action_callback(function(window, pane)
		local choices = session_choices()
		if #choices == 0 then
			notify(window, "no saved sessions")
			return
		end
		window:perform_action(
			act.InputSelector({
				title = "Delete session",
				fuzzy = true,
				fuzzy_description = "Delete session: ",
				choices = choices,
				action = wezterm.action_callback(function(inner_window, _, id)
					if not id then
						return
					end
					-- Otherwise the next autosave tick would recreate the file.
					for tab_id, name in pairs(autosave.bindings()) do
						if name == id then
							autosave.unbind(tonumber(tab_id) or tab_id)
						end
					end
					local ok, err = M.delete(id)
					notify(inner_window, ok and ("deleted '" .. id .. "'") or tostring(err))
				end),
			}),
			pane
		)
	end)
end

---Entries merged into the command palette (CTRL+SHIFT+P).
function M.palette_entries()
	return {
		{
			brief = "Session: save current workspace",
			icon = "md_content_save",
			action = M.save_action(),
		},
		{
			brief = "Session: restore saved session",
			icon = "md_restore",
			action = M.restore_action(),
		},
		{
			brief = "Session: delete saved session",
			icon = "md_delete",
			action = M.delete_action(),
		},
	}
end

---Append key assignments without disturbing existing ones.
---SHIFT|CTRL s / o / d are unbound in both wezterm's defaults and this config.
function M.apply_keys(config)
	config.keys = config.keys or {}
	local keys = {
		{ key = "s", mods = "CTRL|SHIFT", action = M.save_action() },
		{ key = "o", mods = "CTRL|SHIFT", action = M.restore_action() },
		{ key = "d", mods = "CTRL|SHIFT", action = M.delete_action() },
	}
	for _, k in ipairs(keys) do
		table.insert(config.keys, k)
	end
	return config
end

------------------------------------------------------------------------ setup

function M.setup(user_opts)
	M.opts = util.merge(M.opts, user_opts)
	util.ensure_dir(M.opts.dir)
	capture.max_scrollback_lines = M.opts.max_scrollback_lines
	capture.pane_hint_dir = M.opts.dir .. util.separator .. "panes"

	if M.opts.register_command_palette then
		-- Only the first handler that returns a value wins for this event. If
		-- this config ever grows its own augment-command-palette handler, set
		-- register_command_palette = false and splice M.palette_entries() into
		-- it instead.
		wezterm.on("augment-command-palette", function()
			return M.palette_entries()
		end)
	end

	if M.opts.shell_command then
		-- Lets a shell function drive a restore; see the wzs() helper in zshrc.
		wezterm.on("user-var-changed", function(window, pane, name, value)
			if name ~= "wzsession" or not value or value == "" then
				return
			end
			local verb, arg = value:match("^(%a+):?(.*)$")
			if verb == "restore" and arg ~= "" then
				local ok, info = M.load(arg, target_of(window, pane))
				notify(
					window,
					ok and string.format("restored '%s' (%s)", arg, tostring(info))
						or ("restore failed: " .. tostring(info))
				)
			elseif verb == "save" then
				local target = (arg ~= "") and arg or wezterm.mux.get_active_workspace()
				local ok, info = M.save_and_bind(target, pane and pane:tab() or nil)
				notify(
					window,
					ok and string.format("saved '%s' (%s, autosave on)", target, tostring(info))
						or ("save failed: " .. tostring(info))
				)
			end
		end)
	end

	autosave.setup(M.opts.autosave, M.save)

	return M
end

return M
