local parhelion = require "parhelion"

local built = parhelion.built(vim.o.background)
local colors, groups, hues = built.colors, built.groups, built.mode_hues

local modes = {
	n = { name = "NORMAL", hue = hues.normal },
	no = { name = "OPERATOR", hue = hues.normal },
	v = { name = "VISUAL", hue = hues.visual },
	V = { name = "VISUAL LINE", hue = hues.visual },
	["\22"] = { name = "VISUAL BLOCK", hue = hues.visual },
	s = { name = "SELECT", hue = hues.visual },
	S = { name = "SELECT LINE", hue = hues.visual },
	["\19"] = { name = "SELECT BLOCK", hue = hues.visual },
	i = { name = "INSERT", hue = hues.insert },
	t = { name = "TERMINAL", hue = hues.insert },
	R = { name = "REPLACE", hue = hues.replace },
	Rv = { name = "VREPLACE", hue = hues.replace },
	c = { name = "COMMAND", hue = hues.command },
	r = { name = "PROMPT", hue = hues.command },
	["!"] = { name = "SHELL", hue = hues.command },
}

local function current_mode()
	local mode = vim.api.nvim_get_mode().mode

	return modes[mode:sub(1, 2)] or modes[mode:sub(1, 1)]
end

local bar = { fg = groups.StatusLine.fg, bg = colors.raised }
local block = { fg = colors.raised, bg = groups.StatusLine.fg }
local inactive_bar = { fg = groups.StatusLineNC.fg, bg = groups.StatusLineNC.bg }

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
	local hl = { fg = groups[group].fg, bg = colors.raised }

	return { provider = provider, icon = letter .. ":", hl = hl, right_sep = space(hl) }
end

local function hidden_when_narrow(hiding_order, component)
	return vim.tbl_extend("error", component, { truncate_hide = true, priority = hiding_order })
end

local function mode_name() return " " .. current_mode().name .. " " end

local function mode_block()
	return { fg = colors.page, bg = current_mode().hue, style = parhelion.draws_bold() and "bold" or nil }
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
