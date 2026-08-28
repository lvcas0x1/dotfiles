vim.pack.add({
	-- catppuccin
	{
		src = "https://github.com/catppuccin/nvim",
		name = "catppuccin",
	},
	-- neo-tree
	{
		src = "https://github.com/nvim-lua/plenary.nvim",
	},
	{
		src = "https://github.com/MunifTanjim/nui.nvim",
	},
	{
		src = "https://github.com/nvim-tree/nvim-web-devicons",
	},
	{
		src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
	},
	-- window-picker required by neo-tree
	{
		src = "https://github.com/s1n7ax/nvim-window-picker",
	},
	-- gitsigns
	{
		src = "https://github.com/lewis6991/gitsigns.nvim",
	},
	-- telescope
	{
		src = "https://github.com/nvim-telescope/telescope.nvim",
	},
	{
		src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
	},
	-- treesitter
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		version = "main",
	},
	-- mason
	{
		src = "https://github.com/mason-org/mason.nvim",
	},
	-- lsp
	{
		src = "https://github.com/mason-org/mason-lspconfig.nvim",
	},
	{
		src = "https://github.com/neovim/nvim-lspconfig",
	},
	-- dap
	{
		src = "https://github.com/mfussenegger/nvim-dap",
	},
	{
		src = "https://github.com/igorlfs/nvim-dap-view",
	},
	{
		src = "https://github.com/mfussenegger/nvim-dap-python",
	},
	-- java
	{
		src = "https://github.com/JavaHello/spring-boot.nvim",
		version = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0",
	},
	{
		src = "https://github.com/nvim-java/nvim-java",
	},
	-- conform
	{
		src = "https://github.com/stevearc/conform.nvim",
	},
	-- lualine
	{
		src = "https://github.com/nvim-lualine/lualine.nvim",
	},
	-- toggleterm
	{
		src = "https://github.com/akinsho/toggleterm.nvim",
	},
	-- trouble
	{
		src = "https://github.com/folke/trouble.nvim",
	},
	-- im-select
	{
		src = "https://github.com/keaising/im-select.nvim",
	},
	-- ts-autotag
	{
		src = "https://github.com/windwp/nvim-ts-autotag",
	},
	-- autopairs
	{
		src = "https://github.com/windwp/nvim-autopairs",
	},
	-- luasnip / friendly-snippets
	{
		src = "https://github.com/L3MON4D3/LuaSnip",
	},
	{
		src = "https://github.com/rafamadriz/friendly-snippets",
	},
	-- ts-comments
	{
		src = "https://github.com/folke/ts-comments.nvim",
	},
	-- render-markdown
	{
		src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
	},
	-- todo-comments
	{
		src = "https://github.com/folke/todo-comments.nvim",
	},
	-- neogen
	{
		src = "https://github.com/danymat/neogen",
	},
	-- which-key
	{
		src = "https://github.com/folke/which-key.nvim",
	},
	-- diffview
	{
    src = "https://github.com/sindrets/diffview.nvim",
	},
})

require("plugins.catppuccin")
require("plugins.neo-tree")
require("plugins.window-picker")
require("plugins.gitsigns")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.mason")
require("plugins.lsp")
require("plugins.dap")
require("plugins.java")
require("plugins.conform")
require("plugins.lualine")
require("plugins.toggleterm")
require("plugins.trouble")
require("plugins.im-select")
require("plugins.ts-autotag")
require("plugins.autopairs")
require("plugins.luasnip")
require("plugins.ts-comments")
require("plugins.render-markdown")
require("plugins.todo-comments")
require("plugins.neogen")
require("plugins.which-key")
require("plugins.diffview")

-- self made plugins
-- for update packages installed by vim.pack (neovim 0.12+)
require("plugins.vimpack")
require("plugins.pdf")
