local M = {}

local function windows() return vim.api.nvim_tabpage_list_wins(0) end

function M.shows(filetype)
	return vim.iter(windows())
		:any(function(window) return vim.bo[vim.api.nvim_win_get_buf(window)].filetype == filetype end)
end

local function chunks_draw(chunks, group)
	return vim.iter(chunks or {})
		:any(function(chunk) return vim.list_contains(vim.iter({ chunk[2] }):flatten():totable(), group) end)
end

local function mark_draws(mark, group)
	local details = mark[4]
	return details.hl_group == group or details.sign_hl_group == group or chunks_draw(details.virt_text, group)
end

local function window_draws(window, group)
	local marks = vim.api.nvim_buf_get_extmarks(vim.api.nvim_win_get_buf(window), -1, 0, -1, { details = true })
	local matches = vim.fn.getmatches(window)

	return vim.iter(marks):any(function(mark) return mark_draws(mark, group) end)
		or vim.iter(matches):any(function(match) return match.group == group end)
end

local function bar_draws(bar, opts, group)
	if bar == "" then return false end

	local highlights =
		vim.api.nvim_eval_statusline(bar, vim.tbl_extend("force", opts, { highlights = true })).highlights

	return vim.iter(highlights):any(function(highlight) return vim.list_contains(highlight.groups, group) end)
end

function M.bordered(filetype)
	return vim.iter(windows()):any(function(window)
		local border = vim.api.nvim_win_get_config(window).border
		return vim.bo[vim.api.nvim_win_get_buf(window)].filetype == filetype and type(border) == "table"
	end)
end

function M.shows_the_last_line() return vim.fn.line "w$" == vim.fn.line "$" end

function M.tabline_holds(text)
	return vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true }).str:find(text, 1, true) ~= nil
end

function M.draws(group)
	return vim.iter(windows()):any(function(window) return window_draws(window, group) end)
		or bar_draws(vim.o.tabline, { use_tabline = true }, group)
		or bar_draws(vim.o.statusline, {}, group)
		or bar_draws(vim.wo.winbar, { use_winbar = true }, group)
end

return M
