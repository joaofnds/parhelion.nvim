local chrome = require "parhelion.chrome"
local color = require "color"

local M = {}

M.smallest_chroma_read_as_color = 0.07
M.largest_share_in_color_without_code = 0.1
M.largest_share_in_color_with_labels = 0.4
M.smallest_share_in_color_with_labels = 0.1

local neovim_own_groups = vim.api.nvim_get_hl(0, {})

local outside_the_theme_reach = {
	"Aqua$",
	"AquaFloat$",
	"Backdrop",
	"Blue$",
	"BlueFloat$",
	"Cyan$",
	"DevIcon",
	"Green$",
	"GreenFloat$",
	"Orange$",
	"Pink$",
	"Purple$",
	"PurpleFloat$",
	"Red$",
	"RedFloat$",
	"Violet$",
	"Yellow$",
	"YellowFloat$",
	"^BlinkIndent",
	"^BlinkPairs",
	"^BufferDefault",
	"^CmpItem%a+Default$",
	"^GitGraphBranch",
	"^LeapLabelDimmed$",
	"^MiniStatuslineMode",
	"^SagaActionTitle$",
	"^rainbowcol%d$",
}

local structure = {
	"Border",
	"Title",
	"Separator",
	"Guide",
	"Indent",
	"Kind",
	"Icon",
	"Normal",
	"Desc",
	"Footer",
	"Header",
	"Fill",
}

local families_with_label_hues = {
	"diffview",
	"headlines",
	"markdown_text",
	"markview",
	"mason",
	"mini_clue",
	"neogit",
	"render_markdown",
	"which_key",
}

local function names_with_label_hues()
	local names = {}
	for _, family_name in ipairs(families_with_label_hues) do
		for name in pairs(chrome.family_groups("dark", family_name)) do
			names[name] = true
		end
	end

	return names
end

local holds_label_hues = names_with_label_hues()

local derived_from_labels = {
	"^Neogit",
	"^RenderMarkdown_",
}

local function groups_lazy_links_to_core_groups()
	local lazy_colors = dofile(vim.env.PARHELION_DEPS .. "/lazy.nvim/lua/lazy/view/colors.lua").colors
	local names = {}
	for name, target in pairs(lazy_colors) do
		if type(target) == "string" then names["Lazy" .. name] = true end
	end

	return names
end

local follows_a_core_group = groups_lazy_links_to_core_groups()

local has_meaning = {
	"ERROR",
	"Error",
	"WARN",
	"Warn",
	"INFO",
	"Info",
	"Modified",
	"Busy",
	"Key$",
	"Group",
	"Link",
	"Spinner",
	"CmdlineIcon",
	"InputIcon",
	"MultiIcon",
	"HoverIcon",
	"PickPivot",
	"Git",
	"Diagnostic",
	"^NvimSeparator$",
}

local function matches_any(name, patterns)
	for _, pattern in ipairs(patterns) do
		if name:find(pattern) then return true end
	end

	return false
end

local past_the_boundary = {
	"^@",
	"^Diagnostic",
	"^DiffviewCursorLine$",
	"^DiffviewEndOfBuffer$",
	"^DiffviewNormal$",
	"^Diffview[Ss]tatus[Ll]ine",
	"^GitGutter",
	"^GitSigns%u%l+$",
	"^GitSigns%u%l+Cul$",
	"^GitSigns%u%l+Ln$",
	"^GitSigns%u%l+Nr$",
	"^GitSignsStaged",
	"^Lsp",
	"^NeogitCursorLine",
	"^NeogitFoldColumn$",
	"^NeogitNormal$",
	"^NeogitSignColumn$",
	"^RenderMarkdownH%dBg$",
	"^%l",
}

local core_of_the_buffer = {
	"Added",
	"Boolean",
	"Changed",
	"Character",
	"ColorColumn",
	"Comment",
	"Conceal",
	"Conditional",
	"Constant",
	"CursorColumn",
	"CursorLine",
	"CursorLineFold",
	"CursorLineNr",
	"CursorLineSign",
	"Define",
	"Delimiter",
	"Error",
	"Exception",
	"Float",
	"FoldColumn",
	"Folded",
	"Function",
	"Identifier",
	"IncSearch",
	"Include",
	"Keyword",
	"Label",
	"LineNr",
	"LineNrAbove",
	"LineNrBelow",
	"Macro",
	"MatchParen",
	"Normal",
	"NormalFloat",
	"NormalNC",
	"Number",
	"Operator",
	"PreCondit",
	"PreProc",
	"Removed",
	"Repeat",
	"Search",
	"SignColumn",
	"Special",
	"SpecialChar",
	"SpecialComment",
	"Statement",
	"StatusLine",
	"StatusLineNC",
	"StorageClass",
	"String",
	"Structure",
	"Tag",
	"TagAttribute",
	"Todo",
	"Type",
	"Typedef",
	"Underlined",
	"Visual",
}

