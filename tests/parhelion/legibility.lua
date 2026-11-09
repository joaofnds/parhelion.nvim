local color = require "color"

local M = {}

M.text_floor = 30
M.floor_over_a_selection = 20
M.smallest_body_contrast_on_a_wash = 4.5
M.smallest_wash_difference_from_the_cursor_line = 5
M.smallest_word_difference_from_its_line = 10
M.smallest_difference_between_overlays = 10
M.smallest_word_contrast = 4.5
M.smallest_description_contrast = 4.5
M.largest_drift = 10.5
M.largest_hue_shift = 1
M.largest_orange_hue_shift = 5.4
M.smallest_chroma_with_visible_hue = 0.05
M.smallest_accent_difference = 13
M.smallest_step_below_body = 10
M.smallest_neutral_step = 3
M.smallest_staged_sign_contrast = 2
M.smallest_staged_sign_difference = 6
M.smallest_control_contrast = 3

M.diff_wash_hues = {
  added_wash = { name = "green", from = 145, to = 170 },
  added_word_wash = { name = "green", from = 145, to = 170 },
  removed_wash = { name = "red", from = -10, to = 30 },
  removed_word_wash = { name = "red", from = -10, to = 30 },
}

M.page_colors = { "#002b36", "#073642", "#002731", "#fdf6e3", "#eee8d5", "#fbf3db" }

M.accents = {
  yellow = "#b58900",
  orange = "#cb4b16",
  red = "#dc322f",
  magenta = "#d33682",
  violet = "#6c71c4",
  blue = "#268bd2",
  cyan = "#2aa198",
  green = "#859900",
}

local code = {
  "Added",
  "Changed",
  "Constant",
  "DiagnosticError",
  "DiagnosticHint",
  "DiagnosticInfo",
  "DiagnosticOk",
  "DiagnosticWarn",
  "Function",
  "Identifier",
  "Keyword",
  "Removed",
  "Special",
  "Statement",
  "String",
  "Title",
  "Type",
}
local quiet = { "Comment", "LineNr", "LspInlayHint" }

M.tiers = {
  dark = {
    { name = "body", groups = { "Normal" }, ratio = 5.5, lightness = 46 },
    { name = "code", groups = code, ratio = 4.5, lightness = 38 },
    { name = "quiet", groups = quiet, ratio = 3, lightness = 30 },
  },
  light = {
    { name = "body", groups = { "Normal" }, ratio = 4.9, lightness = 71 },
    { name = "code", groups = code, ratio = 4, lightness = 64 },
    { name = "quiet", groups = quiet, ratio = 3, lightness = 55 },
  },
}

local separators = { "▎", "│", "\u{E0B0}", "\u{E0B2}", "\u{E0BA}", "\u{E0BC}", "\u{E0BE}" }

function M.is_separator(text) return vim.list_contains(separators, text) end

function M.is_icon(text)
  local codepoint = vim.fn.char2nr(text)
  return (codepoint >= 0xE000 and codepoint <= 0xF8FF) or codepoint >= 0xF0000
end

function M.draws_its_own_color(text) return M.is_icon(text) and not M.is_separator(text) end

function M.is_line_art_or_icon(text)
  local codepoint = vim.fn.char2nr(text)
  return (codepoint >= 0x2500 and codepoint <= 0x259F) or M.is_icon(text)
end

---@class legibility.Illegible
---@field text string
---@field background string
---@field lightness number
---@field cell string

---@class legibility.UnderFloor
---@field group string
---@field text string
---@field background string
---@field lightness number

---@class legibility.Tier
---@field name string
---@field groups string[]
---@field ratio number
---@field lightness number

---@class legibility.BelowTier: legibility.UnderFloor
---@field ratio number

---@param cell driver.Cell
---@return string text
---@return string background
local function text_and_background(cell)
  if cell.flags:find("reverse", 1, true) then return cell.bg, cell.fg end
  return cell.fg, cell.bg
end

---@param item driver.DrawnWith
---@param fill string
---@param groups driver.GroupColors
---@return boolean
local function is_remapped_onto(item, fill, groups)
  local name = item.name
  local group = name and groups[name]

  return item.kind == "ui" and group ~= nil and group.bg ~= fill
end

