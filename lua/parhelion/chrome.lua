local refinement = require "parhelion.refinement"

local M = {}

local solarized = {
	base03 = "#002b36",
	base02 = "#073642",
	base01 = "#586e75",
	base00 = "#657b83",
	base0 = "#839496",
	base1 = "#93a1a1",
	base2 = "#eee8d5",
	base3 = "#fdf6e3",
	yellow = "#b58900",
	orange = "#cb4b16",
	red = "#dc322f",
	magenta = "#d33682",
	violet = "#6c71c4",
	blue = "#268bd2",
	cyan = "#2aa198",
	green = "#859900",
}

local tone = refinement.color

local function strict(table_name, colors_by_background)
	for background, colors in pairs(colors_by_background) do
		setmetatable(colors, {
			__index = function(_, name)
				error(string.format("the %s %s has no color named %s", background, table_name, tostring(name)), 2)
			end,
		})
	end

	return colors_by_background
end

M.scale = strict("scale", {
	dark = {
		page = solarized.base03,
		float = "#002731",
		raised = solarized.base02,
		selected = "#0d414e",
		hairline = "#27505b",
		ghost = tone("dark", solarized.base01),
		quiet = tone("dark", solarized.base01),
		body = tone("dark", solarized.base0),
		strong = "#c9ccc3",
		accent = tone("dark", solarized.blue),
		error = tone("dark", solarized.red),
		warn = tone("dark", solarized.yellow),
		ok = tone("dark", solarized.green),
		added = tone("dark", solarized.green),
		added_wash = "#23381f",
		changed_wash = "#023751",
		removed_wash = "#422d33",
		added_word_wash = "#38591f",
		changed_word_wash = "#135b84",
		removed_word_wash = "#6e2f33",
		match_wash = "#67462e",
		staged_added = "#7d9239",
		staged_changed = "#a1904b",
		staged_removed = "#c36764",
		backdrop = "#000000",
	},
	light = {
		page = solarized.base3,
		float = "#fbf3db",
		raised = solarized.base2,
		selected = "#e2dbc7",
		hairline = "#c9c6b6",
		ghost = tone("light", solarized.base1),
		quiet = tone("light", solarized.base0),
		body = tone("light", solarized.base00),
		strong = "#2a4c55",
		accent = tone("light", solarized.blue),
		error = tone("light", solarized.red),
		warn = tone("light", solarized.yellow),
		ok = tone("light", solarized.green),
		added = tone("light", solarized.green),
		added_wash = "#eceecc",
		changed_wash = "#e0eeef",
		removed_wash = "#fce8da",
		added_word_wash = "#c7cc7d",
		changed_word_wash = "#9ac5db",
		removed_word_wash = "#f3bbad",
		match_wash = "#dac994",
		staged_added = "#9ca54b",
		staged_changed = "#b79d4b",
		staged_removed = "#e27269",
		backdrop = "#a39c87",
	},
})

local accent_names = { "yellow", "orange", "red", "magenta", "violet", "blue", "cyan", "green" }

local function toned_accents(background)
	local accents = {}
	for _, name in ipairs(accent_names) do
		accents[name] = tone(background, solarized[name])
	end

	return accents
end

M.hues = strict("hues", {
	dark = toned_accents "dark",
	light = toned_accents "light",
})

M.label_hues = strict("label_hues", {
	dark = {
		description = "#3fb3a9",
		magenta = M.hues.dark.magenta,
		orange = M.hues.dark.orange,
		violet = M.hues.dark.violet,
	},
	light = {
		description = "#007a72",
		magenta = M.hues.light.magenta,
		orange = M.hues.light.orange,
		violet = M.hues.light.violet,
	},
})

local function base_look(background, name)
	local hl = require("parhelion.base." .. background).groups[name]

	return { fg = tone(background, hl.fg):lower(), bold = hl.bold }
end

local function base_fill(background, name)
	local hl = require("parhelion.base." .. background).groups[name]

	return { bg = tone(background, hl.bg):lower() }
end

M.constant_hue = {
	dark = base_look("dark", "Constant").fg,
	light = base_look("light", "Constant").fg,
}

local function looks(background)
	local scale = M.scale[background]
	local hues = M.label_hues[background]
	local accents = M.hues[background]
	local look = {
		accent = { fg = scale.accent },
		accent_bold = { fg = scale.accent, bold = true },
		accent_bold_underlined = { fg = scale.accent, bold = true, underline = true },
		added = { fg = scale.added },
		added_bold = { fg = scale.added, bold = true },
		added_inline = { fg = scale.strong, bg = scale.added_word_wash, bold = true },
		added_line = { bg = scale.added_wash },
		added_strong = { fg = scale.strong, bg = scale.added_wash },
		added_word = { fg = scale.strong, bg = scale.added_word_wash },
		backdrop = { bg = scale.backdrop },
		base_added = base_look(background, "Added"),
		body = { fg = scale.body },
		body_bold = { fg = scale.body, bold = true },
		body_italic_opaque = { fg = scale.body, italic = true, blend = 0 },
		bold = { bold = true },
		changed_inline = { fg = scale.strong, bg = scale.changed_word_wash },
		changed_line = { bg = scale.changed_wash },
		description = { fg = hues.description },
		error = { fg = scale.error },
		error_bold = { fg = scale.error, bold = true },
		faint = { fg = scale.raised },
		float_body = { fg = scale.body, bg = scale.float },
		float_accent = { fg = scale.accent, bg = scale.float },
		float_error = { fg = scale.error, bg = scale.float },
		float_hairline = { fg = scale.hairline, bg = scale.float },
		float_quiet = { fg = scale.quiet, bg = scale.float },
		float_strong = { fg = scale.strong, bg = scale.float },
		float_title = { fg = scale.strong, bg = scale.float, bold = true },
		float_ok = { fg = scale.ok, bg = scale.float },
		float_warn = { fg = scale.warn, bg = scale.float },
		ghost = { fg = scale.ghost },
		ghost_italic = { fg = scale.ghost, italic = true },
		ghost_italic_opaque = { fg = scale.ghost, italic = true, blend = 0 },
		group_label = base_look(background, "Constant"),
		hairline = { fg = scale.hairline },
		hidden_on_float = { fg = scale.float, bg = scale.float },
		hidden_on_page = { fg = scale.page, bg = scale.page },
		italic = { italic = true },
		label = { fg = scale.page, bg = scale.accent, bold = true },
		magenta_bold = { fg = hues.magenta, bold = true },
		match = { fg = scale.strong, bg = scale.match_wash },
		ok = { fg = scale.ok },
		ok_bold = { fg = scale.ok, bold = true },
		orange_bold = { fg = hues.orange, bold = true },
		orange_bold_underlined = { fg = hues.orange, bold = true, underline = true },
		page_body = { fg = scale.body, bg = scale.page },
		page_ink = { fg = scale.page },
		page_title = { fg = scale.strong, bg = scale.page, bold = true },
		page_accent = { fg = scale.accent, bg = scale.page },
		page_quiet = { fg = scale.quiet, bg = scale.page },
		page_warn = { fg = scale.warn, bg = scale.page },
		plain = {},
		quiet = { fg = scale.quiet },
		quiet_bubble = { fg = scale.page, bg = scale.quiet },
		quiet_italic = { fg = scale.quiet, italic = true },
		quiet_struck = { fg = scale.quiet, strikethrough = true },
		raised_fill = { bg = scale.raised },
		raised_body = { fg = scale.body, bg = scale.raised },
		raised_body_bold = { fg = scale.body, bg = scale.raised, bold = true },
		raised_hairline = { fg = scale.hairline, bg = scale.raised },
		raised_accent = { fg = scale.accent, bg = scale.raised },
		raised_accent_bold = { fg = scale.accent, bg = scale.raised, bold = true },
		raised_added = { fg = scale.added, bg = scale.raised },
		raised_error = { fg = scale.error, bg = scale.raised },
		raised_quiet = { fg = scale.quiet, bg = scale.raised },
		raised_quiet_bold = { fg = scale.quiet, bg = scale.raised, bold = true },
		raised_staged_added = { fg = scale.staged_added, bg = scale.raised },
		raised_staged_changed = { fg = scale.staged_changed, bg = scale.raised },
		raised_staged_removed = { fg = scale.staged_removed, bg = scale.raised },
		raised_title = { fg = scale.strong, bg = scale.raised, bold = true },
		raised_warn = { fg = scale.warn, bg = scale.raised },
		removed_filler = { fg = scale.quiet, bg = scale.removed_wash },
		removed_inline = { fg = scale.strong, bg = scale.removed_word_wash, bold = true },
		removed_line = { bg = scale.removed_wash },
		removed_strong = { fg = scale.strong, bg = scale.removed_wash },
		selected_strong = { fg = scale.strong, bg = scale.selected },
		selected_accent = { fg = scale.accent, bg = scale.selected },
		selected_accent_bold = { fg = scale.accent, bg = scale.selected, bold = true },
		selected_body = { fg = scale.body, bg = scale.selected },
		selected_row = { bg = scale.selected },
		selected_title = { fg = scale.strong, bg = scale.selected, bold = true },
		selection = base_fill(background, "Visual"),
		strong = { fg = scale.strong },
		thumb = { bg = scale.hairline },
		title = { fg = scale.strong, bold = true },
		violet_bold = { fg = hues.violet, bold = true },
		warn = { fg = scale.warn },
		warn_bold = { fg = scale.warn, bold = true },
	}

	for name, hue in pairs(accents) do
		look[name] = { fg = hue }
		look[name .. "_underline"] = { sp = hue, underline = true }
		look[name .. "_undercurl"] = { sp = hue, undercurl = true }
		look[name .. "_bubble"] = { fg = scale.page, bg = hue }
		look[name .. "_bubble_bold"] = { fg = scale.page, bg = hue, bold = true }
		look["page_" .. name] = { fg = hue, bg = scale.page }
	end

	for level = 1, 6 do
		local heading = base_look(background, "@markup.heading." .. level)
		look["heading_" .. level] = heading
		look["raised_heading_" .. level] = { fg = heading.fg, bg = scale.raised, bold = true }
	end

	return look
