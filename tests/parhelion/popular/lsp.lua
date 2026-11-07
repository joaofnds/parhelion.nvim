-- In-process language server: symbols of every kind, hover, references, and diagnostics of every severity.
local function range(line, first, last)
	return { start = { line = line, character = first }, ["end"] = { line = line, character = last } }
end

local symbols = {}
for kind = 1, 26 do
	local name = vim.lsp.protocol.SymbolKind[kind]
	table.insert(
		symbols,
		{ name = name .. "Symbol", kind = kind, range = range(kind, 0, 30), selectionRange = range(kind, 0, 8) }
	)
end
symbols = {
	{
		name = "Stack",
		kind = 5,
		range = range(0, 0, 200),
		selectionRange = range(0, 6, 11),
		children = {
			{
				name = "new",
				kind = 9,
				range = { start = { line = 5, character = 0 }, ["end"] = { line = 21, character = 3 } },
				selectionRange = range(5, 15, 18),
				children = symbols,
			},
			{
				name = "push",
				kind = 6,
				range = { start = { line = 22, character = 0 }, ["end"] = { line = 27, character = 3 } },
				selectionRange = range(22, 15, 19),
			},
			{
				name = "pop",
				kind = 6,
				range = { start = { line = 28, character = 0 }, ["end"] = { line = 30, character = 3 } },
				selectionRange = range(28, 15, 18),
			},
		},
	},
}

local function respond(method, params)
	if method == "initialize" then
		return {
			capabilities = {
				textDocumentSync = 1,
				documentSymbolProvider = true,
				hoverProvider = true,
				referencesProvider = true,
				definitionProvider = true,
				implementationProvider = true,
				codeActionProvider = true,
				renameProvider = true,
				callHierarchyProvider = true,
			},
		}
	end
	if method == "textDocument/documentSymbol" then return symbols end
	if method == "textDocument/hover" then
		return {
			contents = {
				kind = "markdown",
				value = "```lua\nfunction Stack:push(item: any)\n```\n\nPushes **item** onto the stack, and raises when `limit` is reached.\n\n---\n\n- `item` the value to push",
			},
		}
	end
	if method == "textDocument/definition" or method == "textDocument/implementation" then
		return { { uri = params.textDocument.uri, range = range(22, 15, 19) } }
	end
	if method == "textDocument/references" then
		return {
			{ uri = params.textDocument.uri, range = range(22, 15, 19) },
			{ uri = params.textDocument.uri, range = range(33, 6, 10) },
		}
	end
	if method == "textDocument/codeAction" then
		return {
			{ title = "Extract into a function", kind = "refactor.extract" },
			{ title = "Add missing annotation", kind = "quickfix" },
		}
	end
	return nil
end

local count = 0
local function start()
	return vim.lsp.start {
		name = "gallery-lsp",
		root_dir = vim.fn.getcwd(),
		cmd = function()
			return {
				request = function(method, params, callback)
					count = count + 1
					local id = count
					vim.schedule(function() callback(nil, respond(method, params), id) end)
					return true, id
				end,
				notify = function() return true end,
				is_closing = function() return false end,
				terminate = function() end,
			}
		end,
	}
end

local function diagnostics(bufnr)
	local namespace = vim.api.nvim_create_namespace "gallery"
	vim.diagnostic.set(namespace, bufnr, {
		{
			lnum = 7,
			col = 6,
			end_col = 11,
			severity = vim.diagnostic.severity.ERROR,
			message = "value may be nil here",
			source = "gallery",
		},
		{
			lnum = 10,
			col = 8,
			end_col = 13,
			severity = vim.diagnostic.severity.WARN,
			message = "unused variable index",
			source = "gallery",
		},
		{
			lnum = 22,
			col = 15,
			end_col = 19,
			severity = vim.diagnostic.severity.INFO,
			message = "push is documented",
			source = "gallery",
		},
		{
			lnum = 34,
			col = 0,
			end_col = 5,
			severity = vim.diagnostic.severity.HINT,
			message = "consider renaming",
			source = "gallery",
		},
	})
end

return { start = start, diagnostics = diagnostics }
