local deps = assert(vim.env.PARHELION_DEPS, "PARHELION_DEPS is required")
vim.opt.rtp:prepend(deps .. "/nvim-treesitter")

local languages = dofile(vim.fn.fnamemodify(arg[0], ":p:h") .. "/languages.lua")

assert(require("nvim-treesitter").install(languages):wait(600000), "parser install failed")
assert(require("nvim-treesitter").update(languages):wait(600000), "parser update failed")
