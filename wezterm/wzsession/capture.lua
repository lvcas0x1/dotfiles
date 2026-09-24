local wezterm = require("wezterm")

local M = {}

-- Scrollback lines captured per pane. Every line is stored with its escape
-- sequences intact, so this is the main driver of state file size.
M.max_scrollback_lines = 5000

-- A pane whose foreground process is one of these was simply sitting at a
-- prompt: there is no application to relaunch.
local SHELLS = {
	zsh = true,
	bash = true,
	sh = true,
	dash = true,
	fish = true,
	nu = true,
	ksh = true,
	csh = true,
	tcsh = true,
	["zsh-5.9"] = true,
	["login"] = true,
}

local function basename(p)
	if not p or p == "" then
		return nil
	end
	local b = p:gsub("^.*[/\\]", "")
	return b
end

---Command line to relaunch in this pane, or nil if it held only a shell.
---@return string|nil cmd
---@return string|nil process_name
local function foreground_command(pane)
	-- get_foreground_process_info returns nil for panes whose process has gone
	-- away, and has been observed to error outright on some panes.
	local ok, info = pcall(function()
		return pane:get_foreground_process_info()
	end)
	if not ok or not info then
		return nil, nil
	end

	local exe = basename(info.executable)
	local name = basename(info.name) or exe
	if exe and SHELLS[exe] then
		return nil, name
	end
	if name and SHELLS[name] then
		return nil, name
	end

	local argv = info.argv
	if not argv or #argv == 0 then
		return nil, name
	end
	-- A login shell shows up as argv[1] == "-zsh"; treat it as a bare shell.
	local first = basename(argv[1]) or ""
	if SHELLS[first:gsub("^%-", "")] then
		return nil, name
	end

	return wezterm.shell_join_args(argv), name, argv, info.pid
end

---Read one user var off a pane.
---Deliberately does not type-check the container: wezterm hands some of these
---collections back as userdata proxies rather than tables, and indexing works
---on both. Checking for "table" is what silently broke the autosave bindings.
local function pane_user_var(pane, key)
	local ok, value = pcall(function()
		local vars = pane:get_user_vars()
		if vars == nil then
			return nil
		end
		return vars[key]
	end)
	if ok and type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

-- Where the Claude Code SessionStart hook drops its session-id hints.
-- Set from init.setup(); see ~/.config/claude/hooks/wzsession-session-id.py
M.pane_hint_dir = nil

---Session id published by the hook for this pane, or nil.
---The hint carries the pid of the claude process that wrote it, and is only
---trusted when that matches the process the pane is actually running. A nested
---claude (e.g. a one-shot `claude -p` fired from inside a session) writes to
---the same pane file but has a different pid, and must not be believed.
---@param pane_id integer
---@param fg_pid integer|nil pid of the pane's foreground process
---@return string|nil
local function pane_session_hint(pane_id, fg_pid)
	if not M.pane_hint_dir or not fg_pid then
		return nil
	end

	local path = string.format("%s/%d.json", M.pane_hint_dir, pane_id)
	local fh = io.open(path, "r")
	if not fh then
		return nil
	end
	local raw = fh:read("*a")
	fh:close()
	if not raw or raw == "" then
		return nil
	end

	local ok, hint = pcall(wezterm.json_parse, raw)
	if not ok or hint == nil then
		return nil
	end

	local hint_pid = tonumber(hint.pid)
	local session_id = hint.session_id
	if type(session_id) ~= "string" or session_id == "" then
		return nil
	end

	if hint_pid ~= fg_pid then
		wezterm.log_info(
			string.format(
				"wzsession: ignoring session hint for pane %d (hint pid %s, pane pid %s)",
				pane_id,
				tostring(hint_pid),
				tostring(fg_pid)
			)
		)
		return nil
	end

	return session_id
end

-- Flags by which claude selects a conversation. Dropped and replaced with the
-- id the SessionStart hook published, which is authoritative for this pane.
local CLAUDE_FLAG_WITH_VALUE = { ["--resume"] = true, ["-r"] = true, ["--session-id"] = true }
local CLAUDE_FLAG_BARE = { ["-c"] = true, ["--continue"] = true }

