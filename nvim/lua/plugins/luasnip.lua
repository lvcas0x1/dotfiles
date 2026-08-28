local luasnip = require("luasnip")

luasnip.setup({
	history = true,
	updateevents = "TextChanged,TextChangedI",
	delete_check_events = "TextChanged",
})

require("luasnip.loaders.from_vscode").lazy_load()
