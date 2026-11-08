local built = require("parhelion").built(vim.o.background)
local colors, constant = built.colors, built.constant

local function cursor(color) return { hl = { ReactiveCursor = { bg = color } } } end

return {
	name = "parhelion-cursor",
	init = function() vim.opt.guicursor:append "a:ReactiveCursor" end,
	modes = {
		n = cursor(colors.yellow),
		i = cursor(colors.cyan),
		R = cursor(colors.cyan),
		no = {
			operators = {
				d = cursor(colors.red),
				y = cursor(constant),
				c = cursor(colors.blue),
			},
		},
		[{ "v", "V", "\22" }] = cursor(colors.green),
		[{ "s", "S", "\19" }] = cursor(colors.violet),
	},
}
