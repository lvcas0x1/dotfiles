local conform = require("conform")
local lualine = require("lualine")

-- Formatter status
local function formatter_status()
	local formatters = conform.list_formatters_for_buffer()

	if #formatters == 0 then
		return ""
	end

	return "󱌣 " .. table.concat(formatters, ",")
end

local theme = require("lualine.themes.onelight")

theme.normal.c.bg = "#EFF1F5"
theme.inactive.c.bg = "#EFF1F5"

lualine.setup({
	options = {
		icons_enabled = true,
		theme = theme,
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = { "neo-tree" },
			winbar = {},
		},
		ignore_focus = {},
		always_divide_middle = true,
		always_show_tabline = true,
		globalstatus = true,
		refresh = {
			statusline = 500,
			tabline = 500,
			winbar = 500,
			refresh_time = 16,
			events = {
				"WinEnter",
				"BufEnter",
				"BufWritePost",
				"SessionLoadPost",
				"FileChangedShellPost",
				"VimResized",
				"Filetype",
				"CursorMoved",
				"CursorMovedI",
				"ModeChanged",
			},
		},
	},

	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = {
			{ "filename", path = 3 },
			"lsp_status",
			formatter_status,
		},
		lualine_x = { "encoding" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},

	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = {
			{ "filename", path = 3 },
		},
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},

	tabline = {},
	winbar = {},
	inactive_winbar = {},

	extensions = {
		"fzf",
		"man",
		"mason",
		"neo-tree",
		"quickfix",
		"toggleterm",
		"trouble",
	},
})
