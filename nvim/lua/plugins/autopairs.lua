local npairs = require("nvim-autopairs")

npairs.setup({
	-- disable in special buffers
	disable_filetype = {
		"TelescopePrompt",
		"neo-tree",
		"neo-tree-popup",
		"trouble",
		"toggleterm",
	},

	-- use treesitter
	check_ts = true,

	ts_config = {
		lua = { "string" },
		javascript = { "template_string" },
		typescript = { "template_string" },
		tsx = { "template_string" },
	},

	-- if next character is a close pair and it doesn't have an open pair in same line, then disable
	enable_check_bracket_line = false,

	-- move the cursor to the right when the next character is a closing pair
	enable_moveright = true,
})
