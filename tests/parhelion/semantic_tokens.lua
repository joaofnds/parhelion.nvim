local function identifier_tokens(lines)
	local data, previous_row, previous_col = {}, 0, 0
	for index, line in ipairs(lines) do
		for position, word in line:gmatch "()([%a_][%w_]*)" do
			local row, col = index - 1, position - 1
			local col_delta = row == previous_row and col - previous_col or col
			vim.list_extend(data, { row - previous_row, col_delta, #word, 0, 0 })
			previous_row, previous_col = row, col
		end
	end
	return data
end

local function respond(method, params)
	if method == "initialize" then
		return {
			capabilities = {
				textDocumentSync = 1,
				semanticTokensProvider = { legend = { tokenTypes = { "type" }, tokenModifiers = {} }, full = true },
			},
		}
	end

	if method == "textDocument/semanticTokens/full" then
		local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
		return { data = identifier_tokens(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) }
	end
end

local request_count = 0

vim.lsp.start {
	name = "parhelion-semantic-tokens",
	root_dir = vim.fn.getcwd(),
	cmd = function()
		return {
			request = function(method, params, callback)
				request_count = request_count + 1
				local request_id = request_count
				vim.schedule(function() callback(nil, respond(method, params), request_id) end)
				return true, request_id
			end,
			notify = function() return true end,
			is_closing = function() return false end,
			terminate = function() end,
		}
	end,
}