---@param cell driver.Cell
---@param background string
---@param groups? driver.GroupColors
---@return boolean
local function is_over_the_selection(cell, background, groups)
  local selection = groups and groups.Visual and groups.Visual.bg
  ---@type driver.DrawnWith[]
  local drawing_the_fill = vim
    .iter(cell.drawn_with)
    :filter(
      ---@param item driver.DrawnWith
      ---@return boolean
      function(item) return item.bg == background end
    )
    :totable()
  if not groups or background ~= selection or #drawing_the_fill == 0 then return false end

  return vim.iter(drawing_the_fill):all(
    ---@param item driver.DrawnWith
    ---@return boolean
    function(item) return item.name == "Visual" or is_remapped_onto(item, background, groups) end
  )
end

---@param shot { rows: driver.Cell[][], groups?: driver.GroupColors }
---@param is_exempt fun(text: string): boolean
---@return legibility.Illegible[]
function M.illegible_text(shot, is_exempt)
  ---@type legibility.Illegible[], table<string, true>
  local found, seen = {}, {}
  for _, row in ipairs(shot.rows) do
    for _, cell in ipairs(row) do
      if not cell.text:match "^%s*$" and not is_exempt(cell.text) then
        local text, background = text_and_background(cell)
        local key = text .. background
        local lightness = math.abs(color.lightness_contrast(text, background))
        local over_the_selection = is_over_the_selection(cell, background, shot.groups)
        local floor = over_the_selection and M.floor_over_a_selection or M.text_floor
        if not seen[key] and lightness < floor then
          seen[key] = true
          table.insert(found, {
            text = text,
            background = background,
            lightness = lightness,
            cell = cell.text,
          })
        end
      end
    end
  end

  return found
end

M.decorations = {
  "@markup.heading.1.delimiter.vimdoc",
  "@markup.heading.2.delimiter.vimdoc",
  "EndOfBuffer",
  "NeoTreeStatusLineNC",
  "NvimTreeEndOfBuffer",
  "NvimTreeStatuslineNc",
  "OctoBubbleDelimiterGrey",
  "OctoGrey",
}

local words_for_line_art = {
  "Border",
  "Bullet",
  "Dash$",
  "Gradient%d",
  "Guide",
  "Indent",
  "Marker",
  "ProgressTodo",
  "Scrollbar",
  "Sep$",
  "Separator",
  "Sign$",
  "TableAlign",
  "TableHead",
  "TableRow",
  "VertSplit",
  "Whitespace",
  "VirtLine",
}

---@param name string
---@return boolean
local function is_line_art(name)
  for _, word in ipairs(words_for_line_art) do
    if name:find(word) then return true end
  end

  return false
end

---@param snapshot snapshot.Snapshot
---@return legibility.UnderFloor[]
function M.groups_under_text_floor(snapshot)
  ---@type legibility.UnderFloor[]
  local found = {}
  for name, group in pairs(snapshot.groups) do
    local is_text = not is_line_art(name) and not vim.list_contains(M.decorations, name)
    local fg = group.fg
    if fg and not snapshot.links[name] and is_text then
      local bg = assert(group.bg or snapshot.groups.Normal.bg)
      local text, background = fg, bg
      if group.reverse then
        text, background = bg, fg
      end

      local lightness = math.abs(color.lightness_contrast(text, background))
      if lightness < M.text_floor then
        table.insert(found, { group = name, text = text, background = background, lightness = lightness })
      end
    end
  end

  return found
end

---@param snapshot snapshot.Snapshot
---@param name string
---@return string text
---@return string background
function M.pair(snapshot, name)
  local group = snapshot.groups[name]
  return assert(group.fg), assert(group.bg or snapshot.groups.Normal.bg)
end

---@param snapshot snapshot.Snapshot
---@param tier legibility.Tier
---@return legibility.BelowTier[]
function M.below_tier(snapshot, tier)
  ---@type legibility.BelowTier[]
  local found = {}
  for _, name in ipairs(tier.groups) do
    local text, background = M.pair(snapshot, name)
    local ratio = color.contrast_ratio(text, background)
    local lightness = math.abs(color.lightness_contrast(text, background))
    if ratio < tier.ratio or lightness < tier.lightness then
      table.insert(found, { group = name, text = text, background = background, ratio = ratio, lightness = lightness })
    end
  end

  return found
end

return M
