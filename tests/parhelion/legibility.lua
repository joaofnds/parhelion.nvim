local color = require "color"

local M = {}

M.text_floor = 30
M.smallest_body_contrast_on_a_wash = 4.5
M.smallest_wash_difference_from_the_cursor_line = 5
M.smallest_word_difference_from_its_line = 10
M.smallest_word_contrast = 4.5
M.smallest_description_contrast = 4.5
M.largest_drift = 10.5
M.largest_hue_shift = 1
M.largest_orange_hue_shift = 5.4
M.smallest_chroma_with_visible_hue = 0.05
M.smallest_accent_difference = 13
M.smallest_step_below_body = 10

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

local separators = { "▎", "│", "\u{E0B0}", "\u{E0B2}" }

function M.is_separator(text) return vim.list_contains(separators, text) end

function M.is_icon(text)
	local codepoint = vim.fn.char2nr(text)
	return (codepoint >= 0xE000 and codepoint <= 0xF8FF) or codepoint >= 0xF0000
end

function M.is_line_art_or_icon(text)
	local codepoint = vim.fn.char2nr(text)
	return (codepoint >= 0x2500 and codepoint <= 0x259F) or M.is_icon(text)
end

local function text_and_background(cell)
	if cell.flags:find("reverse", 1, true) then return cell.bg, cell.fg end
	return cell.fg, cell.bg
end

function M.illegible_text(shot, is_exempt)
	local found, seen = {}, {}
	for _, row in ipairs(shot.rows) do
		for _, cell in ipairs(row) do
			if not cell.text:match "^%s*$" and not is_exempt(cell.text) then
				local text, background = text_and_background(cell)
				local key = text .. background
				local lightness = math.abs(color.lightness_contrast(text, background))
				if not seen[key] and lightness < M.text_floor then
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

local function is_line_art(name)
	for _, word in ipairs(words_for_line_art) do
		if name:find(word) then return true end
	end

	return false
end

function M.groups_under_text_floor(snapshot)
	local found = {}
	for name, group in pairs(snapshot.groups) do
		local is_text = not is_line_art(name) and not vim.list_contains(M.decorations, name)
		if group.fg and not snapshot.links[name] and is_text then
			local text, background = group.fg, group.bg or snapshot.groups.Normal.bg
			if group.reverse then
				text, background = background, text
			end

			local lightness = math.abs(color.lightness_contrast(text, background))
			if lightness < M.text_floor then
				table.insert(found, { group = name, text = text, background = background, lightness = lightness })
			end
		end
	end

	return found
end

function M.pair(snapshot, name)
	local group = snapshot.groups[name]
	return group.fg, group.bg or snapshot.groups.Normal.bg
end

function M.below_tier(snapshot, tier)
	local found = {}
	for _, name in ipairs(tier.groups) do
		local text, background = M.pair(snapshot, name)
		local ratio = color.contrast_ratio(text, background)
		local lightness = math.abs(color.lightness_contrast(text, background))
		if ratio < tier.ratio or lightness < tier.lightness then
			table.insert(
				found,
				{ group = name, text = text, background = background, ratio = ratio, lightness = lightness }
			)
		end
	end

	return found
end

return M
