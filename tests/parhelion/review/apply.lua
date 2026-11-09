-- Runs inside the Neovim a view is open in, given an experiments file and an experiment's id, or no id for today's
-- look. Loads parhelion with that experiment's overrides and gives lualine the theme it makes. It sets lualine up again
-- only to change its theme or put today's back, since a setup can change what lualine shows, such as dropping the
-- branch from a window whose buffer is not a file.
---@type string, string?
local path, id = ...
---@type string
local root = vim.env.PARHELION_ROOT
---@type review.Experiments
local experiments = dofile(root .. "/tests/parhelion/review/experiments.lua").load(path)
---@module "color"
local color = dofile(root .. "/tests/parhelion/color.lua")
local parhelion = require "parhelion"
local experiment = id and assert(experiments.by_id[id], "no experiment " .. id)

parhelion.setup {
  overrides = function(colors)
    if not (experiment and experiment.groups) then return {} end

    return experiment.groups(colors, color)
  end,
}

local lualine_theme = experiment and experiment.lualine
---@class review.Lualine
---@field get_config fun(): table
---@field setup fun(config: table)

---@type review.Lualine?
local lualine = package.loaded.lualine
if not lualine then return end
if not (lualine_theme or vim.g.review_changed_lualine) then return end

local config = lualine.get_config()
config.options.theme = "parhelion"
if lualine_theme then
  local built = parhelion.built(vim.o.background)
  ---@type table
  local today = dofile(root .. "/lua/lualine/themes/parhelion.lua")
  config.options.theme = lualine_theme(today, built.colors, built.mode_hues)
end
lualine.setup(config)
vim.g.review_changed_lualine = lualine_theme and true or false
