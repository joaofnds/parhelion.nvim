-- sample module
local M = { name = "sample", retries = 3, enabled = true }

---@param items string[]
---@return table<string, number>
function M.count(items)
  ---@type table<string, number>
  local seen = {}
  for _, item in ipairs(items) do
    seen[item] = (seen[item] or 0) + 1
  end
  return seen
end

local function greet(person)
  if person == nil then error("no person: " .. tostring(person)) end
  print(string.format("hello %s", person:upper()))
  return vim.tbl_keys { a = 1, b = 2.5 }
end

M.greet = greet
return setmetatable(M, { __index = function(_, key) return key end })
