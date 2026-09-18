local wezterm = require("wezterm")
local act = wezterm.action
local util = require("wzsession.util")
local capture = require("wzsession.capture")

local M = {}

M.defaults = {
	-- Where the layout is rebuilt:
	--   "current_tab" reuses the tab and pane the command was invoked from
	--   "tab"         appends new tabs to the current window
	--   "window"      spawns a new window in a workspace of the session's name
	target = "current_tab",

	-- A layout needs an empty tab to expand into, so leftover panes in the
	-- reused tab are closed. Turning this off nests the restored layout inside
	-- the active pane instead, which will not match the saved geometry.
	close_other_panes = true,

	-- Press Enter for the restored command instead of only typing it.
	auto_run = true,

	-- Commands matching any of these are typed but never executed, even when
	-- auto_run is on. Lua patterns, matched against the whole command line.
	no_auto_run = {
		"^rm%s",
		"%f[%w]rm%s+%-",
		"terraform%s+apply",
		"terraform%s+destroy",
		"kubectl%s+delete",
		"git%s+push",
		"%f[%w]shutdown%f[%W]",
		"%f[%w]reboot%f[%W]",
		"%f[%w]dd%s",
	},

	-- Scrollback is injected into the terminal model, so a short fixed wait is
	-- enough for it.
	text_delay = 0.6,

	-- Commands are typed into a shell, so they must not be sent before that
	-- shell is reading input. A cold interactive zsh here takes ~3.6s
	-- (oh-my-zsh + powerlevel10k), so a fixed delay is the wrong tool: these
	-- bound a readiness poll instead. cmd_delay is the earliest we look,
	-- cmd_timeout the point at which we send anyway.
	cmd_delay = 0.5,
	cmd_poll_interval = 0.25,
	cmd_timeout = 20,

	-- Stagger per pane so a many-pane restore does not fire everything at once.
	stagger = 0.05,

	-- Match the maximised-window behaviour of the gui-startup handler.
	maximize = true,

	-- Restoring the saved pixel size fights window_decorations = "RESIZE".
	resize_window = false,
}

local function blocked(cmd, patterns)
	for _, p in ipairs(patterns or {}) do
		if cmd:find(p) then
			return true
		end
	end
	return false
end

local function first_leaf_of(node)
	while node and node.kind == "split" do
		node = node.first
	end
	return node
end

---Call `fn` once the pane's shell looks ready to accept a typed command.
---Ready means: the foreground process is a shell (so we are at a prompt, not
---inside some startup program) and the cursor has stopped moving (so the prompt
---has finished drawing). A cold interactive zsh with oh-my-zsh and
---powerlevel10k takes seconds here, and anything typed before the line editor
---is up is simply lost -- which is why this polls instead of guessing.
---@param fn fun(reason: string)
local function when_shell_ready(pane, opts, offset, fn)
	local deadline = os.time() + (opts.cmd_timeout or 20)
	local last_cursor

	local function poll()
		local settled = false

		local cok, cursor = pcall(function()
			local c = pane:get_cursor_position()
			return c and (tostring(c.x) .. "," .. tostring(c.y)) or nil
		end)
		if cok and cursor then
			settled = (last_cursor ~= nil and cursor == last_cursor)
			last_cursor = cursor
		end

		local at_shell = capture.is_at_shell(pane)

		if at_shell and settled then
			fn("ready")
			return
		end
		if os.time() >= deadline then
			fn(at_shell and "timeout, cursor still moving" or "timeout, shell not at prompt")
			return
		end
		wezterm.time.call_after(opts.cmd_poll_interval or 0.25, poll)
	end

	wezterm.time.call_after((opts.cmd_delay or 0.5) + offset, poll)
end

local function restore_pane(pane, leaf, opts, acc)
	acc.n = (acc.n or 0) + 1
	local offset = acc.n * (opts.stagger or 0)

	if leaf.text and leaf.text ~= "" then
		local text = leaf.text:gsub("%s+$", "")
		wezterm.time.call_after(opts.text_delay + offset, function()
			local ok, err = pcall(function()
				pane:inject_output(text .. "\r\n")
			end)
			if not ok then
				wezterm.log_error("wzsession: inject_output failed: " .. tostring(err))
			end
		end)
	end

	if leaf.cmd and leaf.cmd ~= "" then
		-- The reused pane may already be running something (this is the pane the
		-- restore was triggered from). Typing into it would land in that app.
		if opts._busy_root_id and pane:pane_id() == opts._busy_root_id then
			wezterm.log_warn(
				"wzsession: reused pane is running an application; skipping '" .. leaf.cmd .. "'"
			)
			return
		end
		local auto = opts.auto_run and not blocked(leaf.cmd, opts.no_auto_run)
		when_shell_ready(pane, opts, offset, function(reason)
			local ok, err = pcall(function()
				pane:send_text(leaf.cmd .. (auto and "\r" or ""))
			end)
			wezterm.log_info(
				string.format(
					"wzsession: %s pane %s (%s%s): %s",
					ok and "sent to" or "FAILED sending to",
					tostring(pane:pane_id()),
					reason,
					auto and ", autorun" or ", typed only",
					ok and leaf.cmd or tostring(err)
				)
			)
		end)
	end
