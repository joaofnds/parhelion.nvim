local M = {}

---@alias parhelion.Groups table<string, vim.api.keyset.highlight>

---@class parhelion.Options
---@field transparent boolean
---@field dim_inactive boolean
---@field bold boolean
---@field italic boolean
---@field overrides parhelion.Groups|fun(colors: table<string, string>): parhelion.Groups
---@field plugins table<string, boolean>

---@class (partial) parhelion.UserOptions: parhelion.Options

---@alias parhelion.Background "dark"|"light"

---@class parhelion.Highlight: vim.api.keyset.highlight
---@field fg? string
---@field bg? string
---@field sp? string
---@field link? string

---@class parhelion.Base
---@field terminal string[]
---@field groups table<string, parhelion.Highlight>

---@class parhelion.Built
---@field colors table<string, string>
---@field mode_hues table<string, string>
---@field dimmed string
---@field transparent_clears string[]
---@field terminal string[]
---@field groups table<string, parhelion.Highlight>

---@alias parhelion.Changes table<string, vim.api.keyset.highlight|false>

---@type parhelion.Options
local defaults = {
  transparent = false,
  dim_inactive = false,
  bold = true,
  italic = true,
  overrides = {},
  plugins = {},
}

---@type parhelion.Options
local options = vim.deepcopy(defaults)

local fzf_colors = {
  ["bg"] = { "bg", "NormalFloat" },
  ["bg+"] = { "bg", "PmenuSel" },
  ["border"] = { "fg", "FloatBorder" },
  ["fg"] = { "fg", "NormalFloat" },
  ["fg+"] = { "fg", "Title" },
  ["gutter"] = { "bg", "NormalFloat" },
  ["header"] = { "fg", "PmenuExtra" },
  ["hl"] = { "fg", "PmenuMatch" },
  ["hl+"] = { "fg", "PmenuMatch" },
  ["info"] = { "fg", "PmenuExtra" },
  ["marker"] = { "fg", "PmenuMatch" },
  ["pointer"] = { "fg", "PmenuMatch" },
  ["prompt"] = { "fg", "PmenuExtra" },
  ["query"] = { "fg", "NormalFloat" },
  ["scrollbar"] = { "fg", "FloatBorder" },
  ["separator"] = { "fg", "FloatBorder" },
  ["spinner"] = { "fg", "PmenuMatch" },
}

-- A group as the options applied so far leave it: its attributes, false when the load sets none, or nil when parhelion
-- does not draw it.
---@param built parhelion.Built
---@param changed parhelion.Changes
---@param name string
---@return vim.api.keyset.highlight|false|nil
local function drawn(built, changed, name)
  local hl = changed[name]
  if hl == nil then return built.groups[name] end

  return hl
end

---@param hl table<string, string|integer|boolean>
---@param attribute string
---@param value string|boolean
---@return table<string, string|integer|boolean>
local function with(hl, attribute, value)
  ---@type table<string, string|integer|boolean>
  local copy = {}
  for key, held in pairs(hl) do
    copy[key] = held
  end
  copy[attribute] = value

  return copy
end

---@type string
local directory = debug.getinfo(1, "S").source:match "^@(.*[/\\])"

---@return table<string, string[]>
local function supported_plugins()
  if not package.loaded["parhelion.plugins"] then
    ---@type table<string, string[]>
    local plugins = assert(loadfile(directory .. "plugins.lua"))()
    package.loaded["parhelion.plugins"] = plugins
  end

  return package.loaded["parhelion.plugins"]
end

---@return string[]
local function patterns_turned_off()
  ---@type table<string, string[]>, string[]
  local plugins, patterns = supported_plugins(), {}
  for plugin, on in pairs(options.plugins) do
    if not on then vim.list_extend(patterns, plugins[plugin]) end
  end

  return patterns
end

---@param patterns string[]
---@return table<integer, true>
local function first_letters(patterns)
  ---@type table<integer, true>
  local letters = {}
  for _, pattern in ipairs(patterns) do
    letters[pattern:byte(2)] = true
  end

  return letters
end

