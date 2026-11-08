local chrome = require "parhelion.chrome"
local refinement = require "parhelion.refinement"

local M = {}

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

function M.build(background)
	local base = require("parhelion.base." .. background)

	return {
		colors = vim.tbl_extend(
			"error",
			{ background = background },
			chrome.scale[background],
			chrome.hues[background]
		),
		constant = chrome.constant_hue[background],
		dimmed = chrome.dimmed[background],
		terminal = vim.tbl_map(function(color) return refinement.color(background, color) end, base.terminal),
		groups = layered {
			vim.tbl_map(function(hl) return refinement.highlight(background, hl) end, base.groups),
			refinement.repaired_groups(background, base.groups),
			chrome.groups(background),
		},
	}
end

M.command = [[nvim --headless --clean --cmd "set rtp^=." -c "lua require('parhelion.build').write()" -c "qa!"]]

local function sorted_keys(values)
	local keys = vim.tbl_keys(values)
	table.sort(keys)

	return keys
end

local function literal(value)
	if type(value) == "string" then return string.format("%q", value) end

	return tostring(value)
end

local function inline(hl)
	local fields = vim.tbl_map(function(key) return key .. " = " .. literal(hl[key]) end, sorted_keys(hl))
	if #fields == 0 then return "{}" end

	return "{ " .. table.concat(fields, ", ") .. " }"
end

local function shared_looks(groups, names)
	local looks, look_of = {}, {}
	for _, name in ipairs(names) do
		local look = inline(groups[name])
		if not look_of[look] then
			table.insert(looks, look)
			look_of[look] = #looks
		end
	end

	return looks, look_of
end

local function source(built)
	local names = sorted_keys(built.groups)
	local looks, look_of = shared_looks(built.groups, names)

	local lines = {
		"-- Written by " .. M.command,
		"-- from the base tables, refinement.lua and chrome.lua. Edit those, not this file.",
		"local looks = {",
	}
	for _, look in ipairs(looks) do
		table.insert(lines, "\t" .. look .. ",")
	end
	table.insert(lines, "}")
	table.insert(lines, "")
	table.insert(lines, "return {")

	table.insert(lines, "\tcolors = {")
	for _, name in ipairs(sorted_keys(built.colors)) do
		table.insert(lines, string.format("\t\t%s = %s,", name, literal(built.colors[name])))
	end
	table.insert(lines, "\t},")

	table.insert(lines, string.format("\tconstant = %s,", literal(built.constant)))
	table.insert(lines, string.format("\tdimmed = %s,", literal(built.dimmed)))

	table.insert(lines, "\tgroups = {")
	for _, name in ipairs(names) do
		table.insert(lines, string.format("\t\t[%q] = looks[%d],", name, look_of[inline(built.groups[name])]))
	end
	table.insert(lines, "\t},")

	table.insert(lines, "\tterminal = {")
	for _, color in ipairs(built.terminal) do
		table.insert(lines, string.format("\t\t%s,", literal(color)))
	end
	table.insert(lines, "\t},")

	table.insert(lines, "}")

	return lines
end

local function write_themes(root, themes)
	for path, text in pairs(themes) do
		vim.fn.mkdir(vim.fs.dirname(root .. "/" .. path), "p")
		local file = assert(io.open(root .. "/" .. path, "wb"))
		file:write(text)
		file:close()
	end
end

function M.write()
	local module_directory = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
	local built_directory, root = module_directory .. "/built", vim.fn.fnamemodify(module_directory, ":h:h")
	vim.fn.mkdir(built_directory, "p")

	for _, background in ipairs { "dark", "light" } do
		local built = M.build(background)
		vim.fn.writefile(source(built), built_directory .. "/" .. background .. ".lua")
		write_themes(root, require("parhelion.extras").themes(built))
	end
end

return M
