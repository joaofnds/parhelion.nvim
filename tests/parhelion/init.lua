local root, deps = vim.env.PARHELION_ROOT, vim.env.PARHELION_DEPS
local theme = vim.env.PARHELION_THEME

if vim.env.PARHELION_INSTALLED == "1" then
  vim.opt.rtp:prepend(root)
  vim.opt.rtp:append(root .. "/after")
end
if theme == "base_refined" then vim.opt.rtp:prepend(root .. "/tests/parhelion/base_refined") end

vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.colorcolumn = "80"
vim.o.foldlevel = 99
vim.o.signcolumn = "yes"
vim.o.cursorline = true
vim.o.termguicolors = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.fillchars = "eob: "
vim.opt.diffopt:append { "algorithm:patience", "indent-heuristic", "linematch:60" }

vim.g.globals_before_the_first_load = vim.tbl_keys(_G)
vim.o.background = vim.env.PARHELION_FIRST
local loaded, load_error = pcall(vim.cmd.colorscheme, theme)
if not loaded then
  io.stderr:write(tostring(load_error) .. "\n")
  vim.cmd.cquit()
end

for _, name in ipairs(dofile(root .. "/tests/parhelion/plugins.lua").rtp) do
  if vim.env.PARHELION_PLUGINS == "1" or name == "nvim-treesitter" then vim.opt.rtp:append(deps .. "/" .. name) end
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args) pcall(vim.treesitter.start, args.buf) end,
})

if vim.env.PARHELION_PLUGINS == "1" then dofile(root .. "/tests/parhelion/plugins.lua").setup() end