---@param name string
---@param patterns string[]
---@return boolean
local function matches_any(name, patterns)
  for _, pattern in ipairs(patterns) do
    if name:find(pattern) then return true end
  end

  return false
end

---@param built parhelion.Built
---@param changed parhelion.Changes
local function turn_off_plugins(built, changed)
  local patterns = patterns_turned_off()
  local letters = first_letters(patterns)

  -- Testing a group's first letter before searching it is not redundant: searching every group stops LuaJIT compiling
  -- this loop, which slows a first load.
  for name in pairs(built.groups) do
    if letters[name:byte()] and matches_any(name, patterns) then changed[name] = false end
  end
end

---@param built parhelion.Built
---@param changed parhelion.Changes
local function clear_backgrounds(built, changed)
  for _, name in ipairs(built.transparent_clears) do
    local hl = drawn(built, changed, name)
    if hl then changed[name] = with(hl, "bg", "NONE") end
  end
end

---@param style "bold"|"italic"
---@param built parhelion.Built
---@param changed parhelion.Changes
local function remove_style(style, built, changed)
  for name in pairs(built.groups) do
    local hl = drawn(built, changed, name)
    if hl and hl[style] then changed[name] = with(hl, style, false) end
  end
end

local raises_on_a_missing_color = {
  __index = function(_, name) error(string.format("parhelion has no color named %s", name), 2) end,
}

---@param built parhelion.Built
---@return table<string, string>
local function colors(built) return setmetatable(vim.deepcopy(built.colors), raises_on_a_missing_color) end

local scratch = vim.api.nvim_create_namespace "parhelion.overrides"

-- Neovim refuses a bad attribute only when a group is set, so each override is set first in a namespace no window
-- draws with, before the load clears the active colorscheme.
local function refuse_what_neovim_refuses(name, hl)
  local accepted, message = pcall(vim.api.nvim_set_hl, scratch, name, hl)
  if not accepted then error(string.format("parhelion cannot set overrides.%s: %s", name, message), 0) end
end

local function validate_overrides(overrides)
  for name, override in pairs(overrides) do
    if type(name) ~= "string" then
      error(
        string.format(
          "parhelion cannot set overrides[%s]: a group name is a string, not a %s",
          vim.inspect(name),
          type(name)
        ),
        0
      )
    end

    if name:find "[^A-Za-z0-9_.@-]" then
      error(
        string.format(
          "parhelion cannot set overrides[%s]: a group name holds only letters, digits, _, ., @ and -",
          vim.inspect(name)
        ),
        0
      )
    end

    if type(override) ~= "table" then
      error(string.format("parhelion cannot set overrides.%s: expected a table, got %s", name, type(override)), 0)
    end
  end
end

---@param groups table<string, parhelion.Highlight>
---@return table<string, string>
local function spellings(groups)
  ---@type table<string, string>
  local spelling = {}
  for name in pairs(groups) do
    spelling[name:lower()] = name
  end

  return spelling
end

---@param built parhelion.Built
---@param changed parhelion.Changes
local function apply_overrides(built, changed)
  local overrides = options.overrides
  if type(overrides) == "function" then
    overrides = overrides(colors(built))
    vim.validate("the result of overrides", overrides, "table")
  end
  validate_overrides(overrides)

  ---@type table<string, string>?
  local spelling
  for name, override in pairs(overrides) do
    if built.groups[name] == nil then
      spelling = spelling or spellings(built.groups)
      name = spelling[name:lower()] or name
    end
    local current = drawn(built, changed, name)

    if override.link or not current or current.link then
      changed[name] = override
    else
      changed[name] = vim.tbl_extend("force", current, override)
    end
    refuse_what_neovim_refuses(name, changed[name])
  end
end

local function turns_a_plugin_off() return vim.tbl_contains(vim.tbl_values(options.plugins), false) end

-- The groups the options change, each mapped to its new attributes or to false when the load sets none.
---@param built parhelion.Built
---@return parhelion.Changes
local function changes(built)
  ---@type parhelion.Changes
  local changed = {}
  if turns_a_plugin_off() then turn_off_plugins(built, changed) end
  if options.transparent then clear_backgrounds(built, changed) end
  if options.dim_inactive then changed.NormalNC = { bg = built.dimmed } end
  if not options.bold then remove_style("bold", built, changed) end
  if not options.italic then remove_style("italic", built, changed) end
  apply_overrides(built, changed)

  return changed
