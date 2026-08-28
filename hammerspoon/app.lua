-- hyper keys
local hyper = { 'ctrl', 'alt', 'cmd' }

-- launcher
local appBindings = {
  w = 'WezTerm',
}

local function launchApp(appName)
  hs.application.launchOrFocus(appName)
end

for key, appName in pairs(appBindings) do
  hs.hotkey.bind(hyper, key, function()
    launchApp(appName)
  end)
end

-- new window
local function newAppWindow(appName)
  hs.task.new('/usr/bin/open', nil, { '-n', '-a', appName }):start()
end

hs.hotkey.bind(hyper, 'w', function()
  newAppWindow('Wezterm')
end)
