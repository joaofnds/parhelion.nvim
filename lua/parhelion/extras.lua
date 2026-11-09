local M = {}

local ansi_names = { "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white" }

local function palette(built)
  local normal, cursor, visual = built.groups.Normal, built.groups.Cursor, built.groups.Visual

  return {
    name = "Parhelion " .. built.colors.background:gsub("^%l", string.upper),
    page = normal.bg:lower(),
    text = normal.fg:lower(),
    cursor = cursor.bg:lower(),
    cursor_text = cursor.fg:lower(),
    selection = visual.bg:lower(),
    ansi = vim.tbl_map(string.lower, built.terminal),
  }
end

local function quoted(colors)
  return table.concat(vim.tbl_map(function(color) return '"' .. color .. '"' end, colors), ", ")
end

local function ghostty(p)
  local lines = {
    "background = " .. p.page,
    "foreground = " .. p.text,
    "cursor-color = " .. p.cursor,
    "cursor-text = " .. p.cursor_text,
    "selection-background = " .. p.selection,
    "selection-foreground = cell-foreground",
  }
  for index, color in ipairs(p.ansi) do
    table.insert(lines, string.format("palette = %d=%s", index - 1, color))
  end

  return lines
end

local function kitty(p)
  local lines = {
    "foreground " .. p.text,
    "background " .. p.page,
    "cursor " .. p.cursor,
    "cursor_text_color " .. p.cursor_text,
    "selection_foreground none",
    "selection_background " .. p.selection,
  }
  for index, color in ipairs(p.ansi) do
    table.insert(lines, string.format("color%d %s", index - 1, color))
  end

  return lines
end

local function wezterm(p)
  return {
    "[colors]",
    string.format('foreground = "%s"', p.text),
    string.format('background = "%s"', p.page),
    string.format('cursor_bg = "%s"', p.cursor),
    string.format('cursor_fg = "%s"', p.cursor_text),
    string.format('cursor_border = "%s"', p.cursor),
    'selection_fg = "none"',
    string.format('selection_bg = "%s"', p.selection),
    "ansi = [" .. quoted(vim.list_slice(p.ansi, 1, 8)) .. "]",
    "brights = [" .. quoted(vim.list_slice(p.ansi, 9, 16)) .. "]",
    "",
    "[metadata]",
    string.format('name = "%s"', p.name),
  }
end

local function alacritty(p)
  local lines = {
    "[colors.primary]",
    string.format('background = "%s"', p.page),
    string.format('foreground = "%s"', p.text),
    "",
    "[colors.cursor]",
    string.format('cursor = "%s"', p.cursor),
    string.format('text = "%s"', p.cursor_text),
    "",
    "[colors.selection]",
    string.format('background = "%s"', p.selection),
    'text = "CellForeground"',
  }
  for _, table_name in ipairs { "normal", "bright" } do
    table.insert(lines, "")
    table.insert(lines, "[colors." .. table_name .. "]")
    local first = table_name == "normal" and 0 or 8
    for index, name in ipairs(ansi_names) do
      table.insert(lines, string.format('%s = "%s"', name, p.ansi[first + index]))
    end
  end

  return lines
end

local function iterm2_color(lines, key, color)
  local red, green, blue = tonumber(color:sub(2, 3), 16), tonumber(color:sub(4, 5), 16), tonumber(color:sub(6, 7), 16)
  vim.list_extend(lines, {
    "\t<key>" .. key .. "</key>",
    "\t<dict>",
    "\t\t<key>Alpha Component</key>",
    "\t\t<real>1</real>",
    "\t\t<key>Blue Component</key>",
    string.format("\t\t<real>%.6f</real>", blue / 255),
    "\t\t<key>Color Space</key>",
    "\t\t<string>sRGB</string>",
    "\t\t<key>Green Component</key>",
    string.format("\t\t<real>%.6f</real>", green / 255),
    "\t\t<key>Red Component</key>",
    string.format("\t\t<real>%.6f</real>", red / 255),
    "\t</dict>",
  })
end

local function iterm2(p)
  local lines = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
    '<plist version="1.0">',
    "<dict>",
  }
  for index, color in ipairs(p.ansi) do
    iterm2_color(lines, string.format("Ansi %d Color", index - 1), color)
  end
  iterm2_color(lines, "Background Color", p.page)
  iterm2_color(lines, "Bold Color", p.text)
  iterm2_color(lines, "Cursor Color", p.cursor)
  iterm2_color(lines, "Cursor Text Color", p.cursor_text)
  iterm2_color(lines, "Foreground Color", p.text)
  iterm2_color(lines, "Selected Text Color", p.text)
  iterm2_color(lines, "Selection Color", p.selection)
  vim.list_extend(lines, { "</dict>", "</plist>" })

  return lines
end

function M.themes(built)
  local p = palette(built)
  local function text(lines) return table.concat(lines, "\n") .. "\n" end

  return {
    ["extras/ghostty/" .. p.name] = text(ghostty(p)),
    ["extras/kitty/" .. p.name .. ".conf"] = text(kitty(p)),
    ["extras/wezterm/" .. p.name .. ".toml"] = text(wezterm(p)),
    ["extras/alacritty/" .. p.name .. ".toml"] = text(alacritty(p)),
    ["extras/iterm2/" .. p.name .. ".itermcolors"] = text(iterm2(p)),
  }
end

return M