end

---@param groups table<string, parhelion.Highlight>
---@param changed parhelion.Changes
local function set_groups(groups, changed)
  for name, hl in pairs(groups) do
    if changed[name] == nil then vim.api.nvim_set_hl(0, name, hl) end
  end
  for name, hl in pairs(changed) do
    if hl then vim.api.nvim_set_hl(0, name, hl) end
  end
end

local function set_fzf_colors()
  if options.plugins.fzf == false then
    if vim.g.parhelion_set_fzf_colors and vim.deep_equal(vim.g.fzf_colors, fzf_colors) then vim.g.fzf_colors = nil end
    vim.g.parhelion_set_fzf_colors = nil
  elseif vim.g.fzf_colors == nil then
    vim.g.fzf_colors = fzf_colors
    vim.g.parhelion_set_fzf_colors = true
  end
end

---@generic T
---@param given T?
---@param default T
---@return T
local function given_or(given, default)
  if given == nil then return default end

  return given
end

---@param user_options? parhelion.UserOptions
function M.setup(user_options)
  user_options = user_options or {}
  ---@type table<string, unknown>
  local given = user_options
  for name in pairs(given) do
    if defaults[name] == nil then error(string.format("parhelion has no option named %s", name), 2) end
  end

  vim.validate("transparent", user_options.transparent, "boolean", true)
  vim.validate("dim_inactive", user_options.dim_inactive, "boolean", true)
  vim.validate("bold", user_options.bold, "boolean", true)
  vim.validate("italic", user_options.italic, "boolean", true)

  local overrides = user_options.overrides
  vim.validate("overrides", overrides, { "table", "function" }, true)
  if type(overrides) == "table" then
    validate_overrides(overrides)
    for name, override in pairs(overrides) do
      refuse_what_neovim_refuses(name, override)
    end
  end

  vim.validate("plugins", user_options.plugins, "table", true)
  for plugin, on in pairs(user_options.plugins or {}) do
    if supported_plugins()[plugin] == nil then
      error(string.format("parhelion sets no groups for a plugin named %s", plugin), 2)
    end
    vim.validate("plugins." .. plugin, on, "boolean")
  end

  local previous = options
  options = {
    transparent = given_or(user_options.transparent, defaults.transparent),
    dim_inactive = given_or(user_options.dim_inactive, defaults.dim_inactive),
    bold = given_or(user_options.bold, defaults.bold),
    italic = given_or(user_options.italic, defaults.italic),
    overrides = given_or(user_options.overrides, defaults.overrides),
    plugins = given_or(user_options.plugins, defaults.plugins),
  }
  if vim.g.colors_name ~= "parhelion" then return end

  local reloaded, message = pcall(vim.cmd.colorscheme, "parhelion")
  if not reloaded then
    options = previous
    error(message, 2)
  end
end

---@private
function M.draws_bold() return options.bold end

local built_directory = directory .. "built/"
---@type table<parhelion.Background, parhelion.Built>
local built_tables = {}

---@private
---@param background parhelion.Background
---@return parhelion.Built
function M.built(background)
  if not built_tables[background] then
    ---@type parhelion.Built
    local built = assert(loadfile(built_directory .. background .. ".lua"))()
    setmetatable(built.colors, raises_on_a_missing_color)
    built_tables[background] = built
  end

  return built_tables[background]
end

---@private
function M.load()
  local built = M.built(vim.o.background)
  local changed = changes(built)

  if vim.g.colors_name then
    vim.cmd "hi clear"
  else
    vim.cmd "syntax reset"
  end
  vim.g.colors_name = "parhelion"
  set_fzf_colors()

  for index, color in ipairs(built.terminal) do
    vim.g["terminal_color_" .. (index - 1)] = color
  end

  if next(changed) == nil then
    for name, hl in pairs(built.groups) do
      vim.api.nvim_set_hl(0, name, hl)
    end
  else
    set_groups(built.groups, changed)
  end
end

return M
