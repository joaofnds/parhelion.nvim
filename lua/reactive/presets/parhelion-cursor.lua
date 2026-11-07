local chrome = require "parhelion.chrome"

local hues = chrome.hues[vim.o.background]
local constant = chrome.constant_hue[vim.o.background]

local function cursor(color) return { hl = { ReactiveCursor = { bg = color } } } end

return {
	name = "parhelion-cursor",
	init = function() vim.opt.guicursor:append "a:ReactiveCursor" end,
	modes = {
		n = cursor(hues.yellow),
		i = cursor(hues.cyan),
		R = cursor(hues.cyan),
		no = {
			operators = {
				d = cursor(hues.red),
				y = cursor(constant),
				c = cursor(hues.blue),
			},
		},
		[{ "v", "V", "\22" }] = cursor(hues.green),
		[{ "s", "S", "\19" }] = cursor(hues.violet),
	},
}
