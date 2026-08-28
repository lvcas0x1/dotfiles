local M = {}

local state = {
	buf = nil,
	win = nil,
	items = {},
	loading = false,
	message = "Press r to refresh.",
}

local ns = vim.api.nvim_create_namespace("pack-manager")

local function plugin_name(item)
	if item.spec and item.spec.name then
		return item.spec.name
	end

	if item.spec and item.spec.src then
		return vim.fn.fnamemodify(item.spec.src, ":t"):gsub("%.git$", "")
	end

	return "unknown"
end

local function plugin_src(item)
	if item.spec and item.spec.src then
		return item.spec.src
	end

	return ""
end

local function short_rev(rev)
	if not rev or rev == "" then
		return "latest"
	end

	return rev:sub(1, 8)
end

local function has_update(item)
	return item.rev and item.rev_to and item.rev ~= item.rev_to
end

local function close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end

	state.win = nil
	state.buf = nil
end

local function float_size()
	local columns = vim.o.columns
	local lines = vim.o.lines

	local width = math.floor(columns * 0.8)
	local height = math.floor(lines * 0.75)

	width = math.min(width, 120)
	height = math.min(height, 35)

	width = math.max(width, 70)
	height = math.max(height, 18)

	width = math.min(width, columns - 4)
	height = math.min(height, lines - 4)

	return width, height
end

local function float_config()
	local width, height = float_size()

	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " pack.nvim ",
		title_pos = "center",
	}
end

local function status_counts()
	local updates = 0

	for _, item in ipairs(state.items) do
		if has_update(item) then
			updates = updates + 1
		end
	end

	return updates
end

local function render()
	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end

	local updates = status_counts()

	local lines = {
		"                pack.nvim",
		"",
		" (o) Open Source    (r) Refresh    (u) Update selected    (U) Update all    (q) Quit",
		"",
		"  Installed (" .. tostring(#state.items) .. ")",
		"",
	}

	for _, item in ipairs(state.items) do
		local mark = has_update(item) and "↑" or "✓"
		local status = has_update(item) and "update" or "ok"

		local line = string.format(
			"  %s %-32s %-8s  %s -> %s",
			mark,
			plugin_name(item),
			status,
			short_rev(item.rev),
			short_rev(item.rev_to)
		)

		table.insert(lines, line)
	end

	if #state.items == 0 then
		table.insert(lines, "  No plugins loaded.")
	end

	table.insert(lines, "")
	table.insert(lines, "  " .. state.message)
	table.insert(lines, "")
	table.insert(lines, "  Installed: " .. tostring(#state.items) .. "  Updates: " .. tostring(updates))

	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false

	vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)

	for i, line in ipairs(lines) do
		if line:find("update", 1, true) then
			vim.api.nvim_buf_add_highlight(state.buf, ns, "DiagnosticWarn", i - 1, 0, -1)
		elseif line:match("^  ✓") then
			vim.api.nvim_buf_add_highlight(state.buf, ns, "DiagnosticOk", i - 1, 0, 5)
		elseif line:match("^  ↑") then
			vim.api.nvim_buf_add_highlight(state.buf, ns, "DiagnosticWarn", i - 1, 0, 5)
		end
	end
end

local function refresh()
	if state.loading then
		return
	end

	state.loading = true
	state.message = "Checking updates..."
	render()

	vim.schedule(function()
		local ok, items = pcall(vim.pack.get, nil, {
			offline = false,
		})

		state.loading = false

		if not ok then
			state.items = {}
			state.message = "Refresh failed."
			render()
			return
		end

		table.sort(items, function(a, b)
			return plugin_name(a) < plugin_name(b)
		end)

		state.items = items

		local updates = status_counts()

		if updates == 0 then
			state.message = "All packages are up to date."
		else
			state.message = tostring(updates) .. " package(s) can be updated."
		end

		render()
	end)
end

local function selected_item()
	if not state.win or not vim.api.nvim_win_is_valid(state.win) then
		return nil
	end

	local row = vim.api.nvim_win_get_cursor(state.win)[1]
	local index = row - 6

	if index < 1 or index > #state.items then
		return nil
	end

	return state.items[index]
end

local function update_selected()
	local item = selected_item()

	if not item then
		state.message = "Select a package first."
		render()
		return
	end

	state.message = "Updating " .. plugin_name(item) .. "..."
	render()

	vim.schedule(function()
		local ok, err = pcall(vim.pack.update, {
			plugin_name(item),
		})

		if not ok then
			state.message = "Update failed: " .. tostring(err)
			render()
			return
		end

		state.message = "Update finished. Refreshing..."
		render()
		refresh()
	end)
end

local function update_all()
	local names = {}

	for _, item in ipairs(state.items) do
		if has_update(item) then
			table.insert(names, plugin_name(item))
		end
	end

	if #names == 0 then
		state.message = "No updates available."
		render()
		return
	end

	state.message = "Updating all packages..."
	render()

	vim.schedule(function()
		local ok, err = pcall(vim.pack.update, names)

		if not ok then
			state.message = "Update failed: " .. tostring(err)
			render()
			return
		end

		state.message = "Update finished. Refreshing..."
		render()
		refresh()
	end)
end

local function open_source()
	local item = selected_item()

	if not item then
		state.message = "Select a package first."
		render()
		return
	end

	local src = plugin_src(item)

	if src == "" then
		state.message = "No source URL."
		render()
		return
	end

	vim.ui.open(src)
end

local function resize()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_set_config(state.win, float_config())
	end
end

function M.open()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_set_current_win(state.win)
		return
	end

	state.buf = vim.api.nvim_create_buf(false, true)

	vim.bo[state.buf].buftype = "nofile"
	vim.bo[state.buf].bufhidden = "wipe"
	vim.bo[state.buf].swapfile = false
	vim.bo[state.buf].filetype = "pack-manager"
	vim.bo[state.buf].modifiable = false

	state.win = vim.api.nvim_open_win(state.buf, true, float_config())

	vim.wo[state.win].number = false
	vim.wo[state.win].relativenumber = false
	vim.wo[state.win].cursorline = true
	vim.wo[state.win].signcolumn = "no"
	vim.wo[state.win].wrap = false

	vim.keymap.set("n", "q", close, { buffer = state.buf, silent = true, desc = "Close" })
	vim.keymap.set("n", "r", refresh, { buffer = state.buf, silent = true, desc = "Refresh" })
	vim.keymap.set("n", "u", update_selected, { buffer = state.buf, silent = true, desc = "Update Selected" })
	vim.keymap.set("n", "U", update_all, { buffer = state.buf, silent = true, desc = "Update All" })
	vim.keymap.set("n", "o", open_source, { buffer = state.buf, silent = true, desc = "Open Source" })

	vim.api.nvim_create_autocmd("VimResized", {
		buffer = state.buf,
		callback = resize,
	})

	render()
	refresh()
end

vim.api.nvim_create_user_command("PackManager", function()
	M.open()
end, {
	desc = "Open vim.pack manager",
})

return M