---Rewrite a claude invocation so it reopens *this pane's* conversation.
---A bare `claude` would restore an empty session, and `claude -c` would resume
---whatever conversation was most recent in the directory -- the wrong one as
---soon as a second claude runs in the same cwd.
---@param argv string[]
---@param session_id string|nil
---@return string[] argv
local function apply_claude_session(argv, session_id)
	if not session_id or not argv or #argv == 0 then
		return argv
	end
	local exe = basename(argv[1]) or ""
	if exe ~= "claude" then
		return argv
	end

	local out, i = { argv[1] }, 2
	while i <= #argv do
		local a = argv[i]
		if CLAUDE_FLAG_WITH_VALUE[a] then
			-- --resume takes an optional value; skip it when present
			local nxt = argv[i + 1]
			if nxt and nxt:sub(1, 1) ~= "-" then
				i = i + 1
			end
		elseif CLAUDE_FLAG_BARE[a] then
			-- drop
		elseif a:match("^%-%-resume=") or a:match("^%-%-session%-id=") then
			-- drop
		else
			out[#out + 1] = a
		end
		i = i + 1
	end

	out[#out + 1] = "--resume"
	out[#out + 1] = session_id
	return out
end

---Exposed for tests.
M._apply_claude_session = apply_claude_session

---True when the pane is sitting at a shell prompt rather than running an app.
---Used before typing a restored command into a pane that is being reused.
function M.is_at_shell(pane)
	local cmd = foreground_command(pane)
	return cmd == nil
end

local function pane_cwd(pane)
	local ok, cwd = pcall(function()
		return pane:get_current_working_dir()
	end)
	if not ok or not cwd then
		return nil
	end
	-- Url object since 20240127; older builds handed back a plain string.
	if type(cwd) == "string" then
		local path = cwd:gsub("^file://[^/]*", "")
		return path ~= "" and path or nil
	end
	return cwd.file_path
end

local function pane_text(pane)
	-- While a full-screen TUI owns the alternate screen its buffer is the app's
	-- rendering, not scrollback. Injecting it back would paint garbage over the
	-- relaunched app, so the command is restored instead of the text.
	local alt_ok, alt = pcall(function()
		return pane:is_alt_screen_active()
	end)
	if alt_ok and alt then
		return nil
	end

	local dim_ok, dims = pcall(function()
		return pane:get_dimensions()
	end)
	if not dim_ok or not dims then
		return nil
	end

	local n = math.min(dims.scrollback_rows or 0, M.max_scrollback_lines)
	if n <= 0 then
		return nil
	end

	-- get_lines_as_escapes keeps colour and styling; fall back to plain text on
	-- builds that predate it.
	local ok, txt = pcall(function()
		return pane:get_lines_as_escapes(n)
	end)
	if ok and txt then
		return txt
	end
	ok, txt = pcall(function()
		return pane:get_lines_as_text(n)
	end)
	if ok and txt then
		return txt
	end
	return nil
end

local function leaf_of(info)
	local pane = info.pane

	local domain = "local"
	local dok, dname = pcall(function()
		return pane:get_domain_name()
	end)
	if dok and dname then
		domain = dname
	end

	local alt_ok, alt = pcall(function()
		return pane:is_alt_screen_active()
	end)

	local cmd, proc, argv, fg_pid = foreground_command(pane)

	-- Claude Code publishes its session id through a SessionStart hook; see
	-- ~/.config/claude/hooks/wzsession-session-id.py. The pid-validated file is the
	-- primary route; the user var is a secondary one that only works if the
	-- escape sequence made it through.
	local pane_id
	local pok, pid_val = pcall(function()
		return pane:pane_id()
	end)
	if pok then
		pane_id = pid_val
	end

	local claude_session
	if pane_id then
		claude_session = pane_session_hint(pane_id, fg_pid)
	end
	claude_session = claude_session or pane_user_var(pane, "claude_session_id")
	if cmd and argv and claude_session then
		local rewritten = apply_claude_session(argv, claude_session)
		if rewritten ~= argv then
			cmd = wezterm.shell_join_args(rewritten)
		end
	end

	return {
		kind = "leaf",
		cwd = pane_cwd(pane),
		domain = domain,
		is_active = info.is_active and true or false,
		alt_screen = (alt_ok and alt) and true or false,
		cmd = cmd,
		proc = proc,
		claude_session = claude_session,
		-- inject_output only works on local panes.
		text = (domain == "local") and pane_text(pane) or nil,
	}
end

local function extent(panes, pos, size)
	local lo, hi = math.huge, -math.huge
	for _, p in ipairs(panes) do
		lo = math.min(lo, p[pos])
		hi = math.max(hi, p[pos] + p[size] - 1)
	end
	return lo, hi
end

---Find the single full-width/full-height divider that cuts this set of panes
---in two, along the given axis.
---@return table|nil first
---@return table|nil second
---@return number|nil frac fraction of the region belonging to `second`
local function split_on(panes, axis)
	local pos, size = "left", "width"
	if axis == "y" then
		pos, size = "top", "height"
	end

	local lo, hi = extent(panes, pos, size)

	local seen, candidates = {}, {}
	for _, p in ipairs(panes) do
		local b = p[pos] + p[size] -- the divider occupies this column/row
		if b <= hi and not seen[b] then
			seen[b] = true
			candidates[#candidates + 1] = b
		end
	end
	table.sort(candidates)

	for _, b in ipairs(candidates) do
		local first, second = {}, {}
		for _, p in ipairs(panes) do
			if p[pos] + p[size] <= b then
				first[#first + 1] = p
			elseif p[pos] >= b + 1 then
				second[#second + 1] = p
			end
		end
		-- A valid cut leaves no pane straddling the divider.
		if #first > 0 and #second > 0 and #first + #second == #panes then
			local first_extent = b - lo
			local second_extent = hi - b
			local total = first_extent + second_extent
			local frac = total > 0 and (second_extent / total) or 0.5
			return first, second, frac
		end
	end
	return nil
end

---WezTerm only ever builds guillotine layouts: any arrangement it can produce
---can be cut in two by one straight divider. Recursively finding that cut
---recovers the exact sequence of splits that created the layout.
local function decompose(panes)
	if #panes == 0 then
		return nil
	end
	if #panes == 1 then
		return leaf_of(panes[1])
	end

	for _, axis in ipairs({ "x", "y" }) do
		local first, second, frac = split_on(panes, axis)
		if first then
			return {
				kind = "split",
				axis = axis,
				frac = frac,
				first = decompose(first),
				second = decompose(second),
			}
		end
	end

	-- Unreachable for layouts wezterm itself produced. Degrade to a row of
	-- even splits rather than silently dropping panes.
	wezterm.log_warn("wzsession: unrecognised pane layout, flattening " .. #panes .. " panes")
	local head = table.remove(panes, 1)
	return {
		kind = "split",
		axis = "x",
		frac = 1 - 1 / (#panes + 1),
		first = leaf_of(head),
		second = decompose(panes),
	}
end

function M.tab_state(tab)
	-- panes_with_info reports a zoomed pane at the full size of the tab, which
	-- would flatten the layout to a single leaf. Un-zoom across the capture.
	local was_zoomed = false
	local zok, prev = pcall(function()
		return tab:set_zoomed(false)
	end)
	if zok and prev then
		was_zoomed = true
	end

	local infos = tab:panes_with_info()
	local state = {
		title = tab:get_title(),
		is_zoomed = was_zoomed,
		layout = decompose(infos),
	}

	if was_zoomed then
		pcall(function()
			tab:set_zoomed(true)
		end)
	end

	return state
end

function M.window_state(mux_win)
	local tabs = {}
	local infos = mux_win:tabs_with_info()
	for _, ti in ipairs(infos) do
		local st = M.tab_state(ti.tab)
		st.is_active = ti.is_active and true or false
		tabs[#tabs + 1] = st
	end

	local size
	if infos[1] then
		local ok, s = pcall(function()
			return infos[1].tab:get_size()
		end)
		if ok then
			size = s
		end
	end

	return {
		title = mux_win:get_title(),
		size = size,
		tabs = tabs,
	}
end

---Cheap structural signature of one tab, used by the autosaver to decide
---whether a write is worth doing. Deliberately excludes scrollback text: this
---runs on a timer and must stay far cheaper than a full capture.
function M.tab_fingerprint(tab)
	local ok, infos = pcall(function()
		return tab:panes_with_info()
	end)
	if not ok or not infos then
		return ""
	end

	local parts = { tostring(tab:get_title()) }
	for _, pi in ipairs(infos) do
		local rows = 0
		local dok, d = pcall(function()
			return pi.pane:get_dimensions()
		end)
		if dok and d then
			rows = d.scrollback_rows or 0
		end
		parts[#parts + 1] = table.concat({
			pi.left,
			pi.top,
			pi.width,
			pi.height,
			pi.is_zoomed and "z" or "-",
			pane_cwd(pi.pane) or "",
			foreground_command(pi.pane) or "",
			rows,
		}, ",")
	end
	-- The fingerprint is round-tripped through JSON in wezterm.GLOBAL, and
	-- wezterm.json_encode emits raw control bytes as-is. A tab title or command
	-- containing one would make the stored state unparseable, which would
	-- silently drop every binding.
	local fp = table.concat(parts, "|"):gsub("[%c]", "?")
	return fp
end

---Capture a single tab as a complete state document.
---The schema stays "windows[1].tabs[1]" so the restorer needs no special case.
---@param name string
---@param tab MuxTab
function M.tab_session_state(name, tab)
	local tab_state = M.tab_state(tab)
	tab_state.is_active = true

	local window_title, size
	local wok, mux_win = pcall(function()
		return tab:window()
	end)
	if wok and mux_win then
		local tok, t = pcall(function()
			return mux_win:get_title()
		end)
		if tok then
			window_title = t
		end
	end
	local sok, s = pcall(function()
		return tab:get_size()
	end)
	if sok then
		size = s
	end

	local workspace
	local pok, ws = pcall(wezterm.mux.get_active_workspace)
	if pok then
		workspace = ws
	end

	return {
		schema = 1,
		name = name,
		workspace = workspace,
		saved_at = wezterm.time.now():format("%Y-%m-%d %H:%M:%S"),
		wezterm_version = wezterm.version,
		windows = {
			{ title = window_title, size = size, tabs = { tab_state } },
		},
	}
end

return M
