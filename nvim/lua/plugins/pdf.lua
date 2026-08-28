local config = {
	command = "tdf",
	wezterm = "/Applications/WezTerm.app/Contents/MacOS/wezterm",

	split = {
		direction = "vertical",
		position = "right",
		percent = 50,
	},
}

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "PDF" })
end

local function is_pdf(path)
	return path ~= nil and path:lower():match("%.pdf$") ~= nil
end

local function normalize_path(path)
	if path == nil or path == "" then
		return nil
	end

	return vim.fn.fnamemodify(path, ":p")
end

local function executable(path)
	return vim.fn.executable(path) == 1
end

local function open_pdf_in_wezterm(path)
	path = normalize_path(path)

	if not is_pdf(path) then
		return false
	end

	if not executable(config.command) then
		notify(config.command .. " command was not found.", vim.log.levels.ERROR)
		return false
	end

	if not executable(config.wezterm) then
		notify("wezterm command was not found: " .. config.wezterm, vim.log.levels.ERROR)
		return false
	end

	if vim.env.WEZTERM_PANE == nil then
		notify("WEZTERM_PANE was not found. Start Neovim inside WezTerm.", vim.log.levels.ERROR)
		return false
	end

	local args = {
		config.wezterm,
		"cli",
		"split-pane",
		"--right",
		"--percent",
		tostring(config.split.percent),
		"--",
		config.command,
		path,
	}

	-- Open the PDF in a new WezTerm pane.
	vim.system(args)

	return true
end

local function open_current_pdf()
	local path = normalize_path(vim.fn.expand("<afile>"))

	if not open_pdf_in_wezterm(path) then
		return
	end

	-- Use a small placeholder buffer instead of trying to render PDF in Neovim terminal.
	local bufnr = vim.api.nvim_get_current_buf()

	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].filetype = "pdf"

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
		"PDF opened in WezTerm pane:",
		path,
	})

	vim.bo[bufnr].modifiable = false
end

local function patch_neo_tree()
	local ok, commands = pcall(require, "neo-tree.sources.filesystem.commands")
	if not ok then
		return
	end

	if commands._pdf_patched then
		return
	end

	local original_open = commands.open

	commands.open = function(state, ...)
		local node = state.tree:get_node()
		local path = node and node:get_id()

		-- Open PDF files from neo-tree in a WezTerm pane.
		if node and node.type == "file" and open_pdf_in_wezterm(path) then
			return
		end

		return original_open(state, ...)
	end

	commands._pdf_patched = true
end

local group = vim.api.nvim_create_augroup("Pdf", { clear = true })

-- Handle direct opening, such as: nvim file.pdf
vim.api.nvim_create_autocmd("BufReadCmd", {
	group = group,
	pattern = "*.pdf",
	callback = open_current_pdf,
})

-- Patch neo-tree after plugin setup has finished.
vim.schedule(patch_neo_tree)
