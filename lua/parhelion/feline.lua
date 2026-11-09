local parhelion = require "parhelion"

local function built() return parhelion.built(vim.o.background) end

local modes = {
  n = { name = "NORMAL", colored_as = "normal" },
  no = { name = "OPERATOR", colored_as = "normal" },
  v = { name = "VISUAL", colored_as = "visual" },
  V = { name = "VISUAL LINE", colored_as = "visual" },
  ["\22"] = { name = "VISUAL BLOCK", colored_as = "visual" },
  s = { name = "SELECT", colored_as = "visual" },
  S = { name = "SELECT LINE", colored_as = "visual" },
  ["\19"] = { name = "SELECT BLOCK", colored_as = "visual" },
  i = { name = "INSERT", colored_as = "insert" },
  t = { name = "TERMINAL", colored_as = "insert" },
  R = { name = "REPLACE", colored_as = "replace" },
  Rv = { name = "VREPLACE", colored_as = "replace" },
  c = { name = "COMMAND", colored_as = "command" },
  r = { name = "PROMPT", colored_as = "command" },
  ["!"] = { name = "SHELL", colored_as = "command" },
}

local function current_mode()
  local mode = vim.api.nvim_get_mode().mode

  return modes[mode:sub(1, 2)] or modes[mode:sub(1, 1)]
end

local function bar()
  local current = built()
  return { fg = current.groups.StatusLine.fg, bg = current.colors.raised }
end

local function block()
  local current = built()
  return { fg = current.colors.raised, bg = current.groups.StatusLine.fg }
end

local function inactive_bar()
  local inactive = built().groups.StatusLineNC
  return { fg = inactive.fg, bg = inactive.bg }
end

local function space(hl) return { str = " ", hl = hl } end

local function file_info(path_form)
  return { name = "file_info", opts = { type = path_form, file_modified_icon = "[+]", file_readonly_icon = "[RO] " } }
end

local function branch() return (string.gsub(vim.b.gitsigns_head or "", "%%", "%%%%")) end

local function file_name(hl)
  return {
    provider = file_info "relative",
    short_provider = file_info "base-only",
    icon = "",
    hl = hl,
    left_sep = space(hl),
    right_sep = space(hl),
  }
end

local function in_a_block(provider)
  return { provider = provider, icon = "", hl = block, left_sep = space(block), right_sep = space(block) }
end

local function diagnostic_count(provider, group, letter)
  local function hl()
    local current = built()
    return { fg = current.groups[group].fg, bg = current.colors.raised }
  end

  return { provider = provider, icon = letter .. ":", hl = hl, right_sep = space(hl) }
end

local function hidden_when_narrow(hiding_order, component)
  return vim.tbl_extend("error", component, { truncate_hide = true, priority = hiding_order })
end

local function mode_name() return " " .. current_mode().name .. " " end

local function mode_block()
  local current = built()
  return {
    fg = current.colors.page,
    bg = current.mode_hues[current_mode().colored_as],
    style = parhelion.draws_bold() and "bold" or nil,
  }
end

local function redraw_when_an_operator_starts_or_ends()
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = vim.api.nvim_create_augroup("parhelion.feline", {}),
    pattern = { "*:no*", "no*:*" },
    command = "redrawstatus",
  })
end

local M = {}

function M.get_statusline()
  redraw_when_an_operator_starts_or_ends()

  return {
    active = {
      {
        { provider = mode_name, hl = mode_block },
        hidden_when_narrow(1, in_a_block(branch)),
        file_name(bar),
      },
      {
        hidden_when_narrow(6, diagnostic_count("diagnostic_errors", "DiagnosticError", "E")),
        hidden_when_narrow(5, diagnostic_count("diagnostic_warnings", "DiagnosticWarn", "W")),
        hidden_when_narrow(4, diagnostic_count("diagnostic_info", "DiagnosticInfo", "I")),
        hidden_when_narrow(3, diagnostic_count("diagnostic_hints", "DiagnosticHint", "H")),
        hidden_when_narrow(2, in_a_block "position"),
      },
    },
    inactive = { { file_name(inactive_bar) } },
  }
end

return M
