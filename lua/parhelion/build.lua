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

local gutter = { LineNr = true, LineNrAbove = true, LineNrBelow = true, SignColumn = true, FoldColumn = true }

local function is_a_sign(name) return name:find "Signs?%u" ~= nil or name:find "Sign$" ~= nil end

local function cleared_by_transparent(groups, page)
	local gutter_fill, names = groups.LineNr.bg:lower(), {}
	for name, hl in pairs(groups) do
		local fill = hl.bg and hl.bg:lower()
		if fill and (fill == page or gutter[name] or (fill == gutter_fill and is_a_sign(name))) then
			table.insert(names, name)
		end
	end
	table.sort(names)

	return names
end

function M.build(background)
	local base = require("parhelion.base." .. background)
	local groups = layered {
		vim.tbl_map(function(hl) return refinement.highlight(background, hl) end, base.groups),
		refinement.repaired_groups(background, base.groups),
		chrome.groups(background),
	}

	return {
		colors = vim.tbl_extend(
			"error",
			{ background = background },
			chrome.scale[background],
			chrome.hues[background]
		),
		mode_hues = vim.tbl_map(function(hue) return chrome.hues[background][hue] end, chrome.mode_hues),
		dimmed = chrome.dimmed[background],
		transparent_clears = cleared_by_transparent(groups, chrome.scale[background].page),
		terminal = vim.tbl_map(function(color) return refinement.color(background, color) end, base.terminal),
		groups = groups,
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

local function fields(values)
	return vim.tbl_map(function(key) return key .. " = " .. literal(values[key]) end, sorted_keys(values))
end

local function inline(hl)
	if next(hl) == nil then return "{}" end

	return "{ " .. table.concat(fields(hl), ", ") .. " }"
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

local function append_part(lines, key, rows)
	table.insert(lines, "\t" .. key .. " = {")
	for _, row in ipairs(rows) do
		table.insert(lines, "\t\t" .. row .. ",")
	end
	table.insert(lines, "\t},")
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

	append_part(lines, "colors", fields(built.colors))
	table.insert(lines, string.format("\tdimmed = %s,", literal(built.dimmed)))
	append_part(lines, "mode_hues", fields(built.mode_hues))
	append_part(lines, "transparent_clears", vim.tbl_map(literal, built.transparent_clears))
	append_part(
		lines,
		"groups",
		vim.tbl_map(
			function(name) return string.format("[%q] = looks[%d]", name, look_of[inline(built.groups[name])]) end,
			names
		)
	)
	append_part(lines, "terminal", vim.tbl_map(literal, built.terminal))
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
