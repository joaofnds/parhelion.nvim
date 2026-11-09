local M = {}

M.rtp = {
  "nvim-treesitter",
  "nvim-treesitter-context",
  "plenary.nvim",
  "neogit",
  "diffview.nvim",
  "gitsigns.nvim",
  "lualine.nvim",
  "bufferline.nvim",
  "which-key.nvim",
  "flash.nvim",
  "blink.cmp",
  "fzf-lua",
  "grug-far.nvim",
  "trouble.nvim",
  "promise-async",
  "nvim-ufo",
  "mini.cursorword",
  "mini.notify",
  "mason.nvim",
  "nvim-surround",
  "undotree",
  "yazi.nvim",
}

function M.setup()
  require("treesitter-context").setup {}
  -- The file watcher can re-render the status buffer after the commit view takes focus, and a
  -- render without focus drops the buffer's fold signs, so the screen would vary between runs.
  require("neogit").setup { diff_viewer = "diffview", filewatcher = { enabled = false } }
  require("diffview").setup { use_icons = false }
  require("gitsigns").setup { signcolumn = false, numhl = true }
  require("lualine").setup {
    options = { theme = "parhelion", icons_enabled = false },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch" },
      lualine_c = { "filename", "diff", "diagnostics" },
      lualine_x = { "encoding", "fileformat", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  }
  require("bufferline").setup {
    options = {
      numbers = "ordinal",
      show_buffer_icons = false,
      show_buffer_close_icons = true,
      show_close_icon = false,
      close_icon = "x",
      buffer_close_icon = "x",
      modified_icon = "*",
      separator_style = { "▎", "" },
      indicator = { style = "none" },
    },
  }
  require("which-key").setup { icons = { mappings = false } }
  require("flash").setup {}
  require("blink.cmp").setup { fuzzy = { implementation = "lua" } }
  require("fzf-lua").setup {}
  require("grug-far").setup {}
  require("trouble").setup {}
  require("ufo").setup {}
  require("mini.cursorword").setup {}
  require("mini.notify").setup {}
  require("mason").setup {}
  require("nvim-surround").setup {}
  require("yazi").setup {}
end

return M
