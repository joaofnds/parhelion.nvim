local parhelion = require "parhelion"

local function built() return parhelion.built(vim.o.background) end

local function cursor_in(mode)
	return {
		hl = function()
			local current = built()

			return { ReactiveCursor = { fg = current.colors.page, bg = current.mode_hues[mode] } }
		end,
	}
end

return {
	name = "parhelion-cursor",
	init = function() vim.opt.guicursor:append "a:ReactiveCursor" end,
	static = {
		hl = function()
			local cursor = built().groups.Cursor

			return { ReactiveCursor = { fg = cursor.fg, bg = cursor.bg } }
		end,
	},
	modes = {
		[{ "v", "V", "\22", "s", "S", "\19" }] = cursor_in "visual",
		i = cursor_in "insert",
		R = cursor_in "replace",
		c = cursor_in "command",
	},
}
