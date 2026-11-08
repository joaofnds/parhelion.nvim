local chrome = require "parhelion.chrome"
local plugins = require "parhelion.plugins"
local refinement = require "parhelion.refinement"

local M = {}

local defaults = {
	transparent = false,
	dim_inactive = false,
	bold = true,
	italic = true,
	overrides = {},
	plugins = {},
}

local options = vim.deepcopy(defaults)

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

local gutter = { LineNr = true, LineNrAbove = true, LineNrBelow = true, SignColumn = true, FoldColumn = true }

local function is_a_sign(name)
	return name:find("Sign", 1, true) ~= nil or name:match "Nr$" ~= nil or name:match "Cul$" ~= nil
end

-- Neovim's group names ignore case, so a later layer replaces an earlier group whatever case either spells it in.
local function layered(layers)
	local groups, spelling = {}, {}
	for _, layer in ipairs(layers) do
		for name, hl in pairs(layer) do
			local key = name:lower()
			if spelling[key] then groups[spelling[key]] = nil end
			groups[name], spelling[key] = hl, name
		end
	end

	return groups
end

local function is_turned_off(name)
	for plugin, on in pairs(options.plugins) do
		if not on then
			for _, pattern in ipairs(plugins[plugin]) do
				if name:find(pattern) then return true end
			end
		end
	end

	return false
end

local function without_plugins_turned_off(groups)
	local kept = {}
	for name, hl in pairs(groups) do
		if not is_turned_off(name) then kept[name] = hl end
	end

	return kept
end

local function without_backgrounds(background, groups)
	local page, gutter_fill = chrome.scale[background].page, groups.LineNr.bg:lower()
	local cleared = {}
	for name, hl in pairs(groups) do
		local fill = hl.bg and hl.bg:lower()
		if fill and (fill == page or gutter[name] or (fill == gutter_fill and is_a_sign(name))) then
			hl = vim.tbl_extend("force", hl, { bg = "NONE" })
		end
		cleared[name] = hl
	end

	return cleared
end

local function without_style(style, groups)
	return vim.tbl_map(function(hl) return vim.tbl_extend("force", hl, { [style] = false }) end, groups)
end

local function colors(background)
	return vim.tbl_extend("error", { background = background }, chrome.scale[background], chrome.hues[background])
end

local function overridden(background, groups)
	local overrides = options.overrides
	if type(overrides) == "function" then overrides = overrides(colors(background)) end

	local result = vim.deepcopy(groups)
	for name, override in pairs(overrides) do
		local current = result[name]
		if override.link or current == nil or current.link then
			result[name] = override
		else
			result[name] = vim.tbl_extend("force", current, override)
		end
	end

	return result
end

local function with_options(background, groups)
	groups = without_plugins_turned_off(groups)
	if options.transparent then groups = without_backgrounds(background, groups) end
	if options.dim_inactive then groups.NormalNC = { bg = chrome.dimmed[background] } end
	if not options.bold then groups = without_style("bold", groups) end
	if not options.italic then groups = without_style("italic", groups) end

	return overridden(background, groups)
end

function M.setup(user_options)
	user_options = user_options or {}
	for name in pairs(user_options) do
		if defaults[name] == nil then error(string.format("parhelion has no option named %s", name), 2) end
	end
	vim.validate("transparent", user_options.transparent, "boolean", true)
	vim.validate("dim_inactive", user_options.dim_inactive, "boolean", true)
	vim.validate("bold", user_options.bold, "boolean", true)
	vim.validate("italic", user_options.italic, "boolean", true)
	vim.validate("overrides", user_options.overrides, { "table", "function" }, true)
	vim.validate("plugins", user_options.plugins, "table", true)
	for plugin, on in pairs(user_options.plugins or {}) do
		if plugins[plugin] == nil then
			error(string.format("parhelion sets no groups for a plugin named %s", plugin), 2)
		end
		vim.validate("plugins." .. plugin, on, "boolean")
	end

	options = vim.tbl_extend("force", defaults, user_options)
	if vim.g.colors_name == "parhelion" then vim.cmd.colorscheme "parhelion" end
end

function M.load()
	local background = vim.o.background
	local base = require("parhelion.base." .. background)
	local groups = with_options(
		background,
		layered {
			vim.tbl_map(function(hl) return refinement.highlight(background, hl) end, base.groups),
			refinement.repaired_groups(background, base.groups),
			chrome.groups(background),
		}
	)

	if vim.g.colors_name then vim.cmd "hi clear" end
	vim.cmd "syntax reset"
	vim.g.colors_name = "parhelion"
	if vim.g.fzf_colors == nil then vim.g.fzf_colors = fzf_colors end

	for index, color in ipairs(base.terminal) do
		vim.g["terminal_color_" .. (index - 1)] = refinement.color(background, color)
	end

	for name, hl in pairs(groups) do
		vim.api.nvim_set_hl(0, name, hl)
	end
end

return M
