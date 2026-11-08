local refinement = require "parhelion.refinement"

if vim.g.colors_name then vim.cmd "hi clear" end
vim.cmd "syntax reset"
vim.g.colors_name = "base_refined"

local background = vim.o.background
local base = require("parhelion.base." .. background)

for name, hl in pairs(base.groups) do
	vim.api.nvim_set_hl(0, name, hl)
end

for index, color in ipairs(base.terminal) do
	vim.g["terminal_color_" .. (index - 1)] = refinement.color(background, color)
end

-- A cleared group must stay cleared, because a capture falls back past it and would stop at a defined one.
for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
	local has_color = false
	for _, attribute in ipairs(refinement.color_attributes) do
		if hl[attribute] then
			has_color = true
			hl[attribute] = refinement.color(background, string.format("#%06x", hl[attribute]))
		end
	end

	if has_color then vim.api.nvim_set_hl(0, name, hl) end
end

for name, hl in pairs(refinement.repaired_groups(background, base.groups)) do
	vim.api.nvim_set_hl(0, name, hl)
end

-- The views frame the buffers they compare with a tab bar and window separators, run mini.cursorword, open Neogit and
-- Diffview with their diff lines and marks, and one of the buffers is markdown. Those are restyled on purpose, and
-- every other chrome group is left out so a leak shows up as a difference.
local chrome = require "parhelion.chrome"
for _, family in ipairs {
	"bufferline",
	"diff_lines",
	"diff_marks",
	"diffview",
	"markdown_text",
	"mini_cursorword",
	"neogit",
	"tab_line",
	"window_separators",
} do
	for name, hl in pairs(chrome.family_groups(background, family)) do
		vim.api.nvim_set_hl(0, name, hl)
	end
end
