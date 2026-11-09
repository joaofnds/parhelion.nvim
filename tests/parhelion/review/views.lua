-- Opens a view of the test suite by name, in a Neovim of its own started the way the suite starts it: a popular view
-- under the popular views' init, and a plugin or code view under the suite's init with every plugin loaded.
---@type string, string
local root, deps = vim.env.PARHELION_ROOT, vim.env.PARHELION_DEPS
vim.env.POPULAR_HERE = root .. "/tests/parhelion/popular"
---@module "driver"
local Nvim = dofile(root .. "/tests/parhelion/driver.lua")
---@module "popular.views"
local popular = dofile(root .. "/tests/parhelion/popular/views.lua")
---@module "views"
local suite = dofile(root .. "/tests/parhelion/views.lua")

---@type table<string, views.View>
local suite_views = {}
for _, view in ipairs(vim.list_extend(suite.plugin_views(), suite.code_views(root .. "/tests/parhelion/samples"))) do
  suite_views[view.name] = view
end

local M = {}

---@param name string
---@return boolean
function M.exists(name) return popular.by_name[name] ~= nil or suite_views[name] ~= nil end

---@param sandbox string
---@return table<string, string>
local function homes(sandbox)
  return {
    PARHELION_ROOT = root,
    PARHELION_DEPS = deps,
    XDG_DATA_HOME = deps .. "/xdg/data",
    XDG_CONFIG_HOME = sandbox .. "/config",
    XDG_STATE_HOME = sandbox .. "/state",
    XDG_CACHE_HOME = sandbox .. "/cache",
  }
end

---@param view popular.View
---@param mode string
---@param sandbox string
---@return driver.Nvim
local function open_popular(view, mode, sandbox)
  local nvim = Nvim.spawn {
    args = { "-u", root .. "/tests/parhelion/popular/init.lua", "-i", "NONE", "-n" },
    cwd = sandbox .. "/fixture",
    rows = 36,
    cols = 112,
    env = vim.tbl_extend("error", homes(sandbox), {
      POPULAR_HERE = vim.env.POPULAR_HERE,
      POPULAR_VIEW = view.name,
      POPULAR_MODE = mode,
    }),
  }
  nvim:settle { quiet = 500 }
  view.run(nvim)
  for _, condition in ipairs(view.drawn) do
    nvim:settle { until_lua = condition, quiet = 0 }
  end

  return nvim
end

---@param view views.View
---@param mode string
---@param sandbox string
---@return driver.Nvim
local function open_suite(view, mode, sandbox)
  local nvim = Nvim.spawn {
    args = { "-u", root .. "/tests/parhelion/init.lua", "-i", "NONE", "-n" },
    cwd = sandbox .. "/fixture",
    rows = 50,
    cols = 130,
    env = vim.tbl_extend("error", homes(sandbox), {
      PARHELION_THEME = "parhelion",
      PARHELION_FIRST = mode,
      PARHELION_PLUGINS = "1",
      PARHELION_INSTALLED = "1",
    }),
  }
  nvim:settle { quiet = 500 }
  view.run(nvim)

  return nvim
end

---@param name string
---@param mode string
---@param sandbox string
---@return driver.Nvim
function M.open(name, mode, sandbox)
  assert(vim.system({ root .. "/tests/parhelion/fixture.sh", sandbox .. "/fixture" }):wait().code == 0)
  if popular.by_name[name] then return open_popular(popular.by_name[name], mode, sandbox) end

  return open_suite(assert(suite_views[name], "the suite has no view named " .. name), mode, sandbox)
end

return M