end

local function names_from(template, items)
	local names = {}
	for _, item in ipairs(items) do
		table.insert(names, string.format(template, item))
	end

	return table.concat(names, " ")
end

local kind_names = vim.split(
	"Array Boolean Class Color Constant Constructor Default Enum EnumMember Event Field File Folder Function Interface "
		.. "Key Keyword Method Module Namespace Null Number Object Operator Package Parameter Property Reference Snippet "
		.. "StaticMethod String Struct Text TypeAlias TypeParameter Unit Value Variable",
	" "
)

local function kinds(template) return names_from(template, kind_names) end

local dropbar_statement_names = vim.split(
	"BlockMappingPair BreakStatement Call CaseStatement ContinueStatement Declaration Delete DoStatement Element "
		.. "ElseStatement ForStatement GotoStatement Identifier IfStatement List Macro MarkdownH1 MarkdownH2 MarkdownH3 "
		.. "MarkdownH4 MarkdownH5 MarkdownH6 Pair Repeat ReturnStatement Rule RuleSet Scope Section Specifier Statement "
		.. "SwitchStatement Table Terminal Type WhileStatement",
	" "
)

local dropbar_kind_names = vim.split(
	"Array Boolean BreakStatement Call CaseStatement Class Constant Constructor ContinueStatement Declaration Delete "
		.. "DoStatement ElseStatement Enum EnumMember Event Field File Folder ForStatement Function Identifier IfStatement "
		.. "Interface Keyword List Macro MarkdownH1 MarkdownH2 MarkdownH3 MarkdownH4 MarkdownH5 MarkdownH6 Method Module "
		.. "Namespace Null Number Object Operator Package Property Reference Repeat Scope Specifier Statement String Struct "
		.. "SwitchStatement Type TypeParameter Unit Value Variable WhileStatement",
	" "
)

local function directory_listing(kind)
	return names_from(
		"DropbarDirPreview" .. kind .. "%s",
		{ "Group", "NumHardLinksMulti", "NumHardLinksNormal", "Size", "Time", "User" }
	)
end

local function numbered(template, first, last)
	local indexes = {}
	for index = first, last do
		table.insert(indexes, index)
	end

	return names_from(template, indexes)
end

