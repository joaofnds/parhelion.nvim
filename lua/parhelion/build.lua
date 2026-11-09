local chrome = require "parhelion.chrome"
local refinement = require "parhelion.refinement"

local M = {}

-- Neovim's group names ignore case, so a later layer replaces an earlier group whatever case either spells it in.
---@param layers table<string, parhelion.Highlight>[]
---@return table<string, parhelion.Highlight>
local function layered(layers)
  ---@type table<string, parhelion.Highlight>, table<string, string>
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

---@param name string
---@return boolean
local function is_a_sign(name) return name:find "Signs?%u" ~= nil or name:find "Sign$" ~= nil end

---@param groups table<string, parhelion.Highlight>
---@param page string
---@return string[]
local function cleared_by_transparent(groups, page)
  ---@type string, string[]
  local gutter_fill, names = assert(groups.LineNr.bg):lower(), {}
  for name, hl in pairs(groups) do
    local fill = hl.bg and hl.bg:lower()
    if fill and (fill == page or gutter[name] or (fill == gutter_fill and is_a_sign(name))) then
      table.insert(names, name)
    end
  end
  table.sort(names)

  return names
end

---@param background parhelion.Background
---@return parhelion.Built
function M.build(background)
  ---@type parhelion.Base
  local base = require("parhelion.base." .. background)
  local groups = layered {
    vim.tbl_map(
      ---@param hl parhelion.Highlight
      ---@return parhelion.Highlight
      function(hl) return refinement.highlight(background, hl) end,
      base.groups
    ),
    refinement.repaired_groups(background, base.groups),
    chrome.groups(background),
  }

  return {
    colors = vim.tbl_extend("error", { background = background }, chrome.scale[background], chrome.hues[background]),
    mode_hues = vim.tbl_map(
      ---@param hue parhelion.Accent
      ---@return string
      function(hue) return chrome.hues[background][hue] end,
      chrome.mode_hues
    ),
    dimmed = chrome.dimmed[background],
    transparent_clears = cleared_by_transparent(groups, chrome.scale[background].page),
    terminal = vim.tbl_map(
      ---@param color string
      ---@return string
      function(color) return refinement.color(background, color) end,
      base.terminal
    ),
    groups = groups,
  }
end

M.command = "make build"

---@generic V
---@param values table<string, V>
---@return string[]
local function sorted_keys(values)
  local keys = vim.tbl_keys(values)
  table.sort(keys)

  return keys
end

---@param value string|number|boolean
---@return string
local function literal(value)
  if type(value) == "string" then return string.format("%q", value) end

  return tostring(value)
end

---@param values table<string, string|number|boolean>
---@return string[]
local function fields(values)
  return vim.tbl_map(
    ---@param key string
    ---@return string
    function(key) return key .. " = " .. literal(values[key]) end,
    sorted_keys(values)
  )
end

---@param hl parhelion.Highlight
---@return string
local function inline(hl)
  if next(hl) == nil then return "{}" end

  return "{ " .. table.concat(fields(hl), ", ") .. " }"
end

---@param groups table<string, parhelion.Highlight>
---@param names string[]
---@return string[] looks
---@return table<string, integer> look_of
local function shared_looks(groups, names)
  ---@type string[], table<string, integer>
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

---@param lines string[]
---@param key string
---@param rows string[]
local function append_part(lines, key, rows)
  table.insert(lines, "  " .. key .. " = {")
  for _, row in ipairs(rows) do
    table.insert(lines, "    " .. row .. ",")
  end
  table.insert(lines, "  },")
end

---@param built parhelion.Built
---@return string[]
local function source(built)
  local names = sorted_keys(built.groups)
  local looks, look_of = shared_looks(built.groups, names)

  local lines = {
    "-- Written by " .. M.command,
    "-- from the base tables, refinement.lua and chrome.lua. Edit those, not this file.",
    "local looks = {",
  }
  for _, look in ipairs(looks) do
    table.insert(lines, "  " .. look .. ",")
  end
  table.insert(lines, "}")
  table.insert(lines, "")
  table.insert(lines, "---@type parhelion.Built")
  table.insert(lines, "return {")

  append_part(lines, "colors", fields(built.colors))
  table.insert(lines, string.format("  dimmed = %s,", literal(built.dimmed)))
  append_part(lines, "mode_hues", fields(built.mode_hues))
  append_part(lines, "transparent_clears", vim.tbl_map(literal, built.transparent_clears))
  append_part(
    lines,
    "groups",
    vim.tbl_map(
      ---@param name string
      ---@return string
      function(name) return string.format("[%q] = looks[%d]", name, look_of[inline(built.groups[name])]) end,
      names
    )
  )
  append_part(lines, "terminal", vim.tbl_map(literal, built.terminal))
  table.insert(lines, "}")

  return lines
end

---@param root string
---@param themes table<string, string>
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
