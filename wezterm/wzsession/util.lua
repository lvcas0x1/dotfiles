local wezterm = require("wezterm")

local M = {}

M.is_windows = wezterm.target_triple:find("windows") ~= nil
M.separator = M.is_windows and "\\" or "/"

function M.ensure_dir(path)
	if M.is_windows then
		os.execute('mkdir "' .. path .. '" 2>NUL')
	else
		os.execute('mkdir -p "' .. path .. '"')
	end
end

-- wezterm.json_encode leaves raw C0 control bytes in its output, and captured
-- scrollback is full of them (ESC = 0x1B), which makes the document invalid
-- JSON. Escaping them after encoding is safe: no JSON structural character is
-- a control character, so nothing else can be touched.
local function sanitize(s)
	local out = s:gsub("[\x00-\x1F]", function(c)
		return string.format("\\u%04X", string.byte(c))
	end)
	return out
end

function M.write_json(path, tbl)
	local ok, encoded = pcall(wezterm.json_encode, tbl)
	if not ok then
		return false, "json_encode failed: " .. tostring(encoded)
	end
	-- Write to a sibling temp file and rename over the target. rename(2) is
	-- atomic within a directory, so a reader never sees a half-written state
	-- and concurrent savers cannot interleave. This is what removes the need
	-- for the kind of lock tmux-continuum has to take.
	local tmp = path .. ".tmp"
	local f, err = io.open(tmp, "w+")
	if not f then
		return false, tostring(err)
	end
	local wrote, werr = pcall(function()
		f:write(sanitize(encoded))
		f:flush()
	end)
	f:close()
	if not wrote then
		os.remove(tmp)
		return false, tostring(werr)
	end
	local renamed, rerr = os.rename(tmp, path)
	if not renamed then
		os.remove(tmp)
		return false, "rename failed: " .. tostring(rerr)
	end
	return true
end

function M.write_text(path, str)
	local f = io.open(path, "w+")
	if not f then
		return false
	end
	f:write(str)
	f:close()
	return true
end

function M.read_text(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local s = f:read("*l")
	f:close()
	return s
end

function M.read_json(path)
	local f = io.open(path, "r")
	if not f then
		return nil, "cannot open " .. path
	end
	local raw = f:read("*a")
	f:close()
	if not raw or raw == "" then
		return nil, "empty file: " .. path
	end
	local ok, parsed = pcall(wezterm.json_parse, sanitize(raw))
	if not ok then
		return nil, "json_parse failed: " .. tostring(parsed)
	end
	return parsed
end

-- Session names become file names, so keep them to a boring character set.
function M.slug(name)
	local s = name:gsub("%s+", "-")
	s = s:gsub("[^%w%-%_%.]", "_")
	return s
end

function M.basename(path)
	local b = path:gsub("^.*[/\\]", "")
	b = b:gsub("%.json$", "")
	return b
end

function M.list_json(dir)
	local ok, files = pcall(wezterm.glob, dir .. M.separator .. "*.json")
	if not ok or not files then
		return {}
	end
	table.sort(files)
	return files
end

function M.merge(base, over)
	local out = {}
	for k, v in pairs(base or {}) do
		out[k] = v
	end
	for k, v in pairs(over or {}) do
		if v ~= nil then
			out[k] = v
		end
	end
	return out
end

return M
