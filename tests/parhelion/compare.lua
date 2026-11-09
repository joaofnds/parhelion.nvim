local M = {}

---@class compare.Named
---@field name string

---@class compare.GroupDifference: compare.Named
---@field base snapshot.Group
---@field parhelion snapshot.Group|"missing"

---@class compare.TerminalDifference
---@field index string
---@field base string|vim.NIL
---@field parhelion? string|vim.NIL

---@class compare.Color
---@field group string
---@field attribute "fg"|"bg"|"sp"
---@field color string

---@class compare.LookDifference
---@field name string
---@field approved parhelion.Highlight
---@field parhelion snapshot.Group

---@class compare.Role
---@field group string
---@field attribute "fg"|"bg"|"sp"
---@field equivalent string

---@class compare.RoleDifference
---@field group string
---@field attribute "fg"|"bg"|"sp"
---@field equivalent string
---@field expected? string
---@field actual string

---@class compare.CellDifference
---@field row integer
---@field col integer
---@field field string
---@field base? string
---@field parhelion? string

---@class compare.Table
---@field groups table<string, parhelion.Highlight>
---@field terminal? string[]

---@param value snapshot.Group
---@return string
local function normalized(value)
  if type(value) == "table" and next(value) == nil then return "{}" end
  return vim.inspect(value)
end

-- Neovim matches group names case-insensitively, so one group can be listed under either spelling.
---@param groups table<string, parhelion.Highlight>
---@return table<string, parhelion.Highlight>
local function by_lowercase_name(groups)
  ---@type table<string, parhelion.Highlight>
  local indexed = {}
  for name, value in pairs(groups) do
    indexed[name:lower()] = value
  end
  return indexed
end

---@param base snapshot.Snapshot
---@param parhelion snapshot.Snapshot
---@return compare.GroupDifference[]
function M.group_differences(base, parhelion)
  local parhelion_groups = by_lowercase_name(parhelion.groups)
  ---@type compare.GroupDifference[]
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
  table.sort(
    differences,
    ---@param a compare.GroupDifference
    ---@param b compare.GroupDifference
    ---@return boolean
    function(a, b) return a.name < b.name end
  )
  return differences
end

---@generic D: compare.Named
---@param differences D[]
---@param restyled table<string, parhelion.Highlight>
---@return D[]
function M.outside(differences, restyled)
  local restyled_names = by_lowercase_name(restyled)

  return vim.tbl_filter(
    ---@param difference compare.Named
    ---@return boolean
    function(difference) return restyled_names[difference.name:lower()] == nil end,
    differences
  )
end

---@param base snapshot.Snapshot
---@param parhelion snapshot.Snapshot
---@return compare.TerminalDifference[]
function M.terminal_differences(base, parhelion)
  ---@type compare.TerminalDifference[]
  local differences = {}
  for index, expected in pairs(base.terminal) do
    if parhelion.terminal[index] ~= expected then
      table.insert(differences, { index = index, base = expected, parhelion = parhelion.terminal[index] })
    end
  end
  return differences
end

---@param base snapshot.Snapshot
---@param parhelion snapshot.Snapshot
---@return string[]
function M.parhelion_only_groups(base, parhelion)
  local base_groups = by_lowercase_name(base.groups)
  local names = {}
  for name in pairs(parhelion.groups) do
    if base_groups[name:lower()] == nil then table.insert(names, name) end
  end
  table.sort(names)
  return names
end

---@type ("fg"|"bg"|"sp")[]
local color_attributes = { "fg", "bg", "sp" }

---@param groups table<string, parhelion.Highlight>
---@param names string[]
---@return compare.Color[]
local function colors_of(groups, names)
  ---@type compare.Color[]
  local colors = {}
  for _, name in ipairs(names) do
    local group = groups[name]
    for _, attribute in ipairs(color_attributes) do
      if type(group) == "table" and group[attribute] then
        ---@type compare.Color
        local entry = { group = name, attribute = attribute, color = group[attribute] }
        table.insert(colors, entry)
      end
    end
  end
  return colors
