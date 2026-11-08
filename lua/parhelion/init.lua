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

local function is_a_sign(name) return name:find "Signs?%u" ~= nil or name:find "Sign$" ~= nil end

local function is_turned_off(name, plugins)
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
	local plugins, kept = require "parhelion.plugins", {}
	for name, hl in pairs(groups) do
		if not is_turned_off(name, plugins) then kept[name] = hl end
	end

	return kept
end

local function without_backgrounds(built, groups)
	local page, gutter_fill = built.colors.page, groups.LineNr.bg:lower()
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

local raises_on_a_missing_color = {
	__index = function(_, name) error(string.format("parhelion has no color named %s", name), 2) end,
}

local function colors(built) return setmetatable(vim.deepcopy(built.colors), raises_on_a_missing_color) end

local scratch = vim.api.nvim_create_namespace "parhelion.overrides"

-- Neovim refuses a bad attribute only when a group is set, so each override is set first in a namespace no window
-- draws with, before the load clears the active colorscheme.
local function refuse_what_neovim_refuses(name, hl)
	local accepted, message = pcall(vim.api.nvim_set_hl, scratch, name, hl)
	if not accepted then error(string.format("parhelion cannot set overrides.%s: %s", name, message), 0) end
end

local function validate_override(name, override)
	if type(name) ~= "string" then
		error(string.format("overrides[%s]: expected a group name, got %s", vim.inspect(name), type(name)), 0)
	end
	vim.validate("overrides." .. name, override, "table")
end

local function overridden(built, groups)
	local overrides = options.overrides
	if type(overrides) == "function" then
		overrides = overrides(colors(built))
		vim.validate("the result of overrides", overrides, "table")
	end

	if next(overrides) == nil then return groups end

	local result, spelling = {}, {}
	for name, hl in pairs(groups) do
		result[name], spelling[name:lower()] = hl, name
	end
	for name, override in pairs(overrides) do
		validate_override(name, override)
		name = spelling[name:lower()] or name
		local current = result[name]
		if override.link or current == nil or current.link then
			result[name] = override
		else
			result[name] = vim.tbl_extend("force", current, override)
		end
		refuse_what_neovim_refuses(name, result[name])
	end

	return result
end

local function turns_a_plugin_off() return vim.tbl_contains(vim.tbl_values(options.plugins), false) end

local function with_options(built)
	local groups = built.groups
	if turns_a_plugin_off() then groups = without_plugins_turned_off(groups) end
	if options.transparent then groups = without_backgrounds(built, groups) end
	if options.dim_inactive then groups = vim.tbl_extend("force", groups, { NormalNC = { bg = built.dimmed } }) end
	if not options.bold then groups = without_style("bold", groups) end
	if not options.italic then groups = without_style("italic", groups) end

	return overridden(built, groups)
end

local function set_fzf_colors()
	if options.plugins.fzf == false then
		if vim.deep_equal(vim.g.fzf_colors, fzf_colors) then vim.g.fzf_colors = nil end
	elseif vim.g.fzf_colors == nil then
		vim.g.fzf_colors = fzf_colors
	end
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
	if type(user_options.overrides) == "table" then
		for name, override in pairs(user_options.overrides) do
			validate_override(name, override)
		end
	end

	vim.validate("plugins", user_options.plugins, "table", true)
	local plugins = require "parhelion.plugins"
	for plugin, on in pairs(user_options.plugins or {}) do
		if plugins[plugin] == nil then
			error(string.format("parhelion sets no groups for a plugin named %s", plugin), 2)
		end
		vim.validate("plugins." .. plugin, on, "boolean")
	end

	local previous = options
	options = vim.tbl_extend("force", defaults, user_options)
	if vim.g.colors_name ~= "parhelion" then return end

	local reloaded, message = pcall(vim.cmd.colorscheme, "parhelion")
	if not reloaded then
		options = previous
		error(message, 2)
	end
end

function M.draws_bold() return options.bold end

local built_directory = debug.getinfo(1, "S").source:match "^@(.*[/\\])" .. "built/"
local built_tables = {}

function M.built(background)
	if not built_tables[background] then
		local built = assert(loadfile(built_directory .. background .. ".lua"))()
		setmetatable(built.colors, raises_on_a_missing_color)
		built_tables[background] = built
	end

	return built_tables[background]
end

function M.load()
	local built = M.built(vim.o.background)
	local groups = with_options(built)

	if vim.g.colors_name then
		vim.cmd "hi clear"
	else
		vim.cmd "syntax reset"
	end
	vim.g.colors_name = "parhelion"
	set_fzf_colors()

	for index, color in ipairs(built.terminal) do
		vim.g["terminal_color_" .. (index - 1)] = color
	end

	for name, hl in pairs(groups) do
		vim.api.nvim_set_hl(0, name, hl)
	end
end

return M
