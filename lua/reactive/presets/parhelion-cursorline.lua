local parhelion = require "parhelion"

local function washed(wash)
	return {
		winhl = function()
			local built = parhelion.built(vim.o.background)
			local fill, number = built.colors[wash], built.groups.CursorLineNr

			return {
				CursorLine = { bg = fill },
				CursorLineNr = { fg = number.fg, bg = fill, bold = number.bold and parhelion.draws_bold() },
			}
		end,
	}
end

return {
	name = "parhelion-cursorline",
	modes = {
		i = washed "added_wash",
		R = washed "removed_wash",
	},
}
