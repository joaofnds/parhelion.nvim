local root, deps = vim.env.PARHELION_ROOT, vim.env.PARHELION_DEPS

vim.opt.rtp:prepend(root)
vim.opt.rtp:append(root .. "/after")
vim.opt.rtp:append(deps .. "/xdg/data/nvim/site")
for _, name in ipairs {
  "plenary.nvim",
  "nvim-tree.lua",
  "bufferline.nvim",
  "lualine.nvim",
  "gitsigns.nvim",
  "diffview.nvim",
} do
  vim.opt.rtp:append(deps .. "/" .. name)
end

vim.o.number = true
vim.o.signcolumn = "yes"
vim.o.cursorline = true
vim.o.wrap = false
vim.o.termguicolors = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.laststatus = 3
vim.o.showtabline = 2
vim.o.showmode = false
vim.o.cmdheight = 0
vim.o.fillchars = "eob: ,diff: "
vim.opt.shortmess:append "I"

vim.o.background = vim.env.SHOOT_MODE
vim.cmd.colorscheme "parhelion"

vim.api.nvim_create_autocmd(
  "FileType",
  { pattern = "typescript", callback = function(args) vim.treesitter.start(args.buf) end }
)

require("nvim-tree").setup {
  view = { width = 28 },
  filesystem_watchers = { enable = false },
  filters = { custom = { "^\\.git$" } },
  renderer = {
    root_folder_label = ":t",
    highlight_git = "name",
    indent_markers = { enable = true },
    icons = {
      git_placement = "right_align",
      show = { file = false, folder = false, modified = false, diagnostics = false, bookmarks = false },
      glyphs = {
        folder = { arrow_closed = "▸", arrow_open = "▾" },
        git = {
          unstaged = "M",
          staged = "S",
          unmerged = "!",
          renamed = "R",
          untracked = "U",
          deleted = "D",
          ignored = "◌",
        },
      },
    },
  },
}

require("bufferline").setup {
  options = {
    show_buffer_icons = false,
    show_buffer_close_icons = false,
    show_close_icon = false,
    modified_icon = "●",
    offsets = { { filetype = "NvimTree", text = "", separator = true } },
  },
}

require("lualine").setup {
  options = {
    theme = "parhelion",
    globalstatus = true,
    icons_enabled = false,
    section_separators = "",
    component_separators = "",
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch" },
    lualine_c = { "filename", "diff", "diagnostics" },
    lualine_x = { "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
}

require("gitsigns").setup {}
require("diffview").setup { use_icons = false, enhanced_diff_hl = true }

vim.diagnostic.config { virtual_text = true, severity_sort = true }
