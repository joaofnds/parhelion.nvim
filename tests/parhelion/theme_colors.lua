local chrome = require "parhelion.chrome"
local color = require "color"
local refinement = require "parhelion.refinement"

local M = {}

M.largest_distance = 4

local mix_steps = 20

local groups_out_of_the_theme_reach = {
  "^BufferDefault%a+Target$",
  "^Diagnostic%u+Reverse$",
  "DevIcon",
  "^RedrawDebug",
  "^SagaActionTitle$",
  "Backdrop",
  "^FloatShadow",
  "^PmenuShadow",
}

---@class theme_colors.Drawn
---@field attribute string
---@field color string
---@field cell string

---@class theme_colors.Held
---@field group string
---@field attribute string
---@field color string

---@return string[]
local function theme_colors()
  ---@type table<string, true>
  local colors = {}
  for background, scale in pairs(chrome.scale) do
    ---@type parhelion.Base
    local base = require("parhelion.base." .. background)
    local indent_guide = assert(base.groups.IblIndent.fg)
    for _, neutral in ipairs { scale.page, scale.float, scale.raised, indent_guide:lower() } do
      colors[neutral] = true
    end
  end
  for _, tones in pairs(refinement.tones) do
    for from, to in pairs(tones) do
      colors[from], colors[to] = true, true
    end
  end

  return vim.tbl_keys(colors)
end

---@type number[][]?
local colors_inside

---@return number[][]
local function every_color_inside_the_theme()
  if colors_inside then return colors_inside end

  colors_inside = {}
  local colors = theme_colors()
  for first = 1, #colors do
    for second = first, #colors do
      for step = 0, mix_steps do
        table.insert(colors_inside, color.lab(color.mix(colors[first], colors[second], step / mix_steps)))
      end
    end
  end

  return colors_inside
end

---@type table<string, number>
local distances = {}

---@param hex string
---@return number
function M.distance_from_the_theme(hex)
  if distances[hex] then return distances[hex] end

  local lab = color.lab(hex)
  local nearest = math.huge
  for _, inside in ipairs(every_color_inside_the_theme()) do
    nearest = math.min(nearest, (lab[1] - inside[1]) ^ 2 + (lab[2] - inside[2]) ^ 2 + (lab[3] - inside[3]) ^ 2)
  end

  distances[hex] = math.sqrt(nearest)
  return distances[hex]
end

---@param hex string
---@return boolean
local function is_outside(hex) return M.distance_from_the_theme(hex:lower()) > M.largest_distance end

---@param shot { rows: { text: string, fg: string, bg: string }[][] }
---@param is_icon fun(text: string): boolean
---@return theme_colors.Drawn[]
function M.drawn_outside(shot, is_icon)
  ---@type theme_colors.Drawn[], table<string, true>
  local found, seen = {}, {}

  ---@param attribute string
  ---@param hex string
  ---@param text string
  local function check(attribute, hex, text)
    local key = attribute .. hex
    if not seen[key] and is_outside(hex) then
      seen[key] = true
      table.insert(found, { attribute = attribute, color = hex, cell = text })
    end
  end

  for _, row in ipairs(shot.rows) do
    for _, cell in ipairs(row) do
      check("bg", cell.bg, cell.text)
      if not cell.text:match "^%s*$" and not is_icon(cell.text) then check("fg", cell.fg, cell.text) end
    end
  end

  return found
end

---@param name string
---@return boolean
local function is_out_of_reach(name)
  for _, pattern in ipairs(groups_out_of_the_theme_reach) do
    if name:find(pattern) then return true end
  end

  return false
end

---@param colors_by_group driver.GroupColors
---@return theme_colors.Held[]
function M.groups_outside(colors_by_group)
  ---@type theme_colors.Held[]
  local found = {}
  for name, colors in pairs(colors_by_group) do
    if not is_out_of_reach(name) then
      for attribute, hex in pairs(colors) do
        if is_outside(hex) then table.insert(found, { group = name, attribute = attribute, color = hex }) end
      end
    end
  end

  return found
end

return M
