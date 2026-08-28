require("window-picker").setup({
	hint = "statusline-winbar",
	selection_chars = "123456789",

	picker_config = {
		handle_mouse_click = true,
	},

	show_prompt = false,

	filter_rules = {
		autoselect_one = true,
		include_current_win = false,

		bo = {
			filetype = {
				"neo-tree",
				"neo-tree-popup",
				"notify",
				"snacks_notif",
				"trouble",
			},

			buftype = {
				"terminal",
				"quickfix",
			},
		},
	},

	highlights = {
		enabled = true,

		statusline = {
			focused = {
				fg = "#ededed",
				bg = "#acb0be",
				bold = true,
			},

			unfocused = {
				fg = "#ededed",
				bg = "#acb0be",
				bold = true,
			},
		},
	},
})
