-- Drives a sandboxed Neovim through the suite's UI driver and writes each screen the README shows as an HTML page.
---@type string, string, string
local root, deps, project = vim.env.PARHELION_ROOT, vim.env.PARHELION_DEPS, vim.env.SHOOT_PROJECT
---@type string, string
local out, font = arg[1], vim.env.SHOOT_FONT
---@module "driver"
local Nvim = dofile(root .. "/tests/parhelion/driver.lua")
---@type fun(nvim: driver.Nvim, font: string): string
local page = dofile(root .. "/assets/shoot/page.lua")

local function command(nvim, text) nvim:request("nvim_command", text) end

local function wait_for(nvim, condition)
  nvim:settle { quiet = 400, timeout = 30000, until_lua = "return " .. condition }
end

local function editor(nvim)
  command(nvim, "edit src/forecast.ts | badd src/units.ts | badd src/cache.ts")
  command(nvim, "NvimTreeFindFile | wincmd p")
  wait_for(nvim, "(vim.b.gitsigns_status_dict or {}).added ~= nil")
  wait_for(
    nvim,
    [[vim.iter(vim.api.nvim_buf_get_extmarks(vim.fn.bufnr "NvimTree_1", -1, 0, -1, { details = true })):any(
      function(mark) return tostring(mark[4].hl_group):find "^NvimTreeGit" ~= nil end
    )]]
  )

  nvim:lua [[
    local namespace = vim.api.nvim_create_namespace "shoot"
    local line = vim.fn.search("const body", "n") - 1
    vim.diagnostic.set(namespace, 0, {
      {
        lnum = line,
        col = 8,
        end_col = 12,
        severity = vim.diagnostic.severity.WARN,
        source = "eslint",
        message = "Unsafe assignment of an `any` value.",
      },
    })

    vim.fn.search "convert("
  ]]
  nvim:lua [[
    vim.lsp.util.open_floating_preview({
      "```typescript",
      "function convert(celsius: number, unit: Unit): number",
      "```",
      "Converts a temperature in degrees Celsius to the given unit.",
    }, "markdown", { border = "rounded", focus = false, close_events = {} })
  ]]
end

local function diff(nvim)
  command(nvim, "DiffviewOpen")
  wait_for(nvim, "#vim.tbl_filter(function(w) return vim.wo[w].diff end, vim.api.nvim_tabpage_list_wins(0)) == 2")
  command(nvim, "DiffviewToggleFiles")
  command(nvim, "set showtabline=0")
end

local scenes = {
  { name = "editor", cols = 118, rows = 36, run = editor },
  { name = "diff", cols = 156, rows = 30, run = diff },
}

vim.fn.mkdir(out, "p")
for _, scene in ipairs(scenes) do
  for _, mode in ipairs { "dark", "light" } do
    local nvim = Nvim.spawn {
      args = { "-u", root .. "/assets/shoot/init.lua", "-i", "NONE", "-n" },
      cwd = project,
      rows = scene.rows,
      cols = scene.cols,
      env = { PARHELION_ROOT = root, PARHELION_DEPS = deps, SHOOT_MODE = mode },
    }
    local ok, err = pcall(function()
      scene.run(nvim)
      local path = string.format("%s/%s-%s.html", out, scene.name, mode)
      vim.fn.writefile({ page(nvim, font) }, path)
      print(path)
    end)
    nvim:close()
    if not ok then error(string.format("%s in %s: %s", scene.name, mode, err), 0) end
  end
end
