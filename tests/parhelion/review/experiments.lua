-- Reads a file of experiments for review.sh. The file returns a review.File, and each experiment changes parhelion's
-- look against today's and names the views of the test suite that show the change.
---@class review.Experiment
---@field id string
---@field title string
---@field note string
---@field views string[]
---@field groups? fun(colors: table<string, string>, color: table): table<string, parhelion.Highlight>
---@field lualine? fun(theme: table, colors: table<string, string>, mode_hues: table<string, string>): table

---@class review.File
---@field experiments review.Experiment[]
---@field alternatives? string[][]

---@class review.Experiments
---@field list review.Experiment[]
---@field by_id table<string, review.Experiment>
---@field views string[]
---@field alternatives string[][]

local M = {}

---@param experiment review.Experiment
local function validate(experiment)
  vim.validate("id", experiment.id, "string")
  vim.validate("title", experiment.title, "string")
  vim.validate("note", experiment.note, "string")
  vim.validate("views", experiment.views, "table")
  vim.validate("groups", experiment.groups, "function", true)
  vim.validate("lualine", experiment.lualine, "function", true)
  if #experiment.views == 0 then error(experiment.id .. " names no view", 0) end
  if not (experiment.groups or experiment.lualine) then error(experiment.id .. " changes nothing", 0) end
end

---@param path string
---@return review.Experiments
function M.load(path)
  ---@type review.File
  local file = dofile(path)
  if #file.experiments == 0 then error(path .. " holds no experiments", 0) end
  ---@type table<string, review.Experiment>, string[], table<string, true>
  local by_id, views, seen = {}, {}, {}
  for _, experiment in ipairs(file.experiments) do
    validate(experiment)
    if by_id[experiment.id] then error("two experiments have the id " .. experiment.id, 0) end
    by_id[experiment.id] = experiment
    for _, view in ipairs(experiment.views) do
      if not seen[view] then table.insert(views, view) end
      seen[view] = true
    end
  end

  local alternatives = file.alternatives or {}
  for _, rivals in ipairs(alternatives) do
    for _, id in ipairs(rivals) do
      if not by_id[id] then error("the alternatives name no experiment " .. id, 0) end
    end
  end

  return { list = file.experiments, by_id = by_id, views = views, alternatives = alternatives }
end

return M
