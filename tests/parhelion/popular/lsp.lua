-- In-process language server: symbols of every kind, hover, references, and diagnostics of every severity.
---@param line integer
---@param first integer
---@param last integer
---@return lsp.Range
local function range(line, first, last)
  return { start = { line = line, character = first }, ["end"] = { line = line, character = last } }
end

local symbols = {}
for kind = 1, 26 do
  ---@type string
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
    selectionRange = range(0, 10, 15),
    children = {
      {
        name = "new",
        kind = 9,
        range = { start = { line = 13, character = 0 }, ["end"] = { line = 32, character = 3 } },
        selectionRange = range(13, 15, 18),
        children = symbols,
      },
      {
        name = "push",
        kind = 6,
        range = { start = { line = 33, character = 0 }, ["end"] = { line = 39, character = 3 } },
        selectionRange = range(33, 15, 19),
      },
      {
        name = "pop",
        kind = 6,
        range = { start = { line = 40, character = 0 }, ["end"] = { line = 42, character = 3 } },
        selectionRange = range(40, 15, 18),
      },
    },
  },
}

---@param method string
---@param params { textDocument: { uri: string } }
---@return table?
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
    return { { uri = params.textDocument.uri, range = range(33, 15, 19) } }
  end
  if method == "textDocument/references" then
    return {
      { uri = params.textDocument.uri, range = range(33, 15, 19) },
      { uri = params.textDocument.uri, range = range(45, 6, 10) },
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
      lnum = 17,
      col = 6,
      end_col = 11,
      severity = vim.diagnostic.severity.ERROR,
      message = "value may be nil here",
      source = "gallery",
    },
    {
      lnum = 20,
      col = 8,
      end_col = 13,
      severity = vim.diagnostic.severity.WARN,
      message = "unused variable index",
      source = "gallery",
    },
    {
      lnum = 33,
      col = 15,
      end_col = 19,
      severity = vim.diagnostic.severity.INFO,
      message = "push is documented",
      source = "gallery",
    },
    {
      lnum = 28,
      col = 2,
      end_col = 8,
      severity = vim.diagnostic.severity.HINT,
      message = "consider renaming",
      source = "gallery",
    },
  })
end

return { start = start, diagnostics = diagnostics }
