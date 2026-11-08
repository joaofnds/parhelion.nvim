local refinement = require "parhelion.refinement"

local background = vim.o.background
local dark = background == "dark"

local function tone(color) return refinement.color(background, color) end

local page = tone(dark and "#002B36" or "#FDF6E3")
local bar = tone(dark and "#073642" or "#EEE8D5")
local bar_text = tone(dark and "#93A1A1" or "#586E75")
local blue, green, magenta, red, orange = tone "#268BD2", tone "#859900", tone "#D33682", tone "#DC322F", tone "#CB4B16"

return {
	normal = {
		a = { fg = page, bg = blue, gui = require("parhelion").draws_bold() and "bold" or nil },
		b = { fg = bar, bg = bar_text },
		c = { fg = bar_text, bg = bar },
		z = { fg = page, bg = blue },
	},
	insert = { a = { fg = page, bg = green } },
	visual = { a = { fg = page, bg = magenta } },
	replace = { a = { fg = page, bg = red } },
	command = { a = { fg = page, bg = orange } },
}
