-- nvim --clean -l list.lua EXPERIMENTS OUT: writes the experiments the review page shows to OUT/experiments.json, and
-- prints the name of each view they name, one to a line, stopping on a view the test suite does not have.
---@type string
local root = vim.env.PARHELION_ROOT
local path, out = arg[1], arg[2]
---@type review.Experiments
local experiments = dofile(root .. "/tests/parhelion/review/experiments.lua").load(path)
---@module "review.views"
local views = dofile(root .. "/tests/parhelion/review/views.lua")

for _, view in ipairs(experiments.views) do
  if not views.exists(view) then error("the test suite has no view named " .. view, 0) end
end

---@type table<string, integer>
local numbers = {}
for number, experiment in ipairs(experiments.list) do
  numbers[experiment.id] = number
end

---@param ids string[]
---@return string
local function in_words(ids)
  ---@type string[]
  local listed = {}
  for _, id in ipairs(ids) do
    table.insert(listed, tostring(numbers[id]))
  end
  if #listed == 1 then return listed[1] end

  return table.concat(listed, ", ", 1, #listed - 1) .. " and " .. listed[#listed]
end

---@param experiment review.Experiment
---@return string?
local function alternatives_of(experiment)
  for _, rivals in ipairs(experiments.alternatives) do
    if vim.list_contains(rivals, experiment.id) then
      ---@type string[]
      local others = {}
      for _, id in ipairs(rivals) do
        if id ~= experiment.id then table.insert(others, id) end
      end
      return string.format("Alternative to %s, so keep at most one of them.", in_words(others))
    end
  end
end

local shown = {}
for _, experiment in ipairs(experiments.list) do
  table.insert(shown, {
    id = experiment.id,
    number = numbers[experiment.id],
    title = experiment.title,
    note = experiment.note,
    views = experiment.views,
    alternatives = alternatives_of(experiment),
  })
end
vim.fn.writefile({ vim.json.encode(shown) }, out .. "/experiments.json")
for _, view in ipairs(experiments.views) do
  io.stdout:write(view, "\n")
end
