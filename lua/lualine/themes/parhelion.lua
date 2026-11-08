local built = require("parhelion").built(vim.o.background)
local colors, hues, bar_text = built.colors, built.mode_hues, built.groups.StatusLine.fg

return {
	normal = {
		a = { fg = colors.page, bg = hues.normal, gui = require("parhelion").draws_bold() and "bold" or nil },
		b = { fg = colors.raised, bg = bar_text },
		c = { fg = bar_text, bg = colors.raised },
		z = { fg = colors.page, bg = hues.normal },
	},
	insert = { a = { fg = colors.page, bg = hues.insert } },
	visual = { a = { fg = colors.page, bg = hues.visual } },
	replace = { a = { fg = colors.page, bg = hues.replace } },
	command = { a = { fg = colors.page, bg = hues.command } },
}
