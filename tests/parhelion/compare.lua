local M = {}

local function normalized(value)
	if type(value) == "table" and next(value) == nil then return "{}" end
	return vim.inspect(value)
end

-- Neovim matches group names case-insensitively, so one group can be listed under either spelling.
local function by_lowercase_name(groups)
	local indexed = {}
	for name, value in pairs(groups) do
		indexed[name:lower()] = value
	end
	return indexed
end

function M.group_differences(base, parhelion)
	local parhelion_groups = by_lowercase_name(parhelion.groups)
	local differences = {}
	for name, expected in pairs(base.groups) do
		local actual = parhelion_groups[name:lower()]
		if actual == nil or normalized(expected) ~= normalized(actual) then
			table.insert(differences, {
				name = name,
				base = expected,
				parhelion = actual == nil and "missing" or actual,
			})
		end
	end
	table.sort(differences, function(a, b) return a.name < b.name end)
	return differences
end

function M.outside(differences, restyled)
	local restyled_names = by_lowercase_name(restyled)

	return vim.tbl_filter(function(difference) return restyled_names[difference.name:lower()] == nil end, differences)
end

function M.terminal_differences(base, parhelion)
	local differences = {}
	for index, expected in pairs(base.terminal) do
		if parhelion.terminal[index] ~= expected then
			table.insert(differences, { index = index, base = expected, parhelion = parhelion.terminal[index] })
		end
	end
	return differences
end

function M.parhelion_only_groups(base, parhelion)
	local base_groups = by_lowercase_name(base.groups)
	local names = {}
	for name in pairs(parhelion.groups) do
		if base_groups[name:lower()] == nil then table.insert(names, name) end
	end
	table.sort(names)
	return names
end

local function colors_of(groups, names)
	local colors = {}
	for _, name in ipairs(names) do
		local group = groups[name]
		for _, attribute in ipairs { "fg", "bg", "sp" } do
			if type(group) == "table" and group[attribute] then
				table.insert(colors, { group = name, attribute = attribute, color = group[attribute] })
			end
		end
	end
	return colors
end

function M.colors_used_by(base_table)
	local used = vim.tbl_map(
		function(entry) return entry.color end,
		colors_of(base_table.groups, vim.tbl_keys(base_table.groups))
	)
	return vim.list_extend(used, base_table.terminal or {})
end

function M.foreign_colors(base, parhelion, base_table, scale)
	local known = {}
	for _, entry in ipairs(colors_of(base_table.groups, vim.tbl_keys(base_table.groups))) do
		known[entry.color:lower()] = true
	end
	for _, step in pairs(scale) do
		known[step] = true
	end

	local colored = vim.tbl_filter(
		function(name) return parhelion.links[name] == nil end,
		M.parhelion_only_groups(base, parhelion)
	)

	return vim.tbl_filter(
		function(entry) return entry.attribute ~= "bg" and not known[entry.color] end,
		colors_of(parhelion.groups, colored)
	)
end

function M.look_differences(parhelion, approved)
	local parhelion_groups = by_lowercase_name(parhelion.groups)
	local differences = {}
	for name, expected in pairs(approved) do
		local actual = vim.deepcopy(parhelion_groups[name:lower()] or {})
		actual.cterm = nil
		if not vim.deep_equal(expected, actual) then
			table.insert(differences, { name = name, approved = expected, parhelion = actual })
		end
	end
	return differences
end

function M.dangling_links(base, parhelion)
	local parhelion_groups = by_lowercase_name(parhelion.groups)
	local dangling = {}
	for _, name in ipairs(M.parhelion_only_groups(base, parhelion)) do
		local link = parhelion.links[name]
		if link and next(parhelion_groups[link:lower()] or {}) == nil then
			table.insert(dangling, name .. " -> " .. link)
		end
	end
	return dangling
end

function M.role_difference(role, base, parhelion)
	local parhelion_group = by_lowercase_name(parhelion.groups)[role.group:lower()]
	local actual = parhelion_group and parhelion_group[role.attribute] or "missing"
	local expected = base.groups[role.equivalent][role.attribute]
	if actual == expected then return {} end

	return {
		{
			group = role.group,
			attribute = role.attribute,
			equivalent = role.equivalent,
			expected = expected,
			actual = actual,
		},
	}
end

local cell_fields = { "text", "fg", "bg", "sp", "flags" }

local function row_text(row)
	local parts = {}
	for _, cell in ipairs(row) do
		table.insert(parts, cell.text)
	end
	return table.concat(parts)
end

local function cell_key(cell)
	local parts = {}
	for _, field in ipairs(cell_fields) do
		table.insert(parts, tostring(cell[field]))
	end
	return table.concat(parts, "|")
end

local function hint_window_width(row)
	for col, cell in ipairs(row) do
		if cell.text == "│" then return col - 1 end
	end
	return #row
end

local function with_hint_sorted(row)
	local width = hint_window_width(row)
	local hint = vim.deepcopy(vim.list_slice(row, 1, width))
	table.sort(hint, function(a, b) return cell_key(a) < cell_key(b) end)

	return vim.list_extend(hint, row, width + 1)
end

-- Neogit builds its hint line from pairs(), so the same hints arrive in a different order each run.
local function is_neogit_hint(row) return row_text(row):find "^%s*Hint: " ~= nil end

function M.cell_differences(base, parhelion)
	local differences = {}
	for r, row in ipairs(base.rows) do
		local expected_row, actual_row = row, parhelion.rows[r]
		if is_neogit_hint(expected_row) and is_neogit_hint(actual_row) then
			expected_row, actual_row = with_hint_sorted(expected_row), with_hint_sorted(actual_row)
		end

		for c, expected in ipairs(expected_row) do
			local actual = actual_row[c]
			for _, field in ipairs(cell_fields) do
				if expected[field] ~= actual[field] then
					table.insert(differences, {
						row = r,
						col = c,
						field = field,
						base = expected[field],
						parhelion = actual[field],
					})
					break
				end
			end
		end
	end
	return differences
end

return M
