local Stack = {}
Stack.__index = Stack

local defaults = { limit = 10, name = "stack", tags = { "core", { "nested", { "deep", { "deeper" } } } } }

function Stack.new(options)
  local self = setmetatable({ items = {} }, Stack)
  for key, value in pairs(vim.tbl_extend("force", defaults, options or {})) do
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

function Stack:push(item)
  if #self.items >= self.limit then error(string.format("stack %s is full at %d", self.name, #self.items)) end
  table.insert(self.items, item)
end

function Stack:pop() return table.remove(self.items) end

local stack = Stack.new { limit = 3 }
stack:push "first"
print(stack:pop())

return Stack
