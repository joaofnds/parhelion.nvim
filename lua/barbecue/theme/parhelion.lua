local colors = require("parhelion").built(vim.o.background).colors

local theme = {
	normal = { fg = colors.body },
	ellipsis = { fg = colors.quiet },
	separator = { fg = colors.quiet },
	modified = { fg = colors.warn },
	dirname = { fg = colors.quiet },
	basename = { fg = colors.body, bold = require("parhelion").draws_bold() },
	context = { fg = colors.quiet },
}

for _, kind in
	ipairs(
		vim.split(
			"file module namespace package class method property field constructor enum interface function variable constant "
				.. "string number boolean array object key null enum_member struct event operator type_parameter",
			" "
		)
	)
do
	theme["context_" .. kind] = { fg = colors.quiet }
end

return theme
