local scale = require("parhelion.chrome").scale[vim.o.background]

local theme = {
	normal = { fg = scale.body },
	ellipsis = { fg = scale.quiet },
	separator = { fg = scale.quiet },
	modified = { fg = scale.warn },
	dirname = { fg = scale.quiet },
	basename = { fg = scale.body, bold = true },
	context = { fg = scale.quiet },
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
	theme["context_" .. kind] = { fg = scale.quiet }
end

return theme