end

---@param base_table parhelion.Base
---@return string[]
function M.colors_used_by(base_table)
  local used = vim.tbl_map(
    ---@param entry compare.Color
    ---@return string
    function(entry) return entry.color end,
    colors_of(base_table.groups, vim.tbl_keys(base_table.groups))
  )
  return vim.list_extend(used, base_table.terminal or {})
end

---@param base snapshot.Snapshot
---@param parhelion snapshot.Snapshot
---@param base_table compare.Table
---@param scale string[]
---@return compare.Color[]
function M.foreign_colors(base, parhelion, base_table, scale)
  ---@type table<string, true>
  local known = {}
  for _, entry in ipairs(colors_of(base_table.groups, vim.tbl_keys(base_table.groups))) do
    known[entry.color:lower()] = true
  end
  for _, step in pairs(scale) do
    known[step] = true
  end

  local colored = vim.tbl_filter(
    ---@param name string
    ---@return boolean
    function(name) return parhelion.links[name] == nil end,
    M.parhelion_only_groups(base, parhelion)
  )

  return vim.tbl_filter(
    ---@param entry compare.Color
    ---@return boolean
    function(entry) return entry.attribute ~= "bg" and not known[entry.color] end,
    colors_of(parhelion.groups, colored)
  )
end

---@param parhelion snapshot.Snapshot
---@param approved table<string, parhelion.Highlight>
---@return compare.LookDifference[]
function M.look_differences(parhelion, approved)
  local parhelion_groups = by_lowercase_name(parhelion.groups)
  ---@type compare.LookDifference[]
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

---@param base snapshot.Snapshot
---@param parhelion snapshot.Snapshot
---@return string[]
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

---@param role compare.Role
---@param base snapshot.Snapshot
---@param parhelion snapshot.Snapshot
---@return compare.RoleDifference[]
function M.role_difference(role, base, parhelion)
  local parhelion_group = by_lowercase_name(parhelion.groups)[role.group:lower()]
  local actual = parhelion_group and parhelion_group[role.attribute] or "missing"
  ---@type string?
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

---@type ("text"|"fg"|"bg"|"sp"|"flags")[]
local cell_fields = { "text", "fg", "bg", "sp", "flags" }

---@param row driver.Cell[]
---@return string
local function row_text(row)
  local parts = {}
  for _, cell in ipairs(row) do
    table.insert(parts, cell.text)
  end
  return table.concat(parts)
end

---@param cell driver.Cell
---@return string
local function cell_key(cell)
  local parts = {}
  for _, field in ipairs(cell_fields) do
    table.insert(parts, tostring(cell[field]))
  end
  return table.concat(parts, "|")
end

---@param row driver.Cell[]
---@return integer
local function hint_window_width(row)
  for col, cell in ipairs(row) do
    if cell.text == "│" then return col - 1 end
  end
  return #row
end

---@param row driver.Cell[]
---@return driver.Cell[]
local function with_hint_sorted(row)
  local width = hint_window_width(row)
  local hint = vim.deepcopy(vim.list_slice(row, 1, width))
  table.sort(
    hint,
    ---@param a driver.Cell
    ---@param b driver.Cell
    ---@return boolean
    function(a, b) return cell_key(a) < cell_key(b) end
  )

  return vim.list_extend(hint, row, width + 1)
end

-- Neogit builds its hint line from pairs(), so the same hints arrive in a different order each run.
---@param row driver.Cell[]
---@return boolean
local function is_neogit_hint(row) return row_text(row):find "^%s*Hint: " ~= nil end

---@param base driver.Shot
---@param parhelion driver.Shot
---@return compare.CellDifference[]
function M.cell_differences(base, parhelion)
  ---@type compare.CellDifference[]
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
          ---@type compare.CellDifference
          local difference = {
            row = r,
            col = c,
            field = field,
            base = expected[field],
            parhelion = actual[field],
          }
          table.insert(differences, difference)
          break
        end
      end
    end
  end
  return differences
end

return M
