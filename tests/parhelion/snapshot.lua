---@alias snapshot.Group parhelion.Highlight

---@class snapshot.Snapshot
---@field background parhelion.Background
---@field groups table<string, snapshot.Group>
---@field links table<string, string>
---@field terminal table<string, string|vim.NIL>

---@alias snapshot.Attributes table<string, integer|string|boolean|table|nil>

---@param n? integer
---@return string?
local function hex(n) return n and string.format("#%06x", n) or nil end

---@param name string
---@return vim.api.keyset.get_hl_info
local function resolve(name)
  ---@type table<string, true>, string
  local seen, current = {}, name
  while true do
    local hl = vim.api.nvim_get_hl(0, { name = current })
    local link = hl.link
    if not link then return hl end
    assert(not seen[current], "link cycle at " .. current)
    seen[current] = true
    current = link
  end
end

---@param name string
---@return snapshot.Attributes
local function resolved_group(name)
  local hl = resolve(name)
  ---@type snapshot.Attributes, table<string, integer|string|boolean|table>
  local out, attributes = {}, hl

  for key, value in pairs(attributes) do
    if key ~= "fg" and key ~= "bg" and key ~= "sp" and key ~= "default" then out[key] = value end
  end
  out.fg, out.bg, out.sp = hex(hl.fg), hex(hl.bg), hex(hl.sp)

  return out
end

---@type table<string, snapshot.Attributes>, table<string, string>
local groups, links = {}, {}
---@type table<string, vim.api.keyset.get_hl_info>
local definitions = vim.api.nvim_get_hl(0, {})
for name, hl in pairs(definitions) do
  groups[name] = resolved_group(name)
  links[name] = hl.link
end

---@type table<string, string|vim.NIL>
local terminal = {}
for i = 0, 15 do
  ---@type string?
  local color = vim.g["terminal_color_" .. i]
  terminal[tostring(i)] = color and color:lower() or vim.NIL
end

return vim.json.encode { background = vim.o.background, groups = groups, links = links, terminal = terminal }
