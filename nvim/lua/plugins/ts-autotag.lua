local autotag = require("nvim-ts-autotag")

autotag.setup({
	opts = {
		-- Auto close tags: <div> -> <div></div>
		enable_close = true,

		-- Auto rename paired tags: <div></div> -> <section></section>
		enable_rename = true,

		-- Auto close when typing trailing </
		enable_close_on_slash = false,
	},

	per_filetype = {
		-- html = {
		-- 	enable_close = true,
		-- },
	},
})
