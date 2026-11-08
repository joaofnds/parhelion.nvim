local M = {}

M.color_attributes = { "fg", "bg", "sp" }

M.tones = {
	dark = {
		["#0c4e53"] = "#0b474c",
		["#268bd2"] = "#40a0e8",
		["#586e75"] = "#71888f",
		["#6c71c4"] = "#8188dd",
		["#839496"] = "#93a1a1",
		["#93a1a1"] = "#a3b1b1",
		["#b58900"] = "#c1951e",
		["#cb4b16"] = "#e56824",
		["#d33682"] = "#ef5299",
		["#dc322f"] = "#f95148",
	},
	light = {
		["#268bd2"] = "#117fc5",
		["#2aa198"] = "#018880",
		["#586e75"] = "#4c6168",
		["#657b83"] = "#586e75",
		["#6c71c4"] = "#6165b7",
		["#839496"] = "#728284",
		["#859900"] = "#708101",
		["#93a1a1"] = "#798686",
		["#b58900"] = "#997401",
		["#cb4b16"] = "#b74a00",
	},
}

local bold = { bold = true }

local foregrounds_taken_from_a_group = {
	BuffonUnloadedBuffer = { source = "Comment" },
	LspInlayHint = { source = "Comment" },
	NeogitGraphBoldGray = { source = "Comment", style = bold },
	NeogitGraphBoldWhite = { source = "Normal", style = bold },
	NeogitGraphGray = { source = "Comment" },
	NeogitGraphWhite = { source = "Normal" },
	OkMsg = { source = "DiagnosticOk" },
}

local links = {
	fzf1 = "StatusLine",
	fzf2 = "StatusLine",
	fzf3 = "StatusLine",
}

local literal_groups = {
	dark = {},
	light = {
		LineNr = { fg = "#6c7c80", bg = "#eee8d5" },
		NonText = { fg = "#728284" },
		Whitespace = { fg = "#728284" },
	},
}

function M.color(background, color) return M.tones[background][color:lower()] or color end

function M.highlight(background, hl)
	local refined = vim.tbl_extend("force", {}, hl)
	for _, attribute in ipairs(M.color_attributes) do
		if hl[attribute] then refined[attribute] = M.color(background, hl[attribute]) end
	end

	return refined
end

local function foreground_of(background, base_groups, name)
	local hl = base_groups[name]
	while hl.link do
		hl = base_groups[hl.link]
	end

	return M.color(background, hl.fg)
end

function M.repaired_groups(background, base_groups)
	local repaired = vim.deepcopy(literal_groups[background])

	for name, spec in pairs(foregrounds_taken_from_a_group) do
		repaired[name] = vim.tbl_extend("force", spec.style or {}, {
			fg = foreground_of(background, base_groups, spec.source),
		})
	end

	for name, target in pairs(links) do
		repaired[name] = { link = target }
	end

	return repaired
end

return M