end

local function build(pane, node, opts, acc)
	if node == nil then
		return
	end

	if node.kind == "leaf" then
		if node.is_active then
			acc.active_pane = pane
		end
		restore_pane(pane, node, opts, acc)
		return
	end

	local args = {
		direction = (node.axis == "x") and "Right" or "Bottom",
		size = math.max(0.05, math.min(0.95, node.frac or 0.5)),
	}

	local seed = first_leaf_of(node.second)
	if seed then
		if seed.cwd then
			args.cwd = seed.cwd
		end
		if seed.domain and seed.domain ~= "local" then
			args.domain = { DomainName = seed.domain }
		end
	end

	local ok, new_pane = pcall(function()
		return pane:split(args)
	end)
	if not ok or not new_pane then
		wezterm.log_error("wzsession: split failed: " .. tostring(new_pane))
		-- Keep going: the remaining panes of `first` are still recoverable.
		build(pane, node.first, opts, acc)
		return
	end

	build(pane, node.first, opts, acc)
	build(new_pane, node.second, opts, acc)
end

local function restore_tab(tab, first_pane, tab_state, opts, acc)
	if tab_state.title and tab_state.title ~= "" then
		pcall(function()
			tab:set_title(tab_state.title)
		end)
	end

	build(first_pane, tab_state.layout, opts, acc)

	if tab_state.is_zoomed then
		pcall(function()
			tab:set_zoomed(true)
		end)
	end
end

---Close every pane of `tab` except `keep_pane`. There is no Lua API to kill a
---pane, so this goes through the GUI window's CloseCurrentPane action.
local function close_other_panes(gui_window, tab, keep_pane)
	if not gui_window then
		return 0
	end
	local closed = 0
	for _, p in ipairs(tab:panes()) do
		if p:pane_id() ~= keep_pane:pane_id() then
			local ok = pcall(function()
				p:activate()
				gui_window:perform_action(act.CloseCurrentPane({ confirm = false }), p)
			end)
			if ok then
				closed = closed + 1
			end
		end
	end
	pcall(function()
		keep_pane:activate()
	end)
	return closed
end

