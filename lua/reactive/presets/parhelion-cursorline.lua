local chrome = require "parhelion.chrome"

local scale = chrome.scale[vim.o.background]
local hues = chrome.hues[vim.o.background]
local constant = chrome.constant_hue[vim.o.background]

-- A fill keeps `share` of a color and takes the rest from black in dark mode and from white in light, so it stays on its
-- page's side and the code drawn over it keeps its contrast.
local far_end = vim.o.background == "dark" and { 0, 0, 0 } or { 255, 255, 255 }

local function tint(hex, share)
	local channels = {}
	for index, start in ipairs { 2, 4, 6 } do
		local value = tonumber(hex:sub(start, start + 1), 16)
		table.insert(channels, math.floor(far_end[index] + (value - far_end[index]) * share + 0.5))
	end

	return string.format("#%02X%02X%02X", unpack(channels))
end

local function cursor_line(color) return { CursorLine = { bg = color }, CursorLineNr = { bg = color } } end

local function line(color) return { winhl = cursor_line(color) } end

local function selection(color) return { winhl = { Visual = { bg = color } } } end

return {
	name = "parhelion-cursorline",
	static = { winhl = { inactive = cursor_line(tint(scale.raised, 0.75)) } },
	modes = {
		n = line(scale.raised),
		i = line(tint(hues.blue, 0.3)),
		R = line(tint(hues.cyan, 0.34)),
		no = {
			operators = {
				[{ "gu", "gU", "g~", "~" }] = line(tint(scale.strong, 0.2)),
				d = line(tint(hues.red, 0.36)),
				y = line(tint(constant, 0.3)),
				c = line(tint(hues.blue, 0.34)),
			},
		},
		[{ "v", "V", "\22" }] = selection(tint(hues.green, 0.4)),
		[{ "s", "S", "\19" }] = selection(tint(hues.violet, 0.4)),
	},
}
