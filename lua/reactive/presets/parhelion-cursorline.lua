local chrome = require "parhelion.chrome"

local scale = chrome.scale[vim.o.background]
local hues = chrome.hues[vim.o.background]
local constant = chrome.constant_hue[vim.o.background]

local function darker(hex, factor)
	local channels = {}
	for start = 2, 6, 2 do
		local value = tonumber(hex:sub(start, start + 1), 16)
		table.insert(channels, math.floor(value * factor + 0.5))
	end

	return string.format("#%02X%02X%02X", unpack(channels))
end

local function cursor_line(color) return { CursorLine = { bg = color }, CursorLineNr = { bg = color } } end

local function line(color) return { winhl = cursor_line(color) } end

local function selection(color) return { winhl = { Visual = { bg = color } } } end

return {
	name = "parhelion-cursorline",
	static = { winhl = { inactive = cursor_line(darker(scale.raised, 0.75)) } },
	modes = {
		n = line(scale.raised),
		i = line(darker(hues.blue, 0.3)),
		R = line(darker(hues.cyan, 0.4)),
		no = {
			operators = {
				[{ "gu", "gU", "g~", "~" }] = line(scale.ghost),
				d = line(darker(hues.red, 0.4)),
				y = line(darker(constant, 0.3)),
				c = line(darker(hues.blue, 0.4)),
			},
		},
		[{ "v", "V", "\22" }] = selection(darker(hues.green, 0.4)),
		[{ "s", "S", "\19" }] = selection(darker(hues.violet, 0.4)),
	},
}
