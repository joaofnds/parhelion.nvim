---@type string, string
local root, deps = vim.env.PARHELION_ROOT, vim.env.PARHELION_DEPS
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(root .. "/after")

vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.foldlevel = 99
vim.o.signcolumn = "yes"
vim.o.cursorline = true
vim.o.termguicolors = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.fillchars = "eob: "
vim.o.laststatus = 3
vim.g.mapleader = " "

vim.o.background = vim.env.POPULAR_MODE
vim.cmd.colorscheme "parhelion"

---@module "popular.views"
local views = dofile(vim.env.POPULAR_HERE .. "/views.lua")
---@type string
local view_name = vim.env.POPULAR_VIEW
local view = views.by_name[view_name]

---@param name string
local function add(name)
  local dir = deps .. "/" .. name
  vim.opt.rtp:append(dir)
  if vim.fn.isdirectory(dir .. "/after") == 1 then vim.opt.rtp:append(dir .. "/after") end
end

for _, name in ipairs { "nvim-treesitter", "nvim-web-devicons", "plenary.nvim", "lualine.nvim" } do
  add(name)
end
for _, name in ipairs(view.plugins or {}) do
  add(name)
end

vim.api.nvim_create_autocmd("FileType", { callback = function(args) pcall(vim.treesitter.start, args.buf) end })

if not view.no_lualine then
  require("lualine").setup {
    options = { theme = "parhelion", globalstatus = true },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch" },
      lualine_c = { "filename", "diff", "diagnostics" },
      lualine_x = { "encoding", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  }
end
require("nvim-web-devicons").setup {}
if view.setup then view.setup() end
