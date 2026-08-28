local wezterm = require("wezterm")
local mux = wezterm.mux
local config = {}

-- maximum window when start
wezterm.on("gui-startup", function()
	local _, _, window = mux.spawn_window({})
	window:gui_window():maximize()
end)

-- disable window title bar
config.window_decorations = "RESIZE"

-- enable tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

-- tab bar max width
config.tab_max_width = 32

-- disable new tab button
config.show_new_tab_button_in_tab_bar = false

-- disable close tab button
config.show_close_tab_button_in_tabs = false

-- change tab bar color
config.window_frame = {
	-- for latte
	inactive_titlebar_bg = "#EFF1F5",
	active_titlebar_bg = "#EFF1F5",

	-- for mocha
	-- inactive_titlebar_bg = '#1E1E2E',
	-- active_titlebar_bg = '#1E1E2E',
}

-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
function tab_title(tab_info)
	local title = tab_info.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane
	-- in that tab
	return tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab_title(tab)
	if tab.is_active then
		return {
			{ Background = { Color = "#EFF1F5" } },
			{ Foreground = { Color = "#FF0000" } },
			{ Text = " " .. title .. " " },
		}
	end
	if tab.is_last_active then
		return {
			{ Background = { Color = "#EFF1F5" } },
			{ Foreground = { Color = "#000000" } },
			{ Text = " " .. title .. "*" },
		}
	end
	return {
		{ Background = { Color = "#EFF1F5" } },
		{ Foreground = { Color = "#000000" } },
		{ Text = title },
	}
end)

-- change terminal color scheme
config.color_scheme = "Catppuccin Latte"
-- config.color_scheme = 'Catppuccin Mocha'

-- terminal background image, best with mocha color scheme
--[[
config.background = {
  {
    source = { File = wezterm.config_dir .. '/pkdr23.png' },
    width = 'Cover',
    height = 'Cover',
    horizontal_align = 'Center',
    vertical_align = 'Middle',
  },
  {source = {Color = 'rgba(30, 30, 45, 0.90)',},height = '100%',width = '100%',},
}
--]]

-- change background opacity and blur
config.window_background_opacity = 0.9
config.macos_window_background_blur = 10

-- change font and size
config.font = wezterm.font_with_fallback({
	{
		family = "JetBrainsMonoNL Nerd Font",
		weight = "ExtraBold",
	},
	{
		family = "Maple Mono NF CN",
		weight = "ExtraBold",
	},
	{
		family = "MiSans L3",
		weight = "Regular",
	},
	{
		family = "Apple Color Emoji",
	},
})
config.font_size = 13.0

-- disable change window size when change font size
config.adjust_window_size_when_changing_font_size = false

-- shortcuts
config.keys = {
	-- ctrl + n to create new tab
	{
		key = "n",
		mods = "CTRL",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	-- ctrl + w to close tab
	{
		key = "w",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local tabs = window:mux_window():tabs()

			if #tabs <= 1 then
				return
			end

			window:perform_action(
				wezterm.action.CloseCurrentTab({
					confirm = false,
				}),
				pane
			)
		end),
	},
	-- ctrl + left|right arrow to move between tab
	{
		key = "LeftArrow",
		mods = "CTRL",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = "RightArrow",
		mods = "CTRL",
		action = wezterm.action.ActivateTabRelative(1),
	},

	-- ctrl + , . to move between panes
	{
		key = ",",
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection("Prev"),
	},
	{
		key = ".",
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection("Next"),
	},
	-- ctrl + = to split pane vertically, creating a new pane below
	{
		key = "=",
		mods = "CTRL",
		action = wezterm.action.SplitHorizontal({
			domain = "CurrentPaneDomain",
		}),
	},
	-- ctrl + - to split pane horizontally, creating a new pane on the right
	{
		key = "-",
		mods = "CTRL",
		action = wezterm.action.SplitVertical({
			domain = "CurrentPaneDomain",
		}),
	},
	-- ctrl + q to close pane
	{
		key = "q",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local tab = pane:tab()

			if #tab:panes() <= 1 then
				return
			end

			window:perform_action(
				wezterm.action.CloseCurrentPane({
					confirm = false,
				}),
				pane
			)
		end),
	},
	-- ctrl|shift + arrow resize pane
	{
		key = "UpArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Up", 1 }),
	},
	{
		key = "DownArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Down", 1 }),
	},
	{
		key = "LeftArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Left", 1 }),
	},
	{
		key = "RightArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.AdjustPaneSize({ "Right", 1 }),
	},

	-- send option key to neovim
	{
		key = "n",
		mods = "OPT",
		action = wezterm.action.SendString("\x1bn"),
	},
	{
		key = "w",
		mods = "OPT",
		action = wezterm.action.SendString("\x1bw"),
	},
	{
		key = ",",
		mods = "OPT",
		action = wezterm.action.SendString("\x1b,"),
	},
	{
		key = ".",
		mods = "OPT",
		action = wezterm.action.SendString("\x1b."),
	},
	{
		key = "q",
		mods = "OPT",
		action = wezterm.action.SendString("\x1bq"),
	},
	{
		key = "-",
		mods = "OPT",
		action = wezterm.action.SendString("\x1b-"),
	},
	{
		key = "=",
		mods = "OPT",
		action = wezterm.action.SendString("\x1b="),
	},
	{
		key = ";",
		mods = "OPT",
		action = wezterm.action.SendString("\x1b;"),
	},
	{
		key = "'",
		mods = "OPT",
		action = wezterm.action.SendString("\x1b'"),
	},
	{
		key = "/",
		mods = "OPT",
		action = wezterm.action.SendString("\x1b/"),
	},
	{
		key = "LeftArrow",
		mods = "OPT",
		action = wezterm.action.SendKey({
			key = "LeftArrow",
			mods = "ALT",
		}),
	},
	{
		key = "RightArrow",
		mods = "OPT",
		action = wezterm.action.SendKey({
			key = "RightArrow",
			mods = "ALT",
		}),
	},
	{
		key = "UpArrow",
		mods = "OPT|SHIFT",
		action = wezterm.action.SendKey({
			key = "UpArrow",
			mods = "ALT|SHIFT",
		}),
	},
	{
		key = "DownArrow",
		mods = "OPT|SHIFT",
		action = wezterm.action.SendKey({
			key = "DownArrow",
			mods = "ALT|SHIFT",
		}),
	},
	{
		key = "LeftArrow",
		mods = "OPT|SHIFT",
		action = wezterm.action.SendKey({
			key = "LeftArrow",
			mods = "ALT|SHIFT",
		}),
	},
	{
		key = "RightArrow",
		mods = "OPT|SHIFT",
		action = wezterm.action.SendKey({
			key = "RightArrow",
			mods = "ALT|SHIFT",
		}),
	},
}

return config
