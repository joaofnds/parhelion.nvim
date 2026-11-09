-- Draws the screen a Neovim under the suite's UI driver shows as an HTML page, in the font it is given, for a browser
-- to turn into an image.
---@class shoot.Cursor
---@field fg? string
---@field bg? string

---@param a driver.Cell
---@param b driver.Cell
---@return boolean
local function same_style(a, b) return a.fg == b.fg and a.bg == b.bg and a.sp == b.sp and a.flags == b.flags end

local underlines = {
  { "undercurl", "wavy" },
  { "underdouble", "double" },
  { "underdotted", "dotted" },
  { "underdashed", "dashed" },
  { "underline", "solid" },
}

local function underline_of(flags)
  for _, underline in ipairs(underlines) do
    if flags[underline[1]] then return underline[2] end
  end
end

---@param cell driver.Cell
---@param cursor? shoot.Cursor
---@return string
local function style_of(cell, cursor)
  ---@type table<string, true>
  local flags = {}
  for flag in cell.flags:gmatch "[^,]+" do
    flags[flag] = true
  end
  local text, fill = cell.fg, cell.bg
  if flags.reverse then
    text, fill = cell.bg, cell.fg
  end
  local fg, bg = text, fill
  if cursor then
    fg, bg = cursor.fg or fill, cursor.bg or text
  end

  local style = { "color:" .. fg, "background:" .. bg }
  if flags.bold then table.insert(style, "font-weight:700") end
  if flags.italic then table.insert(style, "font-style:italic") end
  local underline = underline_of(flags)
  if underline then
    table.insert(style, "text-decoration:underline " .. underline .. " " .. (cell.sp or fg))
    table.insert(style, "text-underline-offset:3px")
  end

  return table.concat(style, ";")
end

---@param text string
---@return string
local function escape(text) return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end

---@param cells driver.Cell[]
---@param cursor_col? integer
---@param cursor shoot.Cursor
---@return string
local function row_html(cells, cursor_col, cursor)
  ---@type string[], integer
  local parts, first = {}, 1
  while first <= #cells do
    ---@type integer
    local last = first
    while
      last < #cells
      and first ~= cursor_col
      and last + 1 ~= cursor_col
      and same_style(cells[last + 1], cells[first])
    do
      last = last + 1
    end

    local texts = {}
    for index = first, last do
      table.insert(texts, cells[index].text)
    end
    local text = escape(table.concat(texts))
    if cells[first].flags:find "strikethrough" then text = "<s>" .. text .. "</s>" end
    table.insert(
      parts,
      string.format(
        '<span style="width:%dch;%s">%s</span>',
        last - first + 1,
        style_of(cells[first], first == cursor_col and cursor or nil),
        text
      )
    )
    first = last + 1
  end

  return '<div class="r">' .. table.concat(parts) .. "</div>"
end

---@param nvim driver.Nvim
---@param font string
---@return string
return function(nvim, font)
  local shot = nvim:capture()
  ---@type shoot.Cursor
  local cursor = nvim:lua [[
    local hl = vim.api.nvim_get_hl(0, { name = "Cursor", link = false })
    local function hex(n) return n and string.format("#%06x", n) or nil end
    return { fg = hex(hl.fg), bg = hex(hl.bg) }
  ]]
  local rows = {}
  for index, cells in ipairs(shot.rows) do
    local cursor_col = index == shot.cursor.row and shot.cursor.col or nil
    table.insert(rows, row_html(cells, cursor_col, cursor))
  end

  return table.concat {
    '<!doctype html><meta charset="utf-8"><style>',
    "html,body{margin:0;background:" .. shot.defaults.bg .. "}",
    "#screen{display:inline-block;padding:24px 28px;background:" .. shot.defaults.bg .. "}",
    '.g{font-family:"' .. font .. '";font-size:15px;white-space:pre;font-variant-ligatures:none}',
    ".r{display:block;height:21px;line-height:21px}",
    ".r span{display:inline-block;height:21px;vertical-align:top;overflow:visible}",
    '</style><div id="screen"><div class="g">',
    table.concat(rows),
    "</div></div>",
  }
end
