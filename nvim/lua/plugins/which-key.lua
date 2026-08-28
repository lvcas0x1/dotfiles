local wk = require("which-key")

wk.setup({
	preset = "modern",
	delay = 100,

	icons = {
		mappings = false,
		keys = {},
	},

	win = {
		border = "rounded",
	},

	layout = {
		width = { min = 30 },
		spacing = 3,
	},

	sort = {
		"order",
		"group",
		"alphanum",
	},

	replace = {
		key = {
			{ "<leader>", "SPC" },
		},
	},
})

vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
vim.api.nvim_set_hl(0, "FloatTitle", { bg = "NONE" })

wk.add({
	{ "<leader>d", group = "Debug / DAP" },
	{ "<leader>f", group = "Find / Telescope" },
	{ "<leader>m", group = "Markdown" },
	{ "<leader>n", group = "Neogen" },
	{ "<leader>t", group = "Trouble / Todo" },
	{ "<leader>u", group = "Update" },
	{ "<leader>v", group = "DiffView" },
})