local inside_the_boundary = {
	"^@diff%.plus$",
	"^Added$",
	"^DiagnosticText$",
	"^DiagnosticUnderline%u%l+$",
	"^GitGutterAdd$",
	"^GitGutterAddLineNr$",
	"^GitSignsAdd$",
	"^LspKind",
	"^LspReference%u%l+$",
	"^Todo$",
	"^Visual$",
	"^markdownH%d$",
	"^rainbowcol%d$",
	"^tk%u%l+$",
}

local function crosses_the_boundary(name)
	local crosses = matches_any(name, past_the_boundary) or vim.list_contains(core_of_the_buffer, name)

	return crosses and not matches_any(name, inside_the_boundary)
end

local function is_a_plugin_group(name)
	if neovim_own_groups[name] or crosses_the_boundary(name) then return false end

	return not matches_any(name, outside_the_theme_reach)
end

local function reads_as_color(hex) return color.perceptual_lch(hex).chroma > M.smallest_chroma_read_as_color end

local function set_of(steps)
	local set = {}
	for _, step in pairs(steps) do
		set[step] = true
	end

	return set
end

local function may_hold_a_label_hue(name) return holds_label_hues[name] or matches_any(name, derived_from_labels) end

function M.hues_off_the_scale(background, colors_by_group)
	local on_the_scale = set_of(chrome.scale[background])
	local label_hues = set_of(chrome.label_hues[background])
	local code_hues = set_of(chrome.hues[background])
	local found = {}
	for name, colors in pairs(colors_by_group) do
		if is_a_plugin_group(name) then
			for attribute, hex in pairs(colors) do
				local allowed = on_the_scale[hex:lower()]
					or (may_hold_a_label_hue(name) and label_hues[hex:lower()])
					or (follows_a_core_group[name] and code_hues[hex:lower()])
				if reads_as_color(hex) and not allowed then
					table.insert(found, { group = name, attribute = attribute, color = hex })
				end
			end
		end
	end

	return found
end

function M.share_of_text_in_color(shot, is_icon)
	local text, colored = 0, 0
	for _, row in ipairs(shot.rows) do
		for _, cell in ipairs(row) do
			if not cell.text:match "^%s*$" and not is_icon(cell.text) then
				text = text + 1
				if reads_as_color(cell.fg) then colored = colored + 1 end
			end
		end
	end

	return text == 0 and 0 or colored / text
end

function M.cells_on(shot, background)
	local cells = {}
	for _, row in ipairs(shot.rows) do
		for _, cell in ipairs(row) do
			if cell.bg == background then table.insert(cells, cell) end
		end
	end

	return cells
end

function M.colored_structure(colors_by_group)
	local found = {}
	for name, colors in pairs(colors_by_group) do
		local is_structure = matches_any(name, structure) and not holds_label_hues[name]
		if is_a_plugin_group(name) and is_structure and not matches_any(name, has_meaning) then
			for attribute, hex in pairs(colors) do
				if reads_as_color(hex) then
					table.insert(found, { group = name, attribute = attribute, color = hex })
				end
			end
		end
	end

	return found
end

function M.restyled_past_the_boundary(families)
	local found = {}
	for _, family in pairs(families) do
		for _, names in pairs(family) do
			for name in names:gmatch "%S+" do
				if crosses_the_boundary(name) then table.insert(found, name) end
			end
		end
	end

	return found
end

function M.groups_in_two_roles(families)
	local first_role, found = {}, {}
	for _, family in pairs(families) do
		for role, names in pairs(family) do
			for name in names:gmatch "%S+" do
				local key = name:lower()
				if first_role[key] then table.insert(found, { group = name, roles = { first_role[key], role } }) end
				first_role[key] = first_role[key] or role
			end
		end
	end

	return found
end

return M