---Every saved tab, in order, flattened across saved windows.
local function flatten_tabs(state)
	local out = {}
	for _, win_state in ipairs(state.windows) do
		for _, tab_state in ipairs(win_state.tabs) do
			out[#out + 1] = tab_state
		end
	end
	return out
end

---Rebuild into the tab the command was invoked from. The first saved tab takes
---over that tab; any further saved tabs are appended to the same window.
local function restore_into_current_tab(state, opts)
	local root_pane = opts.pane
	if not root_pane then
		return false, "target='current_tab' needs opts.pane"
	end
	local tab = root_pane:tab()
	if not tab then
		return false, "could not resolve the current tab"
	end
	local mux_win = opts.mux_window or (tab:window())

	local saved_tabs = flatten_tabs(state)
	if #saved_tabs == 0 then
		return false, "state has no tabs"
	end

	local acc = { n = 0 }
	local closed = 0
	if opts.close_other_panes then
		closed = close_other_panes(opts.gui_window, tab, root_pane)
	end

	-- Guard the reused pane against having a command typed into a running app.
	if not capture.is_at_shell(root_pane) then
		opts._busy_root_id = root_pane:pane_id()
	end

	local active_tab
	for i, tab_state in ipairs(saved_tabs) do
		local this_tab, this_pane
		if i == 1 then
			this_tab, this_pane = tab, root_pane
		elseif mux_win then
			local seed = first_leaf_of(tab_state.layout)
			local targs = {}
			if seed and seed.cwd then
				targs.cwd = seed.cwd
			end
			if seed and seed.domain and seed.domain ~= "local" then
				targs.domain = { DomainName = seed.domain }
			end
			this_tab, this_pane = mux_win:spawn_tab(targs)
		end

		if this_tab and this_pane then
			restore_tab(this_tab, this_pane, tab_state, opts, acc)
			if tab_state.is_active then
				active_tab = this_tab
			end
		end
	end

	if acc.active_pane then
		pcall(function()
			acc.active_pane:activate()
		end)
	end
	if active_tab then
		pcall(function()
			active_tab:activate()
		end)
	end

	return true,
		string.format(
			"%d tab(s), %d pane(s)%s",
			#saved_tabs,
			acc.n,
			closed > 0 and string.format(", %d pane(s) closed", closed) or ""
		),
		tab
end

---Rebuild as new tabs appended to the current window.
local function restore_into_new_tabs(state, opts)
	local mux_win = opts.mux_window
	if not mux_win then
		return false, "target='tab' needs opts.mux_window"
	end

	local saved_tabs = flatten_tabs(state)
	if #saved_tabs == 0 then
		return false, "state has no tabs"
	end

	local acc = { n = 0 }
	local active_tab, first_tab
	for _, tab_state in ipairs(saved_tabs) do
		local seed = first_leaf_of(tab_state.layout)
		local targs = {}
		if seed and seed.cwd then
			targs.cwd = seed.cwd
		end
		if seed and seed.domain and seed.domain ~= "local" then
			targs.domain = { DomainName = seed.domain }
		end
		local this_tab, this_pane = mux_win:spawn_tab(targs)
		if this_tab and this_pane then
			first_tab = first_tab or this_tab
			restore_tab(this_tab, this_pane, tab_state, opts, acc)
			if tab_state.is_active then
				active_tab = this_tab
			end
		end
	end

	if acc.active_pane then
		pcall(function()
			acc.active_pane:activate()
		end)
	end
	if active_tab then
		pcall(function()
			active_tab:activate()
		end)
	end

	return true, string.format("%d tab(s), %d pane(s)", #saved_tabs, acc.n), first_tab
end

---Rebuild a saved session into its own workspace.
---@param state table decoded state file
---@param user_opts table|nil
---@return boolean ok
---@return string|nil err
function M.restore(state, user_opts)
	if type(state) ~= "table" or not state.windows then
		return false, "state has no windows"
	end
	if state.schema and state.schema ~= 1 then
		return false, "unsupported schema version: " .. tostring(state.schema)
	end

	local opts = util.merge(M.defaults, user_opts)

	if opts.target == "current_tab" then
		return restore_into_current_tab(state, opts)
	elseif opts.target == "tab" then
		return restore_into_new_tabs(state, opts)
	end

	local workspace = opts.workspace or state.name or state.workspace or "restored"

	local acc = { n = 0 }
	local target_window, first_tab
	local tab_count = 0

	for _, win_state in ipairs(state.windows) do
		tab_count = tab_count + #win_state.tabs
		local seed = first_leaf_of((win_state.tabs[1] or {}).layout)

		local spawn = { workspace = workspace }
		if seed and seed.cwd then
			spawn.cwd = seed.cwd
		end
		if opts.resize_window and win_state.size then
			spawn.width = win_state.size.cols
			spawn.height = win_state.size.rows
		end

		local tab, pane, window = wezterm.mux.spawn_window(spawn)
		if not window then
			return false, "spawn_window returned no window"
		end

		if win_state.title and win_state.title ~= "" then
			pcall(function()
				window:set_title(win_state.title)
			end)
		end

		local active_tab
		for ti, tab_state in ipairs(win_state.tabs) do
			local this_tab, this_pane = tab, pane
			if ti > 1 then
				local seed2 = first_leaf_of(tab_state.layout)
				local targs = {}
				if seed2 and seed2.cwd then
					targs.cwd = seed2.cwd
				end
				if seed2 and seed2.domain and seed2.domain ~= "local" then
					targs.domain = { DomainName = seed2.domain }
				end
				this_tab, this_pane = window:spawn_tab(targs)
			end

			first_tab = first_tab or this_tab
			restore_tab(this_tab, this_pane, tab_state, opts, acc)

			if tab_state.is_active then
				active_tab = this_tab
			end
		end

		if active_tab then
			pcall(function()
				active_tab:activate()
			end)
		end

		target_window = target_window or window
	end

	pcall(function()
		wezterm.mux.set_active_workspace(workspace)
	end)

	if acc.active_pane then
		pcall(function()
			acc.active_pane:activate()
		end)
	end

	if opts.maximize and target_window then
		-- The GUI window is not attached the instant the mux window appears.
		wezterm.time.call_after(0.3, function()
			pcall(function()
				local gui = target_window:gui_window()
				if gui then
					gui:maximize()
				end
			end)
		end)
	end

	return true,
		string.format("%d window(s), %d tab(s), %d pane(s)", #state.windows, tab_count, acc.n),
		first_tab
end

return M
