---@class Stack
---@field items string[]
---@field limit integer
---@field name string
---@field depth integer
---@field [string] integer|string
local Stack = {}
Stack.__index = Stack

local defaults = { limit = 10, name = "stack", tags = { "core", { "nested", { "deep", { "deeper" } } } } }

---@param options? { limit?: integer, name?: string }
---@return Stack
function Stack.new(options)
  local self = setmetatable({ items = {} }, Stack)
  ---@type table<string, integer|string|(string|table)[]>
  local merged = vim.tbl_extend("force", defaults, options or {})
  for key, value in pairs(merged) do
    if type(value) == "table" then
      for index, entry in ipairs(value) do
        if type(entry) == "table" then
          self[key .. index], self.depth = #entry > 0 and entry[1] or ((index + 1) * (index - 1)), index
        end
      end
    else
      self[key] = value
    end
  end
  return self
end

---@param item string
function Stack:push(item)
  if #self.items >= self.limit then error(string.format("stack %s is full at %d", self.name, #self.items)) end
  table.insert(self.items, item)
end

---@return string?
function Stack:pop() return table.remove(self.items) end

local stack = Stack.new { limit = 3 }
stack:push "first"
print(stack:pop())

return Stack
