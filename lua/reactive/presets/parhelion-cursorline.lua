local chrome = require "parhelion.chrome"

local scale = chrome.scale[vim.o.background]
local hues = chrome.hues[vim.o.background]
local constant = chrome.constant_hue[vim.o.background]

local far_end = vim.o.background == "dark" and { 0, 0, 0 } or { 255, 255, 255 }

local function fill_keeping(hex, share)
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
	static = { winhl = { inactive = cursor_line(fill_keeping(scale.raised, 0.75)) } },
	modes = {
		n = line(scale.raised),
		i = line(fill_keeping(hues.blue, 0.3)),
		R = line(fill_keeping(hues.cyan, 0.34)),
		no = {
			operators = {
				[{ "gu", "gU", "g~", "~" }] = line(fill_keeping(scale.strong, 0.2)),
				d = line(fill_keeping(hues.red, 0.36)),
				y = line(fill_keeping(constant, 0.3)),
				c = line(fill_keeping(hues.blue, 0.34)),
			},
		},
		[{ "v", "V", "\22" }] = selection(fill_keeping(hues.green, 0.4)),
		[{ "s", "S", "\19" }] = selection(fill_keeping(hues.violet, 0.4)),
	},
}
