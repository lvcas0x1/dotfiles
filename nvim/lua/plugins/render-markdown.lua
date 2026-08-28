local render_markdown = require("render-markdown")

render_markdown.setup({
	file_types = {
		"markdown",
		"markdown.mdx",
	},

	latex = {
		enabled = false,
	},

	render_modes = {
		"n",
		"c",
		"t",
	},

	completions = {
		lsp = {
			enabled = true,
		},
	},
})
