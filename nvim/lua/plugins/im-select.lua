local im_select = require("im_select")

im_select.setup({
	-- macOS built-in US / ABC input source
	default_im_select = "com.apple.keylayout.US",

	-- macOS latest official recommended CLI
	default_command = "macism",

	-- Always return to US when leaving insert/cmdline or focus returns
	set_default_events = {
		"InsertLeave",
		"CmdlineLeave",
		"FocusGained",
		"VimEnter",
	},

	-- Do not restore Japanese/Chinese IME on InsertEnter
	set_previous_events = {},
	keep_quiet_on_no_binary = false,
	async_switch_im = true,
})
