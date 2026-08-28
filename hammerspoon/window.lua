-- disable animation
hs.window.animationDuration = 0

-- helper
local function focusedWindow()
	return hs.window.focusedWindow()
end

local function isOnUnit(win, unit)
	local screen = win:screen()
	local sf = screen:frame()
	local wf = win:frame()

	local target = hs.geometry.rect(sf.x + sf.w * unit[1], sf.y + sf.h * unit[2], sf.w * unit[3], sf.h * unit[4])

	local function close(a, b)
		return math.abs(a - b) < 10
	end

	return close(wf.x, target.x) and close(wf.y, target.y) and close(wf.w, target.w) and close(wf.h, target.h)
end

local function moveUnitWithScreenHop(unit, direction)
	local win = focusedWindow()
	if not win then
		return
	end

	local screen = win:screen()

	if direction and isOnUnit(win, unit) then
		local nextScreen = nil

		if direction == "left" then
			nextScreen = screen:toEast()
		elseif direction == "right" then
			nextScreen = screen:toWest()
		end

		if nextScreen then
			win:moveToScreen(nextScreen)
			win:moveToUnit(unit)
			return
		end
	end

	win:moveToUnit(unit)
end

local function maximizeWindow()
	local win = focusedWindow()
	if not win then
		return
	end

	win:maximize()
end

local function centerWindow()
	local win = focusedWindow()
	if not win then
		return
	end

	local screen = win:screen()
	local sf = screen:frame()
	local wf = win:frame()

	wf.x = sf.x + (sf.w - wf.w) / 2
	wf.y = sf.y + (sf.h - wf.h) / 2

	win:setFrame(wf)
end

-- Units
local UNIT_LEFT_HALF = { 0, 0, 0.5, 1 }
local UNIT_RIGHT_HALF = { 0.5, 0, 0.5, 1 }

-- Left half
hs.hotkey.bind({ "cmd" }, "left", function()
	moveUnitWithScreenHop(UNIT_LEFT_HALF, "left")
end)

-- Right half
hs.hotkey.bind({ "cmd" }, "right", function()
	moveUnitWithScreenHop(UNIT_RIGHT_HALF, "right")
end)

-- Maximize
hs.hotkey.bind({ "cmd" }, "up", function()
	maximizeWindow()
end)

-- Center window
hs.hotkey.bind({ "cmd" }, "down", function()
	centerWindow()
end)