M.families = {
	editor_frame = {
		accent_bold = "PmenuMatch",
		base_added = "PreInsert",
		bold = "Bold",
		error = "NvimFigureBrace NvimInternalError NvimInvalidSingleQuotedUnknownEscape NvimSingleQuotedUnknownEscape",
		float_hairline = "FloatBorder",
		float_quiet = "FloatFooter",
		float_title = "FloatTitle",
		italic = "Italic",
		quiet = "WinBar WinBarNC",
		raised_fill = "PmenuSbar",
		raised_body = "Pmenu",
		raised_quiet = "PmenuExtra PmenuKind",
		selected_strong = "PmenuSel WildMenu",
		selected_accent_bold = "PmenuMatchSel",
		selected_body = "PmenuExtraSel PmenuKindSel",
		strong = "Directory",
		thumb = "PmenuThumb",
		title = "Title",
	},
	text_overlays = {
		blue_underline = "DiagnosticUnderlineHint DiagnosticUnderlineInfo",
		cyan_undercurl = "SpellRare",
		green_underline = "DiagnosticUnderlineOk",
		magenta_bold = "Todo",
		match = "Search",
		red_undercurl = "SpellBad",
		red_underline = "DiagnosticUnderlineError",
		selected_row = "LspReferenceRead LspReferenceText LspReferenceWrite",
		selected_strong = "QuickFixLine",
		selection = "Visual",
		violet_undercurl = "SpellCap",
		yellow_bubble_bold = "IncSearch",
		yellow_undercurl = "SpellLocal",
		yellow_underline = "DiagnosticUnderlineWarn",
	},
	window_separators = {
		hairline = "DiffviewWinSeparator NeogitWinSeparator VertSplit WinSeparator",
	},
	diff_marks = {
		added = "@diff.plus Added GitGutterAdd GitGutterAddLineNr",
		raised_added = "GitSignsAdd",
		raised_staged_added = "GitSignsStagedAdd GitSignsStagedAddCul GitSignsStagedAddNr "
			.. "GitSignsStagedUntracked GitSignsStagedUntrackedCul GitSignsStagedUntrackedNr",
		raised_staged_changed = "GitSignsStagedChange GitSignsStagedChangeCul GitSignsStagedChangeNr "
			.. "GitSignsStagedChangedelete GitSignsStagedChangedeleteCul GitSignsStagedChangedeleteNr",
		raised_staged_removed = "GitSignsStagedDelete GitSignsStagedDeleteCul GitSignsStagedDeleteNr "
			.. "GitSignsStagedTopdelete GitSignsStagedTopdeleteCul GitSignsStagedTopdeleteNr",
	},
	diff_lines = {
		added_line = "DiffAdd",
		added_word = "DiffTextAdd",
		changed_inline = "DiffText",
		changed_line = "DiffChange",
		removed_filler = "DiffDelete",
	},
	diffview = {
		accent = "DiffviewFolderSign DiffviewPrimary DiffviewSecondary",
		accent_bold = "DiffviewFilePanelTitle DiffviewFolderName DiffviewReference",
		added = "DiffviewFilePanelInsertions DiffviewStatusAdded DiffviewStatusUntracked",
		body = "DiffviewFilePanelCounter",
		error = "DiffviewFilePanelDeletions DiffviewStatusBroken DiffviewStatusDeleted DiffviewStatusUnknown",
		quiet = "DiffviewDim1 DiffviewFilePanelPath DiffviewHash DiffviewStatusIgnored",
		strong = "DiffviewFilePanelSelected",
		violet = "DiffviewReflogSelector",
		violet_bold = "DiffviewFilePanelRootPath",
		warn = "DiffviewFilePanelConflicts DiffviewStatusCopied DiffviewStatusModified DiffviewStatusRenamed "
			.. "DiffviewStatusTypeChange DiffviewStatusUnmerged",
	},
	neogit = {
		accent = "NeogitFilePath NeogitPopupConfigEnabled NeogitPopupOptionEnabled NeogitPopupSwitchEnabled "
			.. "NeogitTagDistance",
		accent_bold = "NeogitPopupBranchName NeogitPopupSectionTitle",
		added = "NeogitDiffAdditions",
		added_bold = "NeogitChangeAdded NeogitChangeNewFile",
		added_inline = "NeogitDiffAddInline",
		added_line = "NeogitDiffAdd NeogitDiffAddHighlight",
		added_strong = "NeogitDiffAddCursor",
		body = "NeogitCommitViewDescription NeogitSectionHeaderCount",
		error = "NeogitDiffDeletions NeogitSignatureGoodRevokedKey",
		error_bold = "NeogitChangeDeleted NeogitSignatureBad",
		magenta_bold = "NeogitChangeCopied",
		ok = "NeogitSignatureGood",
		ok_bold = "NeogitRemote",
		orange_bold = "NeogitBranch NeogitChangeUpdated",
		orange_bold_underlined = "NeogitBranchHead",
		quiet = "NeogitCommandCodeNormal NeogitSignatureMissing",
		raised_accent = "NeogitHunkHeader",
		raised_accent_bold = "NeogitCommitViewHeader NeogitDiffHeader NeogitFloatHeaderHighlight NeogitHunkMergeHeader",
		raised_body = "NeogitDiffContextHighlight",
		raised_title = "NeogitActiveItem",
		removed_inline = "NeogitDiffDeleteInline",
		removed_line = "NeogitDiffDelete NeogitDiffDeleteHighlight",
		removed_strong = "NeogitDiffDeleteCursor",
		selected_accent_bold = "NeogitDiffHeaderHighlight NeogitHunkHeaderCursor NeogitHunkHeaderHighlight "
			.. "NeogitHunkMergeHeaderCursor NeogitHunkMergeHeaderHighlight",
		selected_row = "NeogitDiffContextCursor",
		violet = "NeogitGraphAuthor NeogitPopupActionKey NeogitPopupConfigKey NeogitPopupOptionKey NeogitPopupSwitchKey",
		violet_bold = "NeogitChangeRenamed NeogitSectionHeader NeogitUnmergedInto NeogitUnpulledFrom NeogitUnpushedTo",
		warn = "NeogitSignatureGoodExpired NeogitSignatureGoodExpiredKey NeogitSignatureGoodUnknown NeogitTagName",
		warn_bold = "NeogitChangeModified NeogitChangeUnmerged",
	},
	backdrops = {
		backdrop = "FzfLuaBackdrop LazyBackdrop MasonBackdrop",
	},
	tab_line = {
		float_quiet = "TabLine",
		float_body = "TabLineFill",
		page_title = "TabLineSel",
	},

	telescope = {
		accent = "TelescopeMultiIcon TelescopeMultiSelection",
		accent_bold = "TelescopeMatching TelescopePreviewMatch",
		added = "TelescopeResultsDiffAdd",
		error = "TelescopeResultsDiffDelete",
		float_body = "TelescopeNormal TelescopePreviewNormal TelescopePromptNormal TelescopeResultsNormal",
		float_accent = "TelescopePromptPrefix",
		float_hairline = "TelescopeBorder TelescopePreviewBorder TelescopePromptBorder TelescopeResultsBorder",
		float_quiet = "TelescopePreviewTitle TelescopePromptCounter TelescopeResultsTitle",
		float_title = "TelescopePromptTitle TelescopeTitle",
		quiet = "TelescopePreviewBlock TelescopePreviewCharDev TelescopePreviewDate TelescopePreviewExecute TelescopePreviewGroup "
			.. "TelescopePreviewHyphen TelescopePreviewLink TelescopePreviewPipe TelescopePreviewRead TelescopePreviewSize TelescopePreviewUser "
			.. "TelescopeResultsConstant TelescopeResultsDiffUntracked TelescopeResultsNumber TelescopeResultsVariable",
		raised_fill = "TelescopePreviewLine",
		selected_strong = "TelescopeSelection",
		selected_accent = "TelescopeSelectionCaret",
		warn = "TelescopeResultsDiffChange",
	},
	fzf_lua = {
		accent = "FzfLuaFzfMarker FzfLuaFzfPointer FzfLuaFzfSpinner FzfLuaLivePrompt FzfLuaLiveSym",
		accent_bold = "FzfLuaFzfMatch",
		base_added = "FzfLuaCmdBuf",
		raised_fill = "FzfLuaScrollFloatEmpty",
		thumb = "FzfLuaScrollFloatFull",
		float_body = "FzfLuaFzfGutter FzfLuaFzfNormal FzfLuaFzfQuery FzfLuaHelpNormal FzfLuaNormal FzfLuaPreviewNormal",
		float_hairline = "FzfLuaBorder FzfLuaFzfBorder FzfLuaFzfScrollbar FzfLuaFzfSeparator FzfLuaHelpBorder "
			.. "FzfLuaPreviewBorder FzfLuaScrollBorderEmpty FzfLuaScrollBorderFull",
		float_quiet = "FzfLuaPreviewTitle FzfLuaTitleFlags",
		float_title = "FzfLuaTitle",
		quiet = "FzfLuaBufFlagAlt FzfLuaBufFlagCur FzfLuaBufId FzfLuaBufLineNr FzfLuaBufNr FzfLuaDirPart FzfLuaFzfHeader "
			.. "FzfLuaFzfInfo FzfLuaFzfPrompt FzfLuaHeaderBind FzfLuaHeaderText FzfLuaPathColNr FzfLuaPathLineNr FzfLuaTabMarker",
		selected_strong = "FzfLuaCursorLineNr",
		selected_row = "FzfLuaCursorLine FzfLuaFzfCursorLine FzfLuaSearch",
		strong = "FzfLuaBufName FzfLuaCmdGlobal FzfLuaDirIcon FzfLuaTabTitle",
	},
	snacks_picker = {
		accent = "SnacksPickerLabel SnacksPickerSelected SnacksPickerSpinner",
		accent_bold = "SnacksPickerMatch",
		float_body = "SnacksPicker SnacksPickerBox SnacksPickerInput SnacksPickerList SnacksPickerPreview",
		float_hairline = "SnacksPickerBorder SnacksPickerBoxBorder SnacksPickerInputBorder SnacksPickerListBorder "
			.. "SnacksPickerPreviewBorder",
		float_accent = "SnacksPickerPrompt",
		float_quiet = "SnacksPickerFooter SnacksPickerListTitle SnacksPickerPreviewTitle",
		float_title = "SnacksPickerBoxTitle SnacksPickerInputTitle SnacksPickerTitle",
		label = "SnacksPickerPickWinCurrent",
		body = "SnacksPickerCode",
		plain = "SnacksPickerFile",
		quiet = "SnacksPickerAuEvent SnacksPickerAuGroup SnacksPickerAuPattern SnacksPickerBufNr SnacksPickerCmdBuiltin SnacksPickerCol "
			.. "SnacksPickerDesc SnacksPickerDiagnosticCode SnacksPickerDir SnacksPickerGitAuthor "
			.. "SnacksPickerGitBranchCurrent SnacksPickerGitCommit SnacksPickerGitDate SnacksPickerGitIssue SnacksPickerIcon "
			.. "SnacksPickerIconCategory SnacksPickerIconSource SnacksPickerIdx SnacksPickerKeymapLhs SnacksPickerKeymapMode "
			.. "SnacksPickerKeymapNowait SnacksPickerLspEnabled SnacksPickerManPage SnacksPickerManSection "
			.. "SnacksPickerRegister SnacksPickerRow SnacksPickerSpecial SnacksPickerTime SnacksPickerTotal "
			.. "SnacksPickerUndoCurrent SnacksPickerUndoSaved "
			.. kinds "SnacksPickerIcon%s",
		warn = "SnacksPickerGitStatus SnacksPickerGitStatusCopied SnacksPickerGitStatusRenamed",
		selected_row = "SnacksPickerPreviewCursorLine",
		selected_strong = "SnacksPickerCursorLine SnacksPickerListCursorLine",
		strong = "SnacksPickerDirectory",
	},
	mini_pick = {
		accent_bold = "MiniPickMatchRanges",
		float_body = "MiniPickNormal MiniPickPrompt",
		float_accent = "MiniPickPromptCaret MiniPickPromptPrefix",
		float_hairline = "MiniPickBorder",
		float_quiet = "MiniPickBorderText MiniPickHeader",
		quiet = "MiniPickIconDirectory MiniPickIconFile",
		raised_fill = "MiniPickPreviewLine MiniPickPreviewRegion",
		selected_strong = "MiniPickMatchCurrent",
		selected_row = "MiniPickMatchMarked",
		warn = "MiniPickBorderBusy",
	},

	cmp = {
		accent_bold = "CmpItemAbbrMatch CmpItemAbbrMatchFuzzy",
		plain = "CmpItemAbbr",
		quiet = "CmpItemKind CmpItemKindCopilot CmpItemKindIcon CmpItemKindIconDefault CmpItemMenu "
			.. kinds "CmpItemKind%s"
			.. " "
			.. kinds "CmpItemKind%sIcon"
			.. " "
			.. kinds "CmpItemKind%sIconDefault",
		quiet_struck = "CmpItemAbbrDeprecated",
	},
	blink_cmp = {
		accent_bold = "BlinkCmpLabelMatch BlinkCmpSignatureHelpActiveParameter",
		plain = "BlinkCmpLabel",
		quiet = "BlinkCmpKind BlinkCmpLabelDescription BlinkCmpLabelDetail BlinkCmpSource " .. kinds "BlinkCmpKind%s",
		quiet_italic = "BlinkCmpGhostText",
		quiet_struck = "BlinkCmpLabelDeprecated",
		raised_fill = "BlinkCmpScrollBarGutter",
		raised_body = "BlinkCmpDoc BlinkCmpMenu BlinkCmpSignatureHelp",
		raised_hairline = "PmenuBorder BlinkCmpDocBorder BlinkCmpDocSeparator BlinkCmpMenuBorder BlinkCmpSignatureHelpBorder",
		selected_strong = "BlinkCmpMenuSelection",
		selected_row = "BlinkCmpDocCursorLine",
		thumb = "BlinkCmpScrollBarThumb",
	},

	nvim_tree = {
		hidden_on_float = "NvimTreeStatuslineNc",
		accent = "NvimTreeLiveFilterPrefix",
		accent_bold = "NvimTreeWindowPicker",
		body = "NvimTreeExecFile NvimTreeImageFile NvimTreeSpecialFile",
		error = "NvimTreeGitDeleted",
		float_body = "NvimTreeNormal NvimTreeNormalFloat",
		hairline = "NvimTreeIndentMarker NvimTreeWinSeparator",
		added = "NvimTreeGitNew NvimTreeGitStaged",
		selected_strong = "NvimTreeCursorLineNr",
		selected_row = "NvimTreeCursorLine",
		quiet = "NvimTreeFolderArrowClosed NvimTreeFolderArrowOpen NvimTreeFolderIcon NvimTreeHiddenIcon NvimTreeSymlink "
			.. "NvimTreeSymlinkIcon",
		strong = "NvimTreeEmptyFolderName NvimTreeFolderName NvimTreeOpenedFile",
		title = "NvimTreeOpenedFolderName NvimTreeRootFolder",
		warn = "NvimTreeGitDirty NvimTreeGitMerge NvimTreeGitRenamed NvimTreeModifiedFile",
	},
	neo_tree = {
		hidden_on_float = "NeoTreeStatusLineNC",
		accent_bold = "NeoTreeFilterTerm",
		body = "NeoTreeFileName",
		error = "NeoTreeGitConflict NeoTreeGitDeleted",
		float_body = "NeoTreeFloatNormal NeoTreeNormal NeoTreeNormalNC",
		float_hairline = "NeoTreeFloatBorder",
		float_quiet = "NeoTreeTabInactive NeoTreeTabSeparatorActive NeoTreeTabSeparatorInactive",
		float_title = "NeoTreeFloatTitle NeoTreeTabActive",
		hairline = "NeoTreeIndentMarker NeoTreeVertSplit NeoTreeWinSeparator",
		added = "NeoTreeGitAdded NeoTreeGitStaged",
		quiet = "NeoTreeBufferNumber NeoTreeDimText NeoTreeDirectoryIcon NeoTreeDotFile NeoTreeExpander NeoTreeFileIcon "
			.. "NeoTreeFileStats NeoTreeFileStatsHeader NeoTreeGitIgnored NeoTreeGitUntracked NeoTreeHiddenByName "
			.. "NeoTreeIgnored NeoTreeSymbolicLinkTarget NeoTreeWindowsHidden",
		quiet_italic = "NeoTreeMessage",
		raised_fill = "NeoTreePreview",
		selected_row = "NeoTreeCursorLine",
		strong = "NeoTreeDirectoryName NeoTreeFileNameOpened",
		title = "NeoTreeRootName NeoTreeTitleBar",
		warn = "NeoTreeGitModified NeoTreeGitRenamed NeoTreeGitUnstaged NeoTreeModified",
	},
	oil = {
		accent = "OilCopy OilCreate OilRestore",
		error = "OilDelete OilOrphanLinkTarget OilPurge OilTrash",
		quiet = "OilDirIcon OilEmpty OilHidden OilLinkTarget OilTrashSourcePath",
		strong = "OilDir",
		warn = "OilChange OilMove",
	},
	mini_files = {
		body = "MiniFilesFile",
		float_body = "MiniFilesNormal",
		float_hairline = "MiniFilesBorder",
		float_quiet = "MiniFilesTitle",
		float_title = "MiniFilesTitleFocused",
		selected_row = "MiniFilesCursorLine",
		strong = "MiniFilesDirectory",
		warn = "MiniFilesBorderModified",
	},
	aerial = {
		body = "AerialNormal",
		float_body = "AerialNormalFloat",
		hairline = "AerialGuide " .. numbered("AerialGuide%d", 1, 9),
		quiet = kinds "Aerial%sIcon",
		selected_row = "AerialLine AerialLineNC",
	},
	lir = {
		body = "LirEmptyDirText LirFloatCurdirWindowNormal LirFloatNormal",
		body_bold = "LirFloatCurdirWindowDirName",
		hidden_on_page = "LirFloatBorder",
		quiet = "LirSymLink",
		strong = "LirDir",
	},

	bufferline = {
		accent = "BufferLineIndicatorSelected",
		body = "BufferLineBufferVisible BufferLineCloseButtonVisible BufferLineDuplicateVisible BufferLineIndicatorVisible "
			.. "BufferLineNumbersVisible",
		error = "BufferLineErrorDiagnosticSelected BufferLineErrorSelected",
		float_quiet = "BufferLineBackground BufferLineBuffer BufferLineCloseButton BufferLineDuplicate BufferLineError "
			.. "BufferLineErrorDiagnostic BufferLineGroupLabel BufferLineHint BufferLineHintDiagnostic BufferLineInfo "
			.. "BufferLineInfoDiagnostic BufferLineNumbers BufferLineTab BufferLineTabClose BufferLineTruncMarker "
			.. "BufferLineWarning BufferLineWarningDiagnostic",
		float_body = "BufferLineFill",
		float_hairline = "BufferLineOffsetSeparator BufferLineSeparator BufferLineTabSeparator",
		page_accent = "BufferLineHintDiagnosticSelected BufferLineHintSelected BufferLineInfoDiagnosticSelected "
			.. "BufferLineInfoSelected",
		page_quiet = "BufferLineCloseButtonSelected BufferLineDuplicateSelected BufferLineNumbersSelected",
		page_title = "BufferLineBufferSelected BufferLineTabSelected",
		page_warn = "BufferLineModifiedSelected BufferLineWarningDiagnosticSelected BufferLineWarningSelected",
		float_warn = "BufferLineModified BufferLineModifiedVisible",
	},
	barbar = {
		accent_bold = "BufferInactiveTarget BufferVisibleTarget BufferAlternateTarget",
		float_body = "BufferTabpage BufferTabpageFill BufferTabpages",
		float_hairline = "BufferAlternateSign BufferInactiveSign BufferTabpagesSep BufferVisibleSign",
		float_quiet = "BufferAlternate BufferAlternateIndex BufferInactive BufferInactiveIndex BufferVisibleIndex",
		float_strong = "BufferVisible",
		label = "BufferCurrentTarget",
		page_accent = "BufferCurrentSign",
		page_quiet = "BufferCurrentIndex",
		page_title = "BufferCurrent",
		page_warn = "BufferCurrentMod",
		float_warn = "BufferAlternateMod BufferInactiveMod BufferVisibleMod",
	},
	mini_tabline = {
		float_body = "MiniTablineFill MiniTablineTabpagesection",
		float_quiet = "MiniTablineHidden MiniTablineTrunc",
		float_strong = "MiniTablineVisible",
		float_warn = "MiniTablineModifiedHidden MiniTablineModifiedVisible",
		page_title = "MiniTablineCurrent",
		page_warn = "MiniTablineModifiedCurrent",
	},
	navic = {
		quiet = "NavicSeparator NavicText " .. kinds "NavicIcons%s",
	},
	dropbar = {
		accent_bold = "DropBarFzfMatch DropBarIconUIPickPivot",
		body = names_from("DropBarKind%s", dropbar_kind_names),
		quiet = "DropBarIconUIIndicator DropBarIconUISeparator DropbarDirPreviewLink DropbarDirPreviewTypeLink "
			.. "DropbarDirPreviewLinkTarget DropbarDirPreviewLinkTargetHidden DropbarDirPreviewSecurityContext DropbarDirPreviewSecurityExtended DropbarDirPreviewTypeFifo "
			.. directory_listing "Dir"
			.. " "
			.. directory_listing "Fifo"
			.. " "
			.. directory_listing "File"
			.. " "
			.. directory_listing "Link"
			.. " "
			.. directory_listing "Socket"
			.. " "
			.. kinds "DropBarIconKind%s"
			.. " "
			.. kinds "DropBarIconKind%sNC"
			.. " "
			.. names_from("DropBarIconKind%s", dropbar_statement_names),
		selected_strong = "DropBarCurrentContext DropBarHover DropBarMenuCurrentContext DropBarMenuHoverEntry",
		selected_accent = "DropBarMenuHoverIcon",
		selected_row = "DropBarMenuHoverSymbol DropBarPreview",
	},

	nvim_notify = {
		accent = "NotifyINFOIcon",
		body = "NotifyDEBUGBody NotifyERRORBody NotifyINFOBody NotifyTRACEBody NotifyWARNBody",
		error = "NotifyERRORIcon",
		float_body = "NotifyBackground",
		hairline = "NotifyDEBUGBorder NotifyERRORBorder NotifyINFOBorder NotifyTRACEBorder NotifyWARNBorder",
		quiet = "NotifyDEBUGIcon NotifyDEBUGTitle NotifyLogTime NotifyLogTitle NotifyTRACEIcon NotifyTRACETitle",
		strong = "NotifyERRORTitle NotifyINFOTitle NotifyWARNTitle",
		warn = "NotifyWARNIcon",
	},
	snacks_notifier = {
		float_body = "SnacksNotifierDebug SnacksNotifierError SnacksNotifierInfo SnacksNotifierTrace SnacksNotifierWarn",
		float_accent = "SnacksNotifierIconInfo",
		float_error = "SnacksNotifierIconError",
		float_hairline = "SnacksNotifierBorderDebug SnacksNotifierBorderError SnacksNotifierBorderInfo "
			.. "SnacksNotifierBorderTrace SnacksNotifierBorderWarn",
		float_quiet = "SnacksNotifierFooterDebug SnacksNotifierFooterError SnacksNotifierFooterInfo SnacksNotifierFooterTrace "
			.. "SnacksNotifierFooterWarn SnacksNotifierIconDebug SnacksNotifierIconTrace SnacksNotifierTitleDebug "
			.. "SnacksNotifierTitleTrace",
		float_strong = "SnacksNotifierTitleError SnacksNotifierTitleInfo SnacksNotifierTitleWarn",
		float_warn = "SnacksNotifierIconWarn",
	},
	snacks = {
		accent = "SnacksFooterKey SnacksInputIcon",
		added_line = "SnacksDiffAddLineNr",
		float_body = "SnacksInputNormal",
		float_hairline = "SnacksInputBorder",
		float_title = "SnacksInputTitle",
		hairline = "SnacksIndent SnacksIndentBlank " .. numbered("SnacksIndent%d", 1, 8),
		quiet = "SnacksFooter SnacksFooterDesc SnacksImageAnchor SnacksImageMath SnacksImageSpinner SnacksIndentChunk "
			.. "SnacksIndentScope SnacksNotifierHistoryDateTime SnacksWinBar SnacksWinBarNC SnacksWinKeyDesc",
		raised_fill = "SnacksDiffContext",
		raised_quiet = "SnacksDiffContextLineNr",
		raised_warn = "SnacksDiffConflictLineNr",
		removed_line = "SnacksDiffDelete SnacksDiffDeleteLineNr",
	},
	snacks_dashboard = {
		accent_bold = "SnacksDashboardKey SnacksDashboardSpecial",
		body = "SnacksDashboardDesc SnacksDashboardFile SnacksDashboardNormal SnacksDashboardTerminal",
		quiet = "SnacksDashboardDir SnacksDashboardFooter SnacksDashboardHeader SnacksDashboardIcon",
		strong = "SnacksDashboardTitle",
	},
	noice = {
		accent = "NoiceCmdlineIcon NoiceCmdlineIconSearch NoiceLspProgressSpinner "
			.. "NoiceCmdlineIconCalculator NoiceCmdlineIconCmdline NoiceCmdlineIconFilter NoiceCmdlineIconHelp "
			.. "NoiceCmdlineIconInput NoiceCmdlineIconLua",
		body = "NoiceCmdline NoiceCmdlinePrompt NoiceLspProgressTitle",
		float_body = "NoiceCmdlinePopup NoiceConfirm",
		float_hairline = "NoiceCmdlinePopupBorder NoiceCmdlinePopupBorderCalculator NoiceCmdlinePopupBorderCmdline "
			.. "NoiceCmdlinePopupBorderFilter NoiceCmdlinePopupBorderHelp NoiceCmdlinePopupBorderInput "
			.. "NoiceCmdlinePopupBorderLua NoiceCmdlinePopupBorderSearch NoiceConfirmBorder",
		float_quiet = "NoiceCmdlinePopupTitle NoiceCmdlinePopupTitleCalculator NoiceCmdlinePopupTitleCmdline "
			.. "NoiceCmdlinePopupTitleFilter NoiceCmdlinePopupTitleHelp NoiceCmdlinePopupTitleInput "
			.. "NoiceCmdlinePopupTitleLua NoiceCmdlinePopupTitleSearch",
		accent_bold = "NoicePopupmenuMatch",
		quiet = "NoiceFormatDate NoiceFormatEvent NoiceFormatKind NoiceLspProgressClient NoiceMini "
			.. kinds "NoiceCompletionItemKind%s",
		raised_fill = "NoiceFormatProgressTodo",
		selected_row = "NoiceFormatConfirmDefault NoiceFormatProgressDone",
	},
	fidget = {
		quiet = "FidgetTask",
		strong = "FidgetTitle",
	},
	undotree = {
		accent_bold = "UndotreeCurrent UndotreeNodeCurrent",
		body = "UndotreeHead UndotreeNext",
		quiet = "UndotreeBranch UndotreeFirstNode UndotreeHelp UndotreeHelpKey UndotreeHelpTitle UndotreeNode UndotreeSeq "
			.. "UndotreeTimeStamp",
		strong = "UndotreeSavedBig UndotreeSavedSmall",
	},
	mini_notify = {
		float_body = "MiniNotifyNormal",
		float_hairline = "MiniNotifyBorder",
		float_title = "MiniNotifyTitle",
	},

	which_key = {
		accent = "WhichKey",
		description = "WhichKeyDesc",
		float_hairline = "WhichKeyBorder",
		float_title = "WhichKeyTitle",
		group_label = "WhichKeyGroup",
		quiet = "WhichKeyIcon WhichKeyIconAzure WhichKeyIconBlue WhichKeyIconCyan WhichKeyIconGreen WhichKeyIconGrey "
			.. "WhichKeyIconOrange WhichKeyIconPurple WhichKeyIconRed WhichKeyIconYellow WhichKeySeparator WhichKeyValue",
	},
	mini_clue = {
		accent = "MiniClueNextKey MiniClueNextKeyWithPostkeys",
		float_hairline = "MiniClueBorder",
		description = "MiniClueDescSingle",
		float_title = "MiniClueTitle",
		group_label = "MiniClueDescGroup",
		hairline = "MiniClueSeparator",
	},
	harpoon = {
		float_body = "HarpoonWindow",
		float_hairline = "HarpoonBorder",
		float_title = "HarpoonTitle",
	},
	mason = {
		blue_bubble = "MasonHighlightBlockSecondary",
		blue_bubble_bold = "MasonHeaderSecondary MasonHighlightBlockBold",
		error = "MasonError",
		green = "MasonHighlight",
		green_bubble = "MasonHighlightBlock",
		magenta = "MasonHighlightSecondary",
		quiet = "MasonMuted",
		quiet_bubble = "MasonMutedBlock",
		violet_bold = "MasonHeading",
		violet_bubble_bold = "MasonHeader MasonHighlightBlockBoldSecondary",
		yellow_bubble_bold = "MasonMutedBlockBold",
	},
	grug_far = {
		accent_bold = "GrugFarResultsMatch",
		error = "GrugFarResultsRemoveIndicator GrugFarResultsMatchRemoved",
		added = "GrugFarResultsAddIndicator GrugFarResultsMatchAdded",
		quiet = "GrugFarHelpHeader GrugFarHelpHeaderKey GrugFarInputPlaceholder GrugFarResultsColumnNr "
			.. "GrugFarResultsHeader GrugFarResultsLineNr GrugFarResultsNumberLabel GrugFarResultsNumbersSeparator "
			.. "GrugFarResultsStats GrugFarResultsCmdHeader GrugFarHelpWinActionPrefix",
		selected_row = "GrugFarVisualBufrange",
		selected_strong = "GrugFarResultsCursorLineNo",
		selected_title = "GrugFarCurrentMatch",
		strong = "GrugFarResultsPath GrugFarInputLabel",
		title = "GrugFarHelpWinHeader",
		warn = "GrugFarResultsChangeIndicator",
	},

	dashboard = {
		accent = "DashboardKey DashboardShortCut DashboardShotCut",
		body = "DashboardCenter DashboardDesc DashboardFiles",
		quiet = "DashboardFooter DashboardHeader DashboardIcon",
		strong = "DashboardMruTitle DashboardProjectTitle",
	},
	alpha = {
		accent = "AlphaShortcut",
		body = "AlphaButtons",
		quiet = "AlphaFooter AlphaHeader AlphaHeaderLabel",
	},
	mini_starter = {
		accent = "MiniStarterItemPrefix",
		accent_bold = "MiniStarterQuery",
		body = "MiniStarterItem",
		hairline = "MiniStarterItemBullet",
		quiet = "MiniStarterFooter MiniStarterHeader MiniStarterInactive",
		selected_row = "MiniStarterCurrent",
		title = "MiniStarterSection",
	},

	render_markdown = {
		accent = "RenderMarkdownHint RenderMarkdownInfo RenderMarkdownLink RenderMarkdownLinkTitle RenderMarkdownWikiLink",
		error = "RenderMarkdownError",
		hairline = "RenderMarkdownDash RenderMarkdownIndent RenderMarkdownTableHead RenderMarkdownTableRow",
		heading_1 = "RenderMarkdownH1",
		heading_2 = "RenderMarkdownH2",
		heading_3 = "RenderMarkdownH3",
		heading_4 = "RenderMarkdownH4",
		heading_5 = "RenderMarkdownH5",
		heading_6 = "RenderMarkdownH6",
		ok = "RenderMarkdownChecked RenderMarkdownSuccess",
		quiet = "RenderMarkdownBullet RenderMarkdownCodeInfo RenderMarkdownMath RenderMarkdownQuote RenderMarkdownUnchecked "
			.. numbered("RenderMarkdownQuote%d", 1, 6),
		raised_fill = "RenderMarkdownCode RenderMarkdownCodeBorder",
		raised_body = "RenderMarkdownCodeInline RenderMarkdownInlineHighlight",
		warn = "RenderMarkdownTodo RenderMarkdownWarn",
	},
	markview = {
		accent = "MarkviewBlockQuoteNote MarkviewBlockQuoteSpecial MarkviewCheckboxProgress MarkviewEmail MarkviewHyperlink "
			.. "MarkviewImage",
		error = "MarkviewBlockQuoteError",
		float_body = "MarkviewBlockQuoteDefault",
		hairline = "MarkviewTableAlignCenter MarkviewTableAlignLeft MarkviewTableAlignRight MarkviewTableBorder "
			.. "MarkviewTableHeader "
			.. numbered("MarkviewGradient%d", 0, 9),
		ok = "MarkviewBlockQuoteOk",
		quiet = "MarkviewCheckboxCancelled MarkviewCheckboxChecked MarkviewCheckboxStriked MarkviewCodeFg "
			.. "MarkviewListItemMinus MarkviewListItemPlus MarkviewListItemStar "
			.. numbered("MarkviewIcon%d", 0, 7)
			.. " "
			.. numbered("MarkviewPalette%dSign", 0, 7),
		raised_fill = "MarkviewCode " .. numbered("MarkviewPalette%dBg", 0, 7),
		raised_heading_1 = "MarkviewHeading1 MarkviewHeading1Sign",
		raised_heading_2 = "MarkviewHeading2 MarkviewHeading2Sign",
		raised_heading_3 = "MarkviewHeading3 MarkviewHeading3Sign",
		raised_heading_4 = "MarkviewHeading4 MarkviewHeading4Sign",
		raised_heading_5 = "MarkviewHeading5 MarkviewHeading5Sign",
		raised_heading_6 = "MarkviewHeading6 MarkviewHeading6Sign",
		raised_quiet = "MarkviewCodeInfo",
		raised_body = "MarkviewInlineCode " .. numbered("MarkviewPalette%d", 0, 7),
		body = numbered("MarkviewPalette%dFg", 0, 7) .. " MarkviewCheckboxUnchecked",
		warn = "MarkviewBlockQuoteWarn MarkviewCheckboxPending",
	},
	headlines = {
		hairline = "Dash",
		quiet = "Quote",
		raised_fill = "CodeBlock",
		raised_heading_1 = "Headline Headline1",
		raised_heading_2 = "Headline2",
		raised_heading_3 = "Headline3",
		raised_heading_4 = "Headline4",
		raised_heading_5 = "Headline5",
		raised_heading_6 = "Headline6",
	},
	markdown_text = {
		heading_1 = "markdownH1",
		heading_2 = "markdownH2",
		heading_3 = "markdownH3",
		heading_4 = "markdownH4",
		heading_5 = "markdownH5",
		heading_6 = "markdownH6",
	},

	indent_guides = {
		hairline = "BlinkIndent IblIndent IblWhitespace IndentLine",
		quiet = "BlinkIndentScope IblScope IndentLineCurrent MiniIndentscopeSymbol",
	},
	jump_labels = {
		accent = "HopNextKey1 MiniJump2dSpotAhead",
		accent_bold = "FlashCurrent LeapMatch",
		float_quiet = "FlashPromptIcon",
		accent_bold_underlined = "LightspeedLabel LightspeedLabelDistant",
		body_bold = "LightspeedUnlabeledMatch",
		label = "Beacon FlashLabel HopNextKey LeapLabel LightspeedOneCharMatch LightspeedShortcut MiniJump2dSpot "
			.. "MiniJump2dSpotUnique PounceAccept PounceAcceptBest SneakCurrent SneakLabel WindowPickerStatusLine "
			.. "WindowPickerStatusLineNC WindowPickerWinBar WindowPickerWinBarNC",
		quiet = "FlashBackdrop HopUnmatched LeapBackdrop LeapLabelDimmed LightspeedMaskedChar MiniJump2dDim",
		raised_fill = "SneakScope",
		selected_strong = "FlashMatch HopPreview LightspeedPendingOpArea PounceGap PounceMatch Sneak SneakLabelMask",
		strong = "HopNextKey2",
	},
	illuminate = {
		selected_row = "IlluminatedWordRead IlluminatedWordText IlluminatedWordWrite",
	},
	mini_cursorword = {
		selected_strong = "MiniCursorword",
	},
	yanky = {
		selected_strong = "YankyPut YankyYanked",
	},
	artio = {
		accent = "ArtioMatch ArtioPrompt",
		body = "ArtioMark ArtioPointer",
		float_body = "ArtioNormal",
		raised_body_bold = "ArtioSel",
		selected_strong = "ArtioMarkLine",
	},
	todo_comments = {
		accent = "TodoFgNOTE TodoFgTODO TodoSignNOTE TodoSignTODO",
		error = "TodoFgFIX TodoSignFIX",
		quiet = "TodoFgPERF TodoFgTEST TodoSignPERF TodoSignTEST",
		raised_accent = "TodoBgNOTE TodoBgTODO",
		raised_body = "TodoBgPERF TodoBgTEST",
		raised_error = "TodoBgFIX",
		raised_warn = "TodoBgHACK TodoBgWARN",
		warn = "TodoFgHACK TodoFgWARN TodoSignHACK TodoSignWARN",
	},
	mini_hipatterns = {
		accent_bold = "MiniHipatternsNote MiniHipatternsTodo",
		error_bold = "MiniHipatternsFixme",
		warn_bold = "MiniHipatternsHack",
	},
	gitsigns = {
		added_inline = "GitSignsAddInline GitSignsAddLnInline",
		added_line = "GitSignsAddPreview",
		quiet = "GitSignsNoEOLPreview",
		removed_inline = "GitSignsDeleteInline GitSignsDeleteLnInline GitSignsDeleteVirtLnInLine",
		removed_filler = "GitSignsVirtLnum",
		changed_inline = "GitSignsChangeInline GitSignsChangeLnInline",
		removed_line = "GitSignsDeletePreview GitSignsDeleteVirtLn",
	},

	nvim_dap = {
		accent = "DapLogPoint",
		error = "DapBreakpoint",
		quiet = "DapBreakpointRejected",
		warn = "DapBreakpointCondition DapStopped",
	},
	nvim_dap_ui = {
		accent_bold = "DapUIBreakpointsCurrentLine DapUICurrentFrameName DapUIStoppedThread DapUIWinSelect",
		body = "DapUIBreakpointsInfo DapUIDecoration DapUIFrameName DapUIValue DapUIVariable DapUIWatchesValue",
		error = "DapUIStop DapUIStopNC DapUIWatchesError",
		float_hairline = "DapUIFloatBorder",
		ok = "DapUIPlayPause DapUIPlayPauseNC",
		quiet = "DapUIBreakpointsDisabledLine DapUIBreakpointsLine DapUILineNumber DapUIRestart DapUIRestartNC DapUISource "
			.. "DapUIStepBack DapUIStepBackNC DapUIStepInto DapUIStepIntoNC DapUIStepOut DapUIStepOutNC DapUIStepOver "
			.. "DapUIStepOverNC DapUIType DapUIUnavailable DapUIUnavailableNC DapUIWatchesEmpty",
		strong = "DapUIBreakpointsPath DapUIThread",
		title = "DapUIScope",
		warn_bold = "DapUIModifiedValue",
	},
	neotest = {
		accent = "NeotestMarked NeotestTarget NeotestWinSelect",
		body = "NeotestFile NeotestNamespace NeotestTest",
		bold = "NeotestFocused",
		error = "NeotestFailed",
		hairline = "NeotestExpandMarker NeotestIndent",
		ok = "NeotestPassed",
		quiet = "NeotestSkipped NeotestUnknown",
		strong = "NeotestAdapterName NeotestDir",
		warn = "NeotestRunning NeotestWatching",
	},
	overseer = {
		accent = "OverseerRUNNING",
		body = "OverseerOutput OverseerTask",
		error = "OverseerFAILURE",
		faint = "OverseerTaskBorder",
		ok = "OverseerSUCCESS",
		quiet = "OverseerCANCELED OverseerComponent OverseerDISPOSED OverseerField OverseerPENDING",
	},

	trouble = {
		float_body = "TroubleNormal TroubleNormalNC",
		hairline = "TroubleIndent TroubleIndentFoldOpen TroubleIndentLast TroubleIndentMiddle TroubleIndentTop "
			.. "TroubleIndentWs",
		accent = "TroubleBasename TroubleDirectory TroubleFilename TroubleFsBasename TroubleFsFilename",
		body = "TroubleText",
		quiet = "TroubleCode TroubleCount TroubleFsCount TroubleFsPos TroubleFsSource TroubleIconDirectory "
			.. "TroubleIndentFoldClosed TroublePos TroubleSource "
			.. kinds "TroubleIcon%s",
		raised_fill = "TroublePreview",
	},
	lsp_saga = {
		accent = "SagaInCurrent SagaSelect SagaSpinner SagaSpinnerTitle",
		body = "ActionFix CodeActionText DiagnosticText RenameNormal",
		page_title = "ActionPreviewTitle",
		float_body = "SagaNormal",
		float_hairline = "SagaBorder",
		quiet = "CodeActionNumber SagaCount SagaDetail SagaFileName SagaImpIcon SagaFinderFname SagaFolderName SagaToggle SagaWinbarFileName "
			.. "SagaWinbarFolderName SagaWinbarFolder SagaSep SagaWinbarSep SagaMacro "
			.. kinds "Saga%s",
		raised_fill = "SagaBeacon SagaSearch",
		title = "SagaTitle",
		warn = "SagaLightBulb",
		hairline = "SagaVirtLine",
	},
	treesitter_context = {
		hairline = "TreesitterContextSeparator",
	},
	ufo = {
		raised_fill = "UfoPreviewSbar",
		thumb = "UfoPreviewThumb",
	},
	octo = {
		accent = "OctoStateMerged OctoStateMergedFloat",
		added = "OctoPullAdditions",
		added_line = "OctoReviewDiffAddText",
		blue = "OctoBlue OctoBubbleDelimiterBlue",
		blue_bubble = "OctoBubbleBlue",
		body = "OctoDetailsValue OctoNormalFront OctoStateCommented OctoStateCommentedFloat",
		green = "OctoBubbleDelimiterGreen OctoGreen",
		green_bubble = "OctoBubbleGreen",
		page_blue = "OctoBlueFloat",
		page_body = "OctoBubble OctoBubbleGrey OctoGreyFloat",
		page_green = "OctoGreenFloat",
		page_ink = "OctoBubbleDelimiterGrey OctoGrey",
		page_red = "OctoRedFloat",
		page_violet = "OctoPurpleFloat",
		page_yellow = "OctoYellowFloat",
		plain = "OctoFilePanelFileName",
		raised_body = "OctoViewer",
		red = "OctoBubbleDelimiterRed OctoRed",
		red_bubble = "OctoBubbleRed",
		violet = "OctoBubbleDelimiterPurple OctoPurple",
		violet_bubble = "OctoBubblePurple",
		yellow = "OctoBubbleDelimiterYellow OctoYellow",
		yellow_bubble = "OctoBubbleYellow",
		error = "OctoDirty OctoFailingTest OctoPullDeletions OctoStateChangesRequested OctoStateChangesRequestedFloat "
			.. "OctoStateClosed OctoStateClosedFloat OctoStateDismissed OctoStateDismissedFloat",
		ok = "OctoPassingTest OctoStateApproved OctoStateApprovedFloat OctoStateOpen OctoStateOpenFloat",
		removed_line = "OctoReviewDiffDeleteText",
		quiet = "OctoDate OctoEmpty OctoFilePanelCounter OctoIssueId OctoMissingDetails OctoSymbol OctoTimelineItemHeading",
		title = "OctoDetailsLabel OctoFilePanelTitle OctoIssueTitle",
		warn = "OctoPullModifications OctoStatePending OctoStatePendingFloat",
	},
	avante = {
		body = "AvanteReversedSubtitle AvanteSubtitle",
		float_accent = "AvanteConflictIncoming AvanteConflictIncomingLabel",
		float_error = "AvanteToBeDeleted",
		float_ok = "AvanteConflictCurrent AvanteConflictCurrentLabel",
		float_quiet = "AvanteConflictAncestor AvanteConflictAncestorLabel",
		ghost = "AvanteAnnotation AvanteInlineHint AvantePopupHint AvanteSuggestion",
		title = "AvanteReversedThirdTitle AvanteReversedTitle AvanteThirdTitle AvanteTitle",
	},
	git_graph = {
		blue = "GitGraphBranch3",
		body = "GitGraphAuthor GitGraphBranchMsg",
		green = "GitGraphBranch4",
		red = "GitGraphBranch5",
		violet = "GitGraphBranch2",
		yellow = "GitGraphBranch1",
		quiet = "GitGraphBranchTag GitGraphHash GitGraphTimestamp",
		strong = "GitGraphBranchName",
	},
	buffon = {
		accent = "BuffonShortcut",
		strong = "BuffonLineActive",
		warn = "BuffonUnsavedIndicator",
	},
	operator_sandwich = {
		selected_strong = "OperatorSandwichAdd OperatorSandwichBuns OperatorSandwichChange OperatorSandwichDelete",
	},
	colorful_winsep = {
		accent = "ColorfulWinSep",
	},
	symbols_outline = {
		accent = "FocusedSymbol",
	},
	blink_indent = {
		blue = "BlinkIndentBlue",
		blue_underline = "BlinkIndentBlueUnderline",
		cyan = "BlinkIndentCyan",
		cyan_underline = "BlinkIndentCyanUnderline",
		green = "BlinkIndentGreen",
		green_underline = "BlinkIndentGreenUnderline",
		orange = "BlinkIndentOrange",
		orange_underline = "BlinkIndentOrangeUnderline",
		red = "BlinkIndentRed",
		red_underline = "BlinkIndentRedUnderline",
		violet = "BlinkIndentViolet",
		violet_underline = "BlinkIndentVioletUnderline",
		yellow = "BlinkIndentYellow",
		yellow_underline = "BlinkIndentYellowUnderline",
	},
	blink_pairs = {
		blue = "BlinkPairsBlue",
		cyan = "BlinkPairsCyan",
		error = "BlinkPairsUnmatched",
		green = "BlinkPairsGreen",
		orange = "BlinkPairsOrange",
		red = "BlinkPairsRed",
		violet = "BlinkPairsPurple",
		yellow = "BlinkPairsYellow",
	},
	rainbow = {
		blue = "rainbowcol4 rainbowcol6 TSRainbowBlue",
		cyan = "rainbowcol2 TSRainbowCyan",
		green = "rainbowcol7 TSRainbowGreen",
		orange = "TSRainbowOrange",
		red = "rainbowcol1 TSRainbowRed",
		violet = "rainbowcol5 TSRainbowViolet",
		yellow = "RainbowDelimiterYellow rainbowcol3 TSRainbowYellow",
	},
	coc_nvim = {
		accent_bold = "CocPumSearch",
		ghost_italic = "CocInlayHint",
	},
	copilot_vim = {
		body = "CopilotAnnotation",
		ghost = "CopilotSuggestion",
	},
	dadbod_ui = {
		float_accent = "NotificationInfo",
		float_error = "NotificationError",
		float_warn = "NotificationWarning",
	},
	fern = {
		body = "FernBranchText",
	},
	notifier = {
		body_italic_opaque = "NotifierContent",
		ghost_italic_opaque = "NotifierContentDim",
		quiet = "NotifierIcon",
	},
	signify = {
		added = "SignifySignAdd",
		error = "SignifySignDelete",
		warn = "SignifySignChange",
	},
	telekasten = {
		accent = "tkLink",
		body = "tkBrackets tkTag",
	},
	vimwiki = {
		accent = "VimwikiLink",
		body = "VimwikiHR VimwikiList VimwikiMarkers VimwikiTag",
		ghost = "VimwikiHeaderChar",
		title = "VimwikiHeader1 VimwikiHeader2 VimwikiHeader3 VimwikiHeader4 VimwikiHeader5 VimwikiHeader6",
	},
	lazy = {
		body = "LazyTaskOutput",
		hairline = "LazyProgressTodo",
		quiet = "LazyDimmed LazyProp",
	},
	mini_diff = {
		changed_inline = "MiniDiffOverChange MiniDiffOverChangeBuf",
		removed_line = "MiniDiffOverDelete",
	},
	lsp_kinds = {
		quiet = kinds "LspKind%s",
	},
}

