local M = {}

local function has_filetype(filetype, min_lines)
  return string.format("return vim.bo.filetype == %q and vim.api.nvim_buf_line_count(0) >= %d", filetype, min_lines)
end

local treesitter_highlights_current_buffer =
  "return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil"

local function open_sample(path)
  return function(nvim)
    nvim:request("nvim_command", "edit " .. vim.fn.fnameescape(path))
    nvim:settle { until_lua = treesitter_highlights_current_buffer, quiet = 300 }
  end
end

local function expand_neogit_section(nvim, heading)
  nvim:lua(string.format("vim.fn.search(%q, 'cw')", heading))
  nvim:request("nvim_input", "<Tab>")
  nvim:settle { quiet = 300 }
end

local function neogit_status(nvim)
  nvim:request("nvim_command", "Neogit")
  nvim:settle { until_lua = has_filetype("NeogitStatus", 8), quiet = 800 }
  nvim:lua "vim.fn.search('^Unstaged changes', 'cw')"
  expand_neogit_section(nvim, "^modified.*notes.md")
  expand_neogit_section(nvim, "^modified.*app.lua")
  nvim:lua "vim.fn.cursor(1, 1)"
  nvim:settle { quiet = 300 }
end

local function neogit_commit(nvim)
  nvim:request("nvim_command", "Neogit")
  nvim:settle { until_lua = has_filetype("NeogitStatus", 8), quiet = 1000 }
  nvim:request("nvim_command", "NeogitCommit HEAD")
  nvim:settle { until_lua = has_filetype("NeogitCommitView", 8), quiet = 1000 }
end

local function neogit_popup(nvim)
  nvim:request("nvim_command", "Neogit")
  nvim:settle { until_lua = has_filetype("NeogitStatus", 8), quiet = 800 }
  nvim:request("nvim_input", "c")
  nvim:settle { until_lua = has_filetype("NeogitPopup", 3), quiet = 500 }
end

local function diffview(nvim)
  nvim:request("nvim_command", "DiffviewOpen")
  nvim:settle { until_lua = "return vim.bo.filetype == 'DiffviewFiles' or vim.wo.diff", quiet = 1200, timeout = 30000 }
end

local sample_files = {
  css = "sample.css",
  scss = "sample.scss",
  javascript = "sample.js",
  tsx = "sample.tsx",
  lua = "sample.lua",
}

function M.sample_for(language) return sample_files[language] end

function M.plugin_views()
  return {
    {
      name = "neogit-status",
      run = neogit_status,
      own_group = "NeogitSubtleText",
      draws_labels = true,
      word_washes = { "added_word_wash", "removed_word_wash" },
    },
    {
      name = "neogit-commit",
      run = neogit_commit,
      own_group = "NeogitSubtleText",
      draws_labels = true,
      word_washes = { "added_word_wash", "removed_word_wash" },
    },
    { name = "neogit-popup", run = neogit_popup, own_group = "NeogitSubtleText", draws_labels = true },
    {
      name = "diffview",
      run = diffview,
      own_group = "DiffviewFilePanelFileName",
      word_washes = { "changed_word_wash" },
    },
  }
end

function M.code_views(samples_dir)
  local views = {}
  for _, file in ipairs(vim.fn.sort(vim.fn.readdir(samples_dir))) do
    table.insert(views, { name = "code-" .. file, run = open_sample(samples_dir .. "/" .. file) })
  end
  return views
end

local first_identifier_has_semantic_token = [[
	local position = vim.fn.searchpos([=[\h]=], "cnw")
	return #vim.inspect_pos(0, position[1] - 1, position[2] - 1).semantic_tokens > 0
]]

function M.open_with_semantic_tokens(nvim, path, server_code)
  open_sample(path)(nvim)
  nvim:lua(server_code)
  nvim:settle { until_lua = first_identifier_has_semantic_token, quiet = 300 }
end

return M
