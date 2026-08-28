require("trouble").setup({
	win = {
		type = "split",
		position = "bottom",
		size = math.floor(vim.o.lines * 0.3),
	},

	preview = {
		type = "main",
		scratch = true,
	},
})