M.links = {
	AvantePromptInput = "NormalFloat",
	AvantePromptInputBorder = "FloatBorder",
	AvanteSidebarWinSeparator = "WinSeparator",
	BlinkPairsMatchParen = "MatchParen",
	CocMenuSel = "PmenuSel",
	LazyButton = "CursorLine",
	LazyButtonActive = "Visual",
	LazyH1 = "IncSearch",
	LazyNormal = "NormalFloat",
	LazyReasonEvent = "Constant",
	LazyReasonStart = "@variable.member",
	LightspeedCursor = "Cursor",
	LightspeedGreyWash = "Comment",
	LightspeedUniqueChar = "LightspeedUnlabeledMatch",
	LirFloatCursorLine = "CursorLine",
	MasonNormal = "NormalFloat",
	NvimSeparator = "ColorfulWinSep",
	NvimSurroundHighlight = "Visual",
	OctoCommentLine = "TabLineSel",
	OctoDiffHunkPosition = "NormalFloat",
	OctoFloat = "NormalNC",
	OctoReaction = "OctoBubble",
	OctoReactionViewer = "OctoViewer",
	OctoStateSubmittedBubble = "OctoBubbleGreen",
	OctoUser = "OctoBubble",
	OctoUserViewer = "OctoViewer",
	OutlineCurrent = "FocusedSymbol",
	RenameMatch = "Search",
	SnacksBackdrop = "FloatShadow",
	SnacksNormal = "Normal",
	SnacksNormalNC = "NormalFloat",
}

local function add_family(groups, family_name, look)
	for role, names in pairs(M.families[family_name]) do
		local hl = look[role]
			or error(string.format("the %s family names %s, which is not a look", family_name, role), 0)
		for name in names:gmatch "%S+" do
			groups[name] = hl
		end
	end
end

local function names_in_lowercase(groups)
	local names = {}
	for name in pairs(groups) do
		names[name:lower()] = true
	end

	return names
end

function M.groups(background)
	local look = looks(background)

	local groups = {}
	for family_name in pairs(M.families) do
		add_family(groups, family_name, look)
	end

	local in_a_family = names_in_lowercase(groups)
	for name, target in pairs(M.links) do
		if in_a_family[name:lower()] then error(name .. " is both in a family and a link", 0) end
		groups[name] = { link = target }
	end

	return groups
end

function M.family_groups(background, family_name)
	local groups = {}
	add_family(groups, family_name, looks(background))

	return groups
end

return M
