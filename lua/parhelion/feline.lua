local parhelion = require "parhelion"
local lsp = require "feline.providers.lsp"

local M = {}

local background = vim.o.background
local built = parhelion.built(background)
local colors, constant = built.colors, built.constant

local assets = {
	left_separator = "",
	right_separator = "",
	mode_icon = "",
	dir = "󰉖",
	file = "󰈙",
	lsp = {
		server = "󰅡",
		error = "",
		warning = "",
		info = "",
		hint = "",
	},
	git = {
		branch = "",
		added = "",
		changed = "",
		removed = "",
	},
}

local settings = {
	text = background == "light" and colors.page or colors.float,
	bkg = background == "light" and colors.raised or colors.float,
	diffs = colors.green,
	extras = colors.ghost,
	curr_file = colors.red,
	curr_dir = colors.blue,
	show_modified = false,
	show_lazy_updates = false,
}

local mode_colors = {
	["n"] = { "NORMAL", colors.blue },
	["no"] = { "N-PENDING", colors.blue },
	["i"] = { "INSERT", colors.green },
	["ic"] = { "INSERT", colors.green },
	["t"] = { "TERMINAL", colors.green },
	["v"] = { "VISUAL", colors.blue },
	["V"] = { "V-LINE", colors.blue },
	["\22"] = { "V-BLOCK", colors.blue },
	["R"] = { "REPLACE", colors.red },
	["Rv"] = { "V-REPLACE", colors.red },
	["s"] = { "SELECT", colors.red },
	["S"] = { "S-LINE", colors.red },
	["\19"] = { "S-BLOCK", colors.red },
	["c"] = { "COMMAND", constant },
	["cv"] = { "COMMAND", constant },
	["ce"] = { "COMMAND", constant },
	["r"] = { "PROMPT", colors.cyan },
	["rm"] = { "MORE", colors.cyan },
	["r?"] = { "CONFIRM", colors.green },
	["!"] = { "SHELL", colors.green },
}

local view = {
	lsp = {
		name = false,
		exclude_lsp_names = {},
		separator = "|",
	},
}

function M.setup(opts)
	opts = opts or {}
	assets = vim.tbl_deep_extend("force", assets, opts.assets or {})
	settings = vim.tbl_deep_extend("force", settings, opts.settings or {})
	mode_colors = vim.tbl_deep_extend("force", mode_colors, opts.mode_colors or {})
	view = vim.tbl_deep_extend("force", view, opts.view or {})
end

local function mode_label() return mode_colors[vim.fn.mode()][1] end

local function mode_color() return mode_colors[vim.fn.mode()][2] end

local function has_git_changes()
	local counts = vim.b.gitsigns_status_dict
	if not counts then return false end

	for _, kind in ipairs { "added", "removed", "changed" } do
		if (counts[kind] or 0) > 0 then return true end
	end

	return false
end

local function has_no_git_changes() return not has_git_changes() end

local function wider_than(columns)
	return function() return vim.api.nvim_win_get_width(0) > columns end
end

local function command_line_hidden() return vim.api.nvim_get_option_value("cmdheight", { scope = "global" }) == 0 end

local function lazy_has_updates()
	if not settings.show_lazy_updates or not pcall(require, "lazy") then return false end

	return require("lazy.status").has_updates()
end

local function lazy_updates() return require("lazy.status").updates() end

local function scroll_position()
	local line, last = vim.fn.line ".", vim.fn.line "$"
	if line == 1 then return "Top" end
	if line == last then return "Bot" end

	return math.floor(line / last * 100) .. "%%"
end

local function server_names()
	local clients = vim.lsp.get_clients { bufnr = 0 }
	if view.lsp.name == false and next(clients) ~= nil then return assets.lsp.server .. " Lsp" end

	local names = {}
	for _, client in ipairs(clients) do
		if not vim.list_contains(view.lsp.exclude_lsp_names, client.name) then table.insert(names, client.name) end
	end
	if #names == 0 then return "" end

	return assets.lsp.server .. " " .. table.concat(names, view.lsp.separator)
