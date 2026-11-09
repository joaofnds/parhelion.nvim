-- nvim --clean -l shoot.lua EXPERIMENTS MODE PAGES VIEW: opens VIEW and writes PAGES/VIEW--today.html and a page for
-- each experiment that names the view, as page.lua draws them, all in one Neovim so the view stays the same between
-- them. Each page follows a load of parhelion, today's included, since a load can change more than colors, as when
-- lualine drops the branch from a window whose buffer is not a file. It stops when the screen after the experiments
-- differs from today's, since a difference between two pages would then not be the experiment's.
---@type string, string?
local root, font = vim.env.PARHELION_ROOT, vim.env.SHOOT_FONT
local path, mode, pages, view = arg[1], arg[2], arg[3], arg[4]
---@type review.Experiments
local experiments = dofile(root .. "/tests/parhelion/review/experiments.lua").load(path)
---@module "review.views"
local views = dofile(root .. "/tests/parhelion/review/views.lua")
---@type fun(nvim: driver.Nvim, font?: string): string
local page = dofile(root .. "/assets/shoot/page.lua")
local apply = table.concat(vim.fn.readfile(root .. "/tests/parhelion/review/apply.lua"), "\n")

---@param nvim driver.Nvim
---@param id? string
---@return string
local function shoot(nvim, id)
  nvim:lua(apply, path, id)
  nvim:settle { quiet = 600, timeout = 10000 }

  return page(nvim, font)
end

---@param name string
---@param html string
local function write(name, html) vim.fn.writefile({ html }, string.format("%s/%s--%s.html", pages, view, name)) end

vim.fn.mkdir(pages, "p")
local sandbox = vim.fn.tempname()
local nvim = views.open(view, mode, sandbox)
local ok, err = pcall(function()
  local today = shoot(nvim, nil)
  write("today", today)
  for _, experiment in ipairs(experiments.list) do
    if vim.list_contains(experiment.views, view) then
      local changed = shoot(nvim, experiment.id)
      if changed == today then io.stderr:write(string.format("%s changes nothing in %s\n", experiment.id, view)) end
      write(experiment.id, changed)
    end
  end

  if shoot(nvim, nil) ~= today then error("the screen after the experiments differs from today's", 0) end
end)
nvim:close()
vim.fn.delete(sandbox, "rf")
if not ok then error(string.format("%s in %s: %s", view, mode, err), 0) end
