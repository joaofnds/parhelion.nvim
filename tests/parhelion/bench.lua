if vim.o.verbose ~= 0 then
  error("'verbose' is on, which slows every nvim_set_hl many times over, so run this with -c luafile, not -l", 0)
end
if vim.env.PARHELION_BENCH_LOADER == "1" then vim.loader.enable() end

vim.o.termguicolors = true
vim.o.background = vim.env.PARHELION_BENCH_BACKGROUND

local function timed()
  local start = vim.uv.hrtime()
  vim.cmd.colorscheme(vim.env.PARHELION_BENCH_COLORSCHEME)

  return (vim.uv.hrtime() - start) / 1e6
end

local first = timed()
io.stdout:write(string.format("%.3f %.3f\n", first, timed()))
