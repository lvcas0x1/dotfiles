local telescope = require("telescope")

telescope.setup({
	defaults = {
		mappings = {
			i = {
				["<C-h>"] = "which_key",
			},
		},
	},
})

telescope.load_extension("fzf")

local function set_telescope_highlights()
	vim.api.nvim_set_hl(0, "TelescopeNormal", {
		bg = "NONE",
	})

	vim.api.nvim_set_hl(0, "TelescopeBorder", {
		fg = "#bcc0cc",
		bg = "NONE",
	})

	vim.api.nvim_set_hl(0, "TelescopePromptNormal", {
		bg = "NONE",
	})

	vim.api.nvim_set_hl(0, "TelescopePromptBorder", {
		fg = "#bcc0cc",
		bg = "NONE",
	})

	vim.api.nvim_set_hl(0, "TelescopePromptTitle", {
		fg = "#bcc0cc",
		bg = "NONE",
	})

	vim.api.nvim_set_hl(0, "TelescopeResultsTitle", {
		fg = "#acb0be",
		bg = "NONE",
	})

	vim.api.nvim_set_hl(0, "TelescopePreviewTitle", {
		fg = "#acb0be",
		bg = "NONE",
	})

	vim.api.nvim_set_hl(0, "TelescopeSelection", {
		bg = "#acb0be",
		bold = true,
	})
end

set_telescope_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = set_telescope_highlights,
})