end

local function file_name()
	local name = vim.fn.expand "%:t"
	local has_icons, icons = pcall(require, "nvim-web-devicons")
	local icon = has_icons and icons.get_icon(name, vim.fn.expand "%:e") or assets.file

	return (settings.show_modified and "%m" or "") .. " " .. icon .. " " .. name .. " "
end

local function directory_name() return " " .. assets.dir .. " " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. " " end

local function file_type() return " " .. string.upper(vim.bo.ft) .. " " end

local function on_bar(fg) return { fg = fg, bg = settings.bkg } end

local function spacer() return { str = " ", hl = on_bar(settings.bkg) } end

local function bar_text(provider, enabled)
	return { provider = provider, enabled = enabled, hl = on_bar(settings.extras), left_sep = spacer() }
end

local function diff_count(provider, icon)
	return { provider = provider, hl = { fg = settings.text, bg = settings.diffs }, icon = " " .. icon .. " " }
end

local function diagnostic_count(provider, severity, color, icon)
	return {
		provider = provider,
		enabled = function() return lsp.diagnostics_exist(severity) end,
		hl = on_bar(color),
		icon = " " .. icon .. " ",
	}
end

local function mode_and_git()
	return {
		{
			provider = " " .. assets.mode_icon .. " ",
			hl = function() return { fg = settings.text, bg = mode_color() } end,
		},
		{
			provider = function() return mode_label() .. " " end,
			hl = function()
				return { fg = settings.text, bg = mode_color(), style = parhelion.draws_bold() and "bold" or nil }
			end,
		},
		{
			provider = assets.right_separator,
			hl = function() return on_bar(mode_color()) end,
			enabled = has_no_git_changes,
		},
		{
			provider = assets.right_separator,
			hl = function() return { fg = mode_color(), bg = settings.diffs } end,
			enabled = has_git_changes,
		},
		diff_count("git_diff_added", assets.git.added),
		diff_count("git_diff_changed", assets.git.changed),
		diff_count("git_diff_removed", assets.git.removed),
		{ provider = " ", hl = { fg = settings.bkg, bg = settings.diffs }, enabled = has_git_changes },
		{ provider = assets.right_separator, hl = on_bar(settings.diffs), enabled = has_git_changes },
		bar_text(scroll_position),
		bar_text "position",
		bar_text("macro", command_line_hidden),
		bar_text("search_count", command_line_hidden),
		bar_text(lazy_updates, lazy_has_updates),
	}
end

local function diagnostics()
	local severity = vim.diagnostic.severity

	return {
		diagnostic_count("diagnostic_errors", severity.ERROR, colors.red, assets.lsp.error),
		diagnostic_count("diagnostic_warnings", severity.WARN, colors.yellow, assets.lsp.warning),
		diagnostic_count("diagnostic_info", severity.INFO, colors.blue, assets.lsp.info),
		diagnostic_count("diagnostic_hints", severity.HINT, colors.body, assets.lsp.hint),
	}
end

local function branch_servers_and_place()
	return {
		{
			provider = "git_branch",
			enabled = wider_than(70),
			hl = on_bar(settings.extras),
			icon = assets.git.branch .. " ",
			right_sep = spacer(),
		},
		{ provider = server_names, hl = on_bar(settings.extras), right_sep = spacer() },
		{
			provider = file_name,
			enabled = wider_than(70),
			hl = { fg = settings.text, bg = settings.curr_file },
			left_sep = { str = assets.left_separator, hl = on_bar(settings.curr_file) },
		},
		{
			provider = directory_name,
			enabled = wider_than(80),
			hl = { fg = settings.text, bg = settings.curr_dir },
			left_sep = { str = assets.left_separator, hl = { fg = settings.curr_dir, bg = settings.curr_file } },
		},
	}
end

function M.get_statusline()
	return {
		active = { mode_and_git(), diagnostics(), branch_servers_and_place() },
		inactive = { { { provider = file_type, hl = { fg = colors.body, bg = colors.float } } } },
	}
end

return M
