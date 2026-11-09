local built = require("parhelion").built(vim.o.background)
local colors, hues, cursor = built.colors, built.mode_hues, built.groups.Cursor

local function cursor_in(hue) return { hl = { ReactiveCursor = { fg = colors.page, bg = hue } } } end

return {
  name = "parhelion-cursor",
  init = function() vim.opt.guicursor:append "a:ReactiveCursor" end,
  static = { hl = { ReactiveCursor = { fg = cursor.fg, bg = cursor.bg } } },
  modes = {
    [{ "v", "V", "\22", "s", "S", "\19" }] = cursor_in(hues.visual),
    i = cursor_in(hues.insert),
    R = cursor_in(hues.replace),
    c = cursor_in(hues.command),
  },
}
