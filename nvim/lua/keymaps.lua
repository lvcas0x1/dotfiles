-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Neovim / Tab
map("n", "<M-n>", "<Cmd>tabnew<CR>", { desc = "New Tab" })
map("n", "<M-w>", "<Cmd>tabclose<CR>", { desc = "Close Tab" })
map("n", "<M-Left>", "<Cmd>tabprevious<CR>", { desc = "Previous Tab" })
map("n", "<M-Right>", "<Cmd>tabnext<CR>", { desc = "Next Tab" })

-- Neovim / Window
map("n", "<M-,>", "<C-w>W", { desc = "Prev Window" })
map("n", "<M-.>", "<C-w>w", { desc = "Next Window" })

map("n", "<M-->", "<Cmd>new<CR>", { desc = "Horizontal Split Pane" })
map("n", "<M-=>", "<Cmd>vnew<CR>", { desc = "Vertical Split Pane" })
map("n", "<M-q>", "<Cmd>close<CR>", { desc = "Close Pane" })

map("n", "<M-S-Up>", "<Cmd>resize +1<CR>", { silent = true, desc = "Window: Grow Height" })
map("n", "<M-S-Down>", "<Cmd>resize -1<CR>", { silent = true, desc = "Window: Shrink Height" })
map("n", "<M-S-Left>", "<Cmd>vertical resize +1<CR>", { silent = true, desc = "Window: Grow Width" })
map("n", "<M-S-Right>", "<Cmd>vertical resize -1<CR>", { silent = true, desc = "Window: Shrink Width" })

-- Neo-tree
map("n", "<leader>e", "<Cmd>Neotree toggle left<CR>", { desc = "Toggle Neo-tree" })

-- Telescope
local ok_telescope, builtin = pcall(require, "telescope.builtin")
if ok_telescope then
	map("n", "<leader>ff", builtin.find_files, { desc = "Telescope Find Files" })
	map("n", "<leader>fg", builtin.live_grep, { desc = "Telescope Live Grep" })
	map("n", "<leader>fb", builtin.buffers, { desc = "Telescope Buffers" })
	map("n", "<leader>fh", builtin.help_tags, { desc = "Telescope Help Tags" })
end

-- Completion
map("i", "<Tab>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-n>"
	end
	return "<Tab>"
end, { expr = true, silent = true, desc = "Completion Next" })

map("i", "<S-Tab>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-p>"
	end
	return "<C-d>"
end, { expr = true, silent = true, desc = "Completion Previous / Deindent" })

map("i", "<CR>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-y>"
	end
	return "<CR>"
end, { expr = true, silent = true, desc = "Completion Confirm" })

map("i", "<C-Space>", "<C-x><C-o>", { silent = true, desc = "LSP Completion" })

-- DAP
map("n", "<F5>", function()
	require("dap").continue()
end, { desc = "DAP Continue" })

map("n", "<F10>", function()
	require("dap").step_over()
end, { desc = "DAP Step Over" })

map("n", "<F11>", function()
	require("dap").step_into()
end, { desc = "DAP Step Into" })

map("n", "<F12>", function()
	require("dap").step_out()
end, { desc = "DAP Step Out" })

map("n", "<leader>db", function()
	require("dap").toggle_breakpoint()
end, { desc = "DAP Toggle Breakpoint" })

map("n", "<leader>dB", function()
	require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "DAP Conditional Breakpoint" })

map("n", "<leader>dr", function()
	require("dap").repl.open()
end, { desc = "DAP Open REPL" })

map("n", "<leader>dl", function()
	require("dap").run_last()
end, { desc = "DAP Run Last" })

map("n", "<leader>dt", function()
	require("dap").terminate()
end, { desc = "DAP Terminate" })

-- DAP View
map("n", "<leader>dv", function()
	require("dap-view").toggle()
end, { desc = "DAP View Toggle" })

-- ToggleTerm
map("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "Terminal Normal Mode" })

map("n", "<M-`>", "<Cmd>ToggleTerm 1 direction=float<CR>", { desc = "Terminal Float #1" })
map("n", "<M-\\>", "<Cmd>ToggleTerm 2 direction=vertical<CR>", { desc = "Terminal Vertical #2" })
map("n", "<M-;>", "<Cmd>ToggleTerm 3 direction=horizontal<CR>", { desc = "Terminal Horizontal #3" })
map("n", "<M-'>", "<Cmd>ToggleTerm 4 direction=horizontal<CR>", { desc = "Terminal Horizontal #4" })

-- Trouble
map("n", "<leader>td", "<Cmd>Trouble diagnostics toggle<CR>", { desc = "Trouble Diagnostics" })
map("n", "<leader>tD", "<Cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Trouble Buffer Diagnostics" })
map("n", "<leader>tl", "<Cmd>Trouble lsp toggle focus=false win.position=right<CR>", { desc = "Trouble LSP" })
map("n", "<leader>tL", "<Cmd>Trouble loclist toggle<CR>", { desc = "Trouble Location List" })
map("n", "<leader>ts", "<Cmd>Trouble symbols toggle focus=false<CR>", { desc = "Trouble Symbols" })
map("n", "<leader>tq", "<Cmd>Trouble qflist toggle<CR>", { desc = "Trouble Quickfix" })

-- LuaSnip
local ok_luasnip, luasnip = pcall(require, "luasnip")
if ok_luasnip then
	map("i", "<M-/>", function()
		if luasnip.expandable() then
			luasnip.expand()
		end
	end, { silent = true, desc = "LuaSnip Expand" })
end

-- Render Markdown
map("n", "<leader>mt", "<Cmd>RenderMarkdown toggle<CR>", { desc = "Render Markdown Toggle" })
map("n", "<leader>mn", "<Cmd>RenderMarkdown buf_toggle<CR>", { desc = "Render Markdown Buffer Toggle" })
map("n", "<leader>mc", "<Cmd>RenderMarkdown config<CR>", { desc = "Render Markdown Config" })

-- Todo Comments
map("n", "]t", function()
	require("todo-comments").jump_next()
end, { desc = "Next Todo Comment" })

map("n", "[t", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous Todo Comment" })

map("n", "<leader>tt", "<Cmd>Trouble todo toggle<CR>", { desc = "Todo Trouble" })
map("n", "<leader>tT", "<Cmd>TodoTelescope<CR>", { desc = "Todo Telescope" })

-- Neogen
map("n", "<leader>nf", function()
	require("neogen").generate()
end, { desc = "Neogen Function Doc" })

map("n", "<leader>nc", function()
	require("neogen").generate({ type = "class" })
end, { desc = "Neogen Class Doc" })

map("n", "<leader>nt", function()
	require("neogen").generate({ type = "type" })
end, { desc = "Neogen Type Doc" })

map("n", "<leader>nF", function()
	require("neogen").generate({ type = "file" })
end, { desc = "Neogen File Doc" })

-- Vimpack
map("n", "<leader>uv", "<Cmd>PackManager<CR>", { desc = "Vim Pack Manager" })
map("n", "<leader>um", "<Cmd>Mason<CR>", { desc = "Mason" })
map("n", "<leader>uh", "<Cmd>checkhealth<CR>", { desc = "CheckHealth" })

-- Diffview
vim.keymap.set("n", "<leader>vo", "<cmd>DiffviewOpen<CR>", {
	desc = "Diffview Open",
})
vim.keymap.set("n", "<leader>vc", "<cmd>DiffviewClose<CR>", {
	desc = "Diffview Close",
})
vim.keymap.set("n", "<leader>vh", "<cmd>DiffviewFileHistory %<CR>", {
	desc = "Diffview File History",
})
