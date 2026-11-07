local chrome = require "parhelion.chrome"
local refinement = require "parhelion.refinement"

local M = {}

local function set_final(groups)
	for name, hl in pairs(groups) do
		vim.api.nvim_set_hl(0, name, hl)
	end
end

local function set_refined(background, groups)
	for name, hl in pairs(groups) do
		vim.api.nvim_set_hl(0, name, refinement.highlight(background, hl))
	end
end

local fzf_colors = {
	["bg"] = { "bg", "NormalFloat" },
	["bg+"] = { "bg", "PmenuSel" },
	["border"] = { "fg", "FloatBorder" },
	["fg"] = { "fg", "NormalFloat" },
	["fg+"] = { "fg", "Title" },
	["gutter"] = { "bg", "NormalFloat" },
	["header"] = { "fg", "PmenuExtra" },
	["hl"] = { "fg", "PmenuMatch" },
	["hl+"] = { "fg", "PmenuMatch" },
	["info"] = { "fg", "PmenuExtra" },
	["marker"] = { "fg", "PmenuMatch" },
	["pointer"] = { "fg", "PmenuMatch" },
	["prompt"] = { "fg", "PmenuExtra" },
	["query"] = { "fg", "NormalFloat" },
	["scrollbar"] = { "fg", "FloatBorder" },
	["separator"] = { "fg", "FloatBorder" },
	["spinner"] = { "fg", "PmenuMatch" },
}

function M.load()
	local background = vim.o.background
	local base = require("parhelion.base." .. background)
	local repaired_groups = refinement.repaired_groups(background, base.groups)
	local chrome_groups = chrome.groups(background)

	if vim.g.colors_name then vim.cmd "hi clear" end
	vim.cmd "syntax reset"
	vim.g.colors_name = "parhelion"
	if vim.g.fzf_colors == nil then vim.g.fzf_colors = fzf_colors end

	for index, color in ipairs(base.terminal) do
		vim.g["terminal_color_" .. (index - 1)] = refinement.color(background, color)
	end

	set_refined(background, base.groups)
	set_final(repaired_groups)
	set_final(chrome_groups)
end

return M
