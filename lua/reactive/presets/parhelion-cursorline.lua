local parhelion = require "parhelion"

local built = parhelion.built(vim.o.background)
local colors, number = built.colors, built.groups.CursorLineNr

local function washed(wash)
	return {
		winhl = {
			CursorLine = { bg = wash },
			CursorLineNr = { fg = number.fg, bg = wash, bold = number.bold and parhelion.draws_bold() },
		},
	}
end

return {
	name = "parhelion-cursorline",
	modes = {
		i = washed(colors.added_wash),
		R = washed(colors.removed_wash),
	},
}
