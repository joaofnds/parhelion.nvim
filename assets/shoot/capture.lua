-- Drives a sandboxed Neovim through the suite's UI driver and writes each screen the README shows as an HTML page.
local root, deps, project = vim.env.PARHELION_ROOT, vim.env.PARHELION_DEPS, vim.env.SHOOT_PROJECT
local out, font = arg[1], vim.env.SHOOT_FONT
local Nvim = dofile(root .. "/tests/parhelion/driver.lua")

local function command(nvim, text) nvim:request("nvim_command", text) end

local function wait_for(nvim, condition)
  nvim:settle { quiet = 400, timeout = 30000, until_lua = "return " .. condition }
end

local function editor(nvim)
  command(nvim, "edit src/forecast.ts | badd src/units.ts | badd src/cache.ts")
  command(nvim, "NvimTreeFindFile | wincmd p")
  wait_for(nvim, "(vim.b.gitsigns_status_dict or {}).added ~= nil")
  wait_for(
    nvim,
    [[vim.iter(vim.api.nvim_buf_get_extmarks(vim.fn.bufnr "NvimTree_1", -1, 0, -1, { details = true })):any(
			function(mark) return tostring(mark[4].hl_group):find "^NvimTreeGit" ~= nil end
		)]]
  )

  nvim:lua [[
		local namespace = vim.api.nvim_create_namespace "shoot"
		local line = vim.fn.search("const body", "n") - 1
		vim.diagnostic.set(namespace, 0, {
			{
				lnum = line,
				col = 8,
				end_col = 12,
				severity = vim.diagnostic.severity.WARN,
				source = "eslint",
				message = "Unsafe assignment of an `any` value.",
			},
		})

		vim.fn.search "convert("
	]]
  nvim:lua [[
		vim.lsp.util.open_floating_preview({
			"```typescript",
			"function convert(celsius: number, unit: Unit): number",
			"```",
			"Converts a temperature in degrees Celsius to the given unit.",
		}, "markdown", { border = "rounded", focus = false, close_events = {} })
	]]
end

local function diff(nvim)
  command(nvim, "DiffviewOpen")
  wait_for(nvim, "#vim.tbl_filter(function(w) return vim.wo[w].diff end, vim.api.nvim_tabpage_list_wins(0)) == 2")
  command(nvim, "DiffviewToggleFiles")
  command(nvim, "set showtabline=0")
end

local scenes = {
  { name = "editor", cols = 118, rows = 36, run = editor },
  { name = "diff", cols = 156, rows = 30, run = diff },
}

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

local function style_of(cell, cursor)
  local fg, bg = cell.fg, cell.bg
  local flags = {}
  for flag in cell.flags:gmatch "[^,]+" do
    flags[flag] = true
  end
  if flags.reverse then
    fg, bg = bg, fg
  end
  if cursor then
    fg, bg = cursor.fg or bg, cursor.bg or fg
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

local function escape(text) return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end

local function row_html(cells, cursor_col, cursor)
  local parts, first = {}, 1
  while first <= #cells do
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

local function page(shot, cursor)
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

vim.fn.mkdir(out, "p")
for _, scene in ipairs(scenes) do
  for _, mode in ipairs { "dark", "light" } do
    local nvim = Nvim.spawn {
      args = { "-u", root .. "/assets/shoot/init.lua", "-i", "NONE", "-n" },
      cwd = project,
      rows = scene.rows,
      cols = scene.cols,
      env = { PARHELION_ROOT = root, PARHELION_DEPS = deps, SHOOT_MODE = mode },
    }
    local ok, err = pcall(function()
      scene.run(nvim)
      local shot = nvim:capture()
      local cursor = nvim:lua [[
				local hl = vim.api.nvim_get_hl(0, { name = "Cursor", link = false })
				local function hex(n) return n and string.format("#%06x", n) or nil end
				return { fg = hex(hl.fg), bg = hex(hl.bg) }
			]]
      local path = string.format("%s/%s-%s.html", out, scene.name, mode)
      vim.fn.writefile({ page(shot, cursor) }, path)
      print(path)
    end)
    nvim:close()
    if not ok then error(string.format("%s in %s: %s", scene.name, mode, err), 0) end
  end
end
