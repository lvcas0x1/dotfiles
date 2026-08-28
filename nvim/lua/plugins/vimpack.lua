local M = {}

local state = {
	buf = nil,
	win = nil,
	items = {},
	loading = false,
	message = "Loading...",
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
		return "unknown"
	end

	return rev:sub(1, 8)
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
	local updates, unchecked, errors = 0, 0, 0

	for _, item in ipairs(state.items) do
		if item.check_error then
			errors = errors + 1
		elseif not item.checked then
			unchecked = unchecked + 1
		elseif item.has_update then
			updates = updates + 1
		end
	end

	return updates, unchecked, errors
end

local function render()
	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end

	local updates, unchecked, errors = status_counts()

	local lines = {
		"                pack.nvim",
		"",
		" (o) Open Source    (r) Refresh & check    (u) Apply selected    (U) Apply All",
		"",
		"  Installed (" .. tostring(#state.items) .. ")   Updates: " .. tostring(updates) .. "   Unchecked: " .. tostring(unchecked),
		"",
	}

	local mark_hls = {}

	for _, item in ipairs(state.items) do
		local mark, mark_hl
		if item.check_error then
			mark, mark_hl = "!", "DiagnosticError"
		elseif not item.checked then
			mark, mark_hl = "?", "Comment"
		elseif item.has_update then
			mark, mark_hl = "↑", "DiagnosticWarn"
		else
			mark, mark_hl = "✓", "DiagnosticOk"
		end

		local rev_part = short_rev(item.rev)
		if item.checked and item.has_update then
			rev_part = short_rev(item.rev) .. " -> " .. short_rev(item.rev_to)
		end

		local line = string.format(
			"  %s %-32s %-10s %s",
			mark,
			plugin_name(item),
			item.active and "active" or "inactive",
			rev_part
		)

		table.insert(lines, line)
		mark_hls[#lines] = mark_hl
	end

	if #state.items == 0 then
		table.insert(lines, "  No plugins loaded.")
	end

	table.insert(lines, "")
	table.insert(lines, "  " .. state.message)
	table.insert(lines, "")
	if errors > 0 then
		table.insert(lines, "  " .. tostring(errors) .. " package(s) failed to check.")
	end

	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = false

	vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)

	for line_no, hl in pairs(mark_hls) do
		vim.api.nvim_buf_add_highlight(state.buf, ns, hl, line_no - 1, 2, 5)
	end
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

-- vim.pack.get() never fetches from remote and has no field for a "target"
-- revision, so on its own it cannot tell whether an update is available.
-- The only API that actually computes that is vim.pack.update(), which
-- (with force = false) fetches and opens Neovim's own confirmation buffer
-- containing the real diff. We drive that call, read the diff out of the
-- buffer it produces, then cancel it (close the window, same as :quit)
-- so nothing is applied yet -- this is purely a status check.
local function parse_confirm_lines(lines)
	local by_name = {}
	local section = nil
	local current = nil

	local function push()
		if current then
			by_name[current.name] = current
		end
		current = nil
	end

	for _, line in ipairs(lines) do
		local name = line:match("^## (.+)$")
		local section_word = (not name) and line:match("^# (%a+)")

		if name then
			push()
			name = name:gsub("%s+%(not active%)$", "")
			current = { name = name, section = section and section:lower(), count = 0 }
		elseif section_word then
			push()
			section = section_word
		elseif current then
			local before = line:match("^Revision before:%s+(%S+)")
			local after = line:match("^Revision after:%s+(%S+)")
			local same_rev = line:match("^Revision:%s+(%S+)")

			if before then
				current.rev_before = before
			elseif after then
				current.rev_after = after
			elseif same_rev then
				current.rev = same_rev
			elseif line:match("^> ") then
				current.count = current.count + 1
			end
		end
	end
	push()

	return by_name
end

local function check_updates(names, label)
	state.message = "Fetching " .. label .. "... this can take a while."
	render()

	vim.schedule(function()
		local ok, err = pcall(vim.pack.update, names, { offline = false, force = false })

		if not ok then
			state.message = "Check failed: " .. tostring(err)
			render()
			return
		end

		local buf = vim.api.nvim_get_current_buf()
		local bufname = vim.api.nvim_buf_get_name(buf)

		if not bufname:match("^nvim%-pack://confirm") then
			state.message = "Nothing to check."
			render()
			return
		end

		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local by_name = parse_confirm_lines(lines)

		-- Cancel the confirmation buffer (equivalent to :quit): nothing gets
		-- applied, we only wanted the diff it computed.
		pcall(vim.api.nvim_win_close, vim.api.nvim_get_current_win(), true)

		-- Only mark the plugins we actually asked about as checked. `names`
		-- is nil when checking everything; otherwise it's the exact subset
		-- that was fetched, and every other item's status must stay as-is.
		local target = nil
		if names then
			target = {}
			for _, n in ipairs(names) do
				target[n] = true
			end
		end

		for _, item in ipairs(state.items) do
			local pname = plugin_name(item)
			if target == nil or target[pname] then
				local info = by_name[pname]
				item.checked = true
				item.has_update = info ~= nil and info.section == "update"
				item.check_error = info == nil or info.section == "error"
				item.rev_to = info and info.rev_after or nil
			end
		end

		local updates, _, errors = status_counts()

		if errors > 0 then
			state.message = errors .. " package(s) failed to check, " .. updates .. " have updates."
		elseif updates == 0 then
			state.message = "All checked packages are up to date."
		else
			state.message = updates .. " package(s) have updates available. Press u/U to apply."
		end

		render()
	end)
end

local function refresh()
	if state.loading then
		return
	end

	local ok, items = pcall(vim.pack.get, nil, { info = false })

	if not ok then
		state.items = {}
		state.message = "Failed to list plugins: " .. tostring(items)
		render()
		return
	end

	table.sort(items, function(a, b)
		return plugin_name(a) < plugin_name(b)
	end)

	state.items = items
	render()

	check_updates(nil, "all packages")
end

local function check_selected()
	local item = selected_item()

	if not item then
		state.message = "Select a package first."
		render()
		return
	end

	check_updates({ plugin_name(item) }, plugin_name(item))
end

local function apply_update(names, label)
	state.message = "Applying update for " .. label .. "..."
	render()

	vim.schedule(function()
		local ok, err = pcall(vim.pack.update, names, { offline = false, force = true })

		if not ok then
			state.message = "Update failed: " .. tostring(err)
			render()
			return
		end

		state.message = "Update applied. Re-checking..."
		render()
		check_updates(names, label)
	end)
end

local function update_selected()
	local item = selected_item()

	if not item then
		state.message = "Select a package first."
		render()
		return
	end

	apply_update({ plugin_name(item) }, plugin_name(item))
end

local function update_all()
	local pending = {}

	for _, item in ipairs(state.items) do
		if item.has_update then
			table.insert(pending, plugin_name(item))
		end
	end

	if #pending == 0 then
		state.message = "No pending updates. Press (r) to refresh & check again."
		render()
		return
	end

	apply_update(pending, tostring(#pending) .. " package(s)")
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
	vim.wo[state.win].wrap = true
	vim.wo[state.win].linebreak = true

	vim.keymap.set("n", "q", close, { buffer = state.buf, silent = true, desc = "Close" })
	vim.keymap.set("n", "<Esc>", close, { buffer = state.buf, silent = true, desc = "Close" })
	vim.keymap.set("n", "r", refresh, { buffer = state.buf, silent = true, desc = "Refresh & Check" })
	vim.keymap.set("n", "gc", check_selected, { buffer = state.buf, silent = true, desc = "Check Updates (Selected)" })
	vim.keymap.set("n", "u", update_selected, { buffer = state.buf, silent = true, desc = "Apply Selected" })
	vim.keymap.set("n", "U", update_all, { buffer = state.buf, silent = true, desc = "Apply All" })
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
