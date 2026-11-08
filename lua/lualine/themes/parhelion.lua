local built = require("parhelion").built(vim.o.background)
local colors, bar_text = built.colors, built.groups.StatusLine.fg

return {
	normal = {
		a = { fg = colors.page, bg = colors.blue, gui = require("parhelion").draws_bold() and "bold" or nil },
		b = { fg = colors.raised, bg = bar_text },
		c = { fg = bar_text, bg = colors.raised },
		z = { fg = colors.page, bg = colors.blue },
	},
	insert = { a = { fg = colors.page, bg = colors.green } },
	visual = { a = { fg = colors.page, bg = colors.magenta } },
	replace = { a = { fg = colors.page, bg = colors.red } },
	command = { a = { fg = colors.page, bg = colors.orange } },
}
