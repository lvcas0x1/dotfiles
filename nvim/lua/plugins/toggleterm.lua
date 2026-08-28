local toggleterm = require("toggleterm")

toggleterm.setup({
	direction = "float",

	size = function(term)
		if term.direction == "horizontal" then
			return math.floor(vim.o.lines * 0.3)
		end

		if term.direction == "vertical" then
			return math.floor(vim.o.columns * 0.4)
		end

		return 20
	end,

	-- set default key to nil
	open_mapping = nil,

	-- hide line numbers
	hide_numbers = true,

	-- shade background for terminal
	shade_terminals = true,

	-- start terminal in terminal mode
	start_in_insert = true,

	-- remember last window size
	persist_size = true,

	-- close on exit
	close_on_exit = true,

	-- auto scroll to bottom
	auto_scroll = true,

	-- insert_mappings = true,

	-- remember last terminal mode
	persist_mode = false,

	shell = vim.o.shell,

	float_opts = {
		border = "rounded",

		width = function()
			return math.floor(vim.o.columns * 0.7)
		end,

		height = function()
			return math.floor(vim.o.lines * 0.5)
		end,
	},
})
