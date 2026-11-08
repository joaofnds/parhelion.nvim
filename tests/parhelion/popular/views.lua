local M = { list = {}, by_name = {} }
local here = vim.env.POPULAR_HERE
local nest, rich = here .. "/nest.lua", here .. "/rich.md"

local function view(name, spec)
	spec.name = name
	table.insert(M.list, spec)
	M.by_name[name] = spec
end

local function edit(nvim, path, quiet)
	nvim:request("nvim_command", "edit " .. path)
	nvim:settle { quiet = quiet or 400 }
end

local function cmd(nvim, command, quiet)
	nvim:request("nvim_command", command)
	nvim:settle { quiet = quiet or 500 }
end

local function code_with_lsp(nvim)
	edit(nvim, nest)
	nvim:lua [[
    local lsp = dofile(vim.env.POPULAR_HERE .. "/lsp.lua")
    lsp.start()
    lsp.diagnostics(0)
  ]]
	nvim:settle { quiet = 500 }
end

view("telescope", {
	plugins = { "telescope.nvim" },
	setup = function()
		require("telescope").setup {
			defaults = { layout_strategy = "horizontal", layout_config = { preview_cutoff = 1 } },
			pickers = { find_files = { find_command = { "git", "ls-files" } } },
		}
	end,
	run = function(nvim)
		edit(nvim, "src/app.lua")
		cmd(nvim, "Telescope find_files", 900)
		nvim:request("nvim_input", "s")
		nvim:settle { quiet = 600 }
	end,
})

view("nvim-tree", {
	plugins = { "nvim-tree.lua" },
	setup = function() require("nvim-tree").setup { view = { width = 34 } } end,
	run = function(nvim)
		edit(nvim, "src/app.lua")
		cmd(nvim, "NvimTreeOpen", 900)
		nvim:lua "vim.fn.search('src')"
		nvim:request("nvim_input", "<CR>")
		nvim:settle { quiet = 700 }
	end,
})

view("neo-tree", {
	plugins = { "neo-tree.nvim", "nui.nvim" },
	setup = function()
		require("neo-tree").setup {
			window = { width = 100 },
			default_component_configs = {
				file_size = { enabled = false },
				type = { enabled = false },
				last_modified = { enabled = false },
				created = { enabled = false },
				symlink_target = { enabled = false },
			},
		}
	end,
	run = function(nvim)
		edit(nvim, "src/app.lua")
		cmd(nvim, "Neotree show reveal", 1500)
	end,
})

view("oil", {
	plugins = { "oil.nvim" },
	setup = function() require("oil").setup {} end,
	run = function(nvim) cmd(nvim, "Oil", 900) end,
})

local function cmp_view(name, window)
	view(name, {
		plugins = { "nvim-cmp" },
		setup = function()
			local cmp = require "cmp"
			local source = {}
			source.complete = function(_, _, callback)
				local items = {}
				for kind = 1, 25 do
					table.insert(items, {
						label = "item" .. vim.lsp.protocol.CompletionItemKind[kind],
						kind = kind,
						documentation = { kind = "markdown", value = "A **documented** entry with `code`." },
					})
				end
				callback { items = items, isIncomplete = false }
			end
			cmp.register_source("gallery", setmetatable({}, { __index = source }))
			cmp.setup {
				sources = { { name = "gallery" } },
				mapping = cmp.mapping.preset.insert {},
				window = window(cmp),
				formatting = { fields = { "abbr", "kind", "menu" } },
			}
		end,
		run = function(nvim)
			edit(nvim, nest)
			nvim:lua "vim.fn.cursor(36, 1)"
			nvim:request("nvim_input", "Oite")
			nvim:settle { quiet = 500 }
			nvim:lua "require('cmp').complete()"
			nvim:settle { quiet = 700 }
			nvim:request("nvim_input", "<C-n><C-n>")
			nvim:settle { quiet = 600 }
		end,
	})
end

cmp_view("cmp", function() return {} end)

cmp_view("cmp-bordered", function(cmp)
	local bordered = cmp.config.window.bordered { border = "rounded" }
	return { completion = bordered, documentation = bordered }
end)

local function blink_view(name, menu)
	view(name, {
		plugins = { "blink.cmp" },
		setup = function()
			require("blink.cmp").setup {
				fuzzy = { implementation = "lua" },
				completion = { documentation = { auto_show = true, auto_show_delay_ms = 0 }, menu = menu },
				sources = { default = { "buffer", "path", "snippets" } },
			}
		end,
		run = function(nvim)
			edit(nvim, nest)
			nvim:lua "vim.fn.cursor(36, 1)"
			nvim:request("nvim_input", "Ost")
			nvim:settle { quiet = 900 }
		end,
	})
end

blink_view("blink", {})
blink_view("blink-bordered", { border = "rounded" })

view("noice", {
	plugins = { "noice.nvim", "nui.nvim", "nvim-notify" },
	setup = function()
		require("notify").setup {
			stages = "static",
			timeout = 600000,
			render = "default",
			background_colour = "NotifyBackground",
		}
		require("noice").setup {
			lsp = { progress = { enabled = false } },
			presets = { command_palette = true, lsp_doc_border = true },
		}
	end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:settle { quiet = 600 }
		nvim:lua [[
      vim.notify("An error happened in the build", vim.log.levels.ERROR, { title = "Build" })
      vim.notify("Careful with this option", vim.log.levels.WARN, { title = "Config" })
      vim.notify("Finished indexing", vim.log.levels.INFO, { title = "Index" })
    ]]
		nvim:settle { quiet = 700 }
		nvim:request("nvim_input", ":lua vim.lsp.buf.format()")
		nvim:settle { quiet = 800 }
	end,
})

view("notify", {
	plugins = { "nvim-notify" },
	setup = function()
		require("notify").setup {
			stages = "static",
			timeout = 600000,
			render = "default",
			background_colour = "NotifyBackground",
		}
		vim.notify = require "notify"
	end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:lua [[
      vim.schedule(function()
      vim.notify("An error happened in the build", vim.log.levels.ERROR, { title = "Build" })
      vim.notify("Careful with this option", vim.log.levels.WARN, { title = "Config" })
      vim.notify("Finished indexing", vim.log.levels.INFO, { title = "Index" })
      end)
      vim.schedule(function()
      vim.notify("Resolved the path", vim.log.levels.DEBUG, { title = "Debug" })
      vim.notify("Called the handler", vim.log.levels.TRACE, { title = "Trace" })
      end)
    ]]
		nvim:settle { quiet = 700 }
	end,
})

view("snacks-picker", {
	plugins = { "snacks.nvim" },
	setup = function()
		require("snacks").setup {
			picker = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			notifier = { enabled = true },
		}
	end,
	run = function(nvim)
		edit(nvim, "src/app.lua")
		nvim:lua "Snacks.picker.git_files()"
		nvim:settle { quiet = 1200 }
		nvim:request("nvim_input", "s")
		nvim:settle { quiet = 500 }
	end,
})

view("snacks-dashboard", {
	draws_no_code = true,
	no_lualine = false,
	plugins = { "snacks.nvim" },
	setup = function()
		vim.g.snacks_animate = false
		require("snacks").setup {
			dashboard = {
				enabled = true,
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
					{ icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
				},
			},
		}
	end,
	run = function(nvim)
		nvim:request("nvim_input", ":lua Snacks.dashboard()<CR>")
		nvim:settle { quiet = 1200, timeout = 6000 }
	end,
})

view("snacks-notifier", {
	plugins = { "snacks.nvim" },
	setup = function()
		vim.g.snacks_animate = false
		require("snacks").setup {
			styles = { notification = { wo = { winblend = 0 } } },
			notifier = { enabled = true, timeout = 0 },
			indent = { enabled = true },
			words = { enabled = true },
		}
	end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:lua [[
      Snacks.notify("An error happened", { level = "error", title = "Build", timeout = 0 })
      Snacks.notify("Careful with this", { level = "warn", title = "Config", timeout = 0 })
      Snacks.notify("Finished indexing", { level = "info", title = "Index", timeout = 0 })
      Snacks.notify("Resolved the path", { level = "debug", title = "Debug", timeout = 0 })
    ]]
		nvim:lua "vim.fn.cursor(11, 12)"
		nvim:settle { quiet = 800 }
	end,
})

view("indent-rainbow", {
	plugins = { "indent-blankline.nvim", "rainbow-delimiters.nvim" },
	setup = function() require("ibl").setup {} end,
	run = function(nvim)
		edit(nvim, nest, 800)
		nvim:lua "vim.fn.cursor(11, 12)"
		nvim:settle { quiet = 700 }
	end,
})

view("illuminate-diagnostics", {
	plugins = { "vim-illuminate" },
	run = function(nvim)
		code_with_lsp(nvim)
		nvim:lua "vim.diagnostic.config({ virtual_text = true }); vim.fn.cursor(25, 15)"
		nvim:settle { quiet = 900 }
	end,
})

view("dashboard", {
	draws_no_code = true,
	plugins = { "dashboard-nvim" },
	setup = function()
		require("dashboard").setup {
			theme = "hyper",
			config = {
				week_header = { enable = true },
				shortcut = {
					{ desc = "Update", group = "@property", action = "", key = "u" },
					{ desc = "Files", group = "Label", action = "", key = "f" },
				},
			},
		}
	end,
	run = function(nvim) cmd(nvim, "Dashboard", 900) end,
})

view("alpha", {
	plugins = { "alpha-nvim" },
	setup = function()
		local theme = require "alpha.themes.dashboard"
		require("alpha").setup(theme.config)
	end,
	run = function(nvim) nvim:settle { quiet = 900 } end,
})

view("render-markdown", {
	plugins = { "render-markdown.nvim" },
	setup = function() require("render-markdown").setup {} end,
	run = function(nvim)
		edit(nvim, rich, 1000)
		nvim:lua "vim.fn.cursor(2, 1)"
		nvim:settle { quiet = 700 }
	end,
})

view("render-markdown-end", {
	plugins = { "render-markdown.nvim" },
	setup = function() require("render-markdown").setup {} end,
	run = function(nvim)
		edit(nvim, rich, 1000)
		nvim:lua "vim.fn.cursor(60, 1)"
		nvim:settle { quiet = 700 }
	end,
})

view("markview", {
	plugins = { "markview.nvim" },
	run = function(nvim)
		edit(nvim, rich, 1200)
		nvim:lua "vim.fn.cursor(2, 1)"
		nvim:settle { quiet = 900 }
	end,
})

view("markview-end", {
	plugins = { "markview.nvim" },
	run = function(nvim)
		edit(nvim, rich, 1200)
		nvim:lua "vim.fn.cursor(60, 1)"
		nvim:settle { quiet = 900 }
	end,
})

view("lspsaga", {
	plugins = { "lspsaga.nvim" },
	setup = function() require("lspsaga").setup { ui = { border = "rounded" } } end,
	run = function(nvim)
		code_with_lsp(nvim)
		nvim:lua "vim.fn.cursor(25, 15)"
		cmd(nvim, "Lspsaga outline", 900)
		nvim:request("nvim_command", "wincmd p")
		cmd(nvim, "Lspsaga hover_doc", 900)
	end,
})

view("dap-ui", {
	plugins = { "nvim-dap", "nvim-dap-ui", "nvim-nio" },
	setup = function() require("dapui").setup {} end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:lua "vim.fn.cursor(24, 1); require('dap').toggle_breakpoint(); vim.fn.cursor(25,1); require('dap').toggle_breakpoint('x > 1'); vim.fn.cursor(28,1); require('dap').toggle_breakpoint(nil, nil, 'log {x}'); require('dapui').open()"
		nvim:settle { quiet = 1200 }
	end,
})

view("harpoon", {
	plugins = { "harpoon" },
	setup = function() require("harpoon"):setup {} end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:lua "local h = require('harpoon'); h:list():add(); vim.cmd.edit('src/app.lua'); h:list():add(); vim.cmd.edit('notes.md'); h:list():add(); h.ui:toggle_quick_menu(h:list())"
		nvim:settle { quiet = 800 }
	end,
})

view("aerial", {
	plugins = { "aerial.nvim" },
	setup = function()
		require("aerial").setup {
			backends = { "lsp", "treesitter" },
			layout = { default_direction = "right", min_width = 34 },
			nerd_font = true,
		}
	end,
	run = function(nvim)
		code_with_lsp(nvim)
		cmd(nvim, "AerialOpen!", 900)
	end,
})

view("navic-winbar", {
	plugins = { "nvim-navic" },
	setup = function() require("nvim-navic").setup { highlight = true } end,
	run = function(nvim)
		code_with_lsp(nvim)
		nvim:lua [[
      local navic = require "nvim-navic"
      local kinds = { "File", "Module", "Namespace", "Package", "Class", "Method", "Property", "Field", "Constructor", "Enum", "Interface", "Function", "Variable", "Constant", "String", "Number" }
      local path = {}
      for kind, name in ipairs(kinds) do
        table.insert(path, { name = name:lower(), type = name, icon = "* ", kind = kind })
      end
      vim.o.winbar = navic.format_data(path)
    ]]
		nvim:settle { quiet = 600 }
	end,
})

view("dropbar", {
	plugins = { "dropbar.nvim" },
	setup = function() require("dropbar").setup {} end,
	run = function(nvim)
		edit(nvim, nest, 700)
		nvim:lua "vim.fn.cursor(11, 12)"
		nvim:settle { quiet = 800 }
		nvim:lua "require('dropbar.api').pick(3)"
		nvim:settle { quiet = 800 }
	end,
})

view("barbar", {
	plugins = { "barbar.nvim" },
	setup = function()
		vim.g.barbar_auto_setup = false
		require("barbar").setup {}
	end,
	run = function(nvim)
		edit(nvim, "notes.md")
		edit(nvim, "src/view.tsx")
		edit(nvim, "src/app.lua")
		edit(nvim, nest)
		nvim:lua "vim.bo.modified = true"
		nvim:settle { quiet = 600 }
	end,
})

view("bufferline", {
	plugins = { "bufferline.nvim" },
	setup = function() require("bufferline").setup {} end,
	run = function(nvim)
		edit(nvim, "notes.md")
		edit(nvim, "src/view.tsx")
		edit(nvim, "src/app.lua")
		edit(nvim, nest)
		nvim:lua "vim.bo.modified = true; vim.cmd.tabnew(); vim.cmd.tabprevious()"
		nvim:settle { quiet = 600 }
	end,
})

view("flash", {
	plugins = { "flash.nvim" },
	setup = function()
		require("flash").setup {}
		vim.keymap.set("n", "s", function() require("flash").jump() end)
	end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:request("nvim_input", "slo")
		nvim:settle { quiet = 500 }
	end,
})

view("mini-notify", {
	plugins = { "mini.nvim" },
	setup = function() require("mini.notify").setup { window = { winblend = 0 } } end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:lua [[
      MiniNotify.add("An error happened", "ERROR")
      MiniNotify.add("A warning worth reading", "WARN")
      MiniNotify.add("Formatting finished", "INFO")
    ]]
		nvim:settle { quiet = 500 }
	end,
})

view("undotree", {
	plugins = { "undotree" },
	run = function(nvim)
		edit(nvim, nest)
		nvim:request("nvim_input", "oone<Esc>otwo<Esc>")
		nvim:settle { quiet = 300 }
		cmd(nvim, "UndotreeShow", 600)
	end,
})

view("vim-sneak", {
	plugins = { "vim-sneak" },
	run = function(nvim)
		edit(nvim, nest)
		nvim:request("nvim_input", "sta")
		nvim:settle { quiet = 500 }
	end,
})

view("fidget", {
	plugins = { "fidget.nvim" },
	setup = function() require("fidget").setup {} end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:lua [[
      local fidget = require("fidget")
      fidget.notify("An error happened", vim.log.levels.ERROR, { ttl = 600 })
      fidget.notify("Careful with this", vim.log.levels.WARN, { ttl = 600 })
      fidget.notify("Finished indexing", vim.log.levels.INFO, { ttl = 600 })
    ]]
		nvim:settle { quiet = 500, timeout = 8000 }
	end,
})

view("hop", {
	plugins = { "hop.nvim" },
	setup = function() require("hop").setup {} end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:request("nvim_input", ":HopWord<CR>")
		nvim:settle { quiet = 600 }
	end,
})

view("leap", {
	plugins = { "leap.nvim" },
	run = function(nvim)
		edit(nvim, nest)
		nvim:lua "vim.keymap.set('n', 's', '<Plug>(leap)')"
		nvim:request("nvim_input", "sta")
		nvim:settle { quiet = 500 }
	end,
})

view("mini-files", {
	plugins = { "mini.nvim" },
	setup = function() require("mini.files").setup {} end,
	run = function(nvim)
		edit(nvim, "src/app.lua")
		nvim:lua "MiniFiles.open()"
		nvim:settle { quiet = 800 }
	end,
})

view("mini-pick", {
	plugins = { "mini.nvim" },
	setup = function() require("mini.pick").setup {} end,
	run = function(nvim)
		edit(nvim, "src/app.lua")
		nvim:lua "vim.schedule(function() MiniPick.builtin.cli({ command = { 'git', 'ls-files' } }) end)"
		nvim:settle { quiet = 900 }
		nvim:request("nvim_input", "s")
		nvim:settle { quiet = 500 }
	end,
})

view("mini-starter", {
	draws_no_code = true,
	no_lualine = true,
	plugins = { "mini.nvim" },
	setup = function() require("mini.starter").setup {} end,
	run = function(nvim)
		nvim:lua "MiniStarter.open()"
		nvim:settle { quiet = 800 }
	end,
})

view("mini-editor", {
	no_lualine = true,
	plugins = { "mini.nvim" },
	setup = function()
		require("mini.statusline").setup {}
		require("mini.tabline").setup {}
		require("mini.indentscope").setup { draw = { delay = 0, animation = function() return 0 end } }
		require("mini.diff").setup {}
		require("mini.hipatterns").setup {
			highlighters = {
				fixme = { pattern = "first", group = "MiniHipatternsFixme" },
				hack = { pattern = "stack", group = "MiniHipatternsHack" },
				todo = { pattern = "limit", group = "MiniHipatternsTodo" },
				note = { pattern = "name", group = "MiniHipatternsNote" },
			},
		}
		require("mini.clue").setup {
			triggers = { { mode = "n", keys = "g" } },
			clues = { require("mini.clue").gen_clues.g() },
			window = { delay = 0 },
		}
		require("mini.jump2d").setup {}
	end,
	run = function(nvim)
		edit(nvim, "notes.md")
		edit(nvim, nest, 700)
		nvim:lua "vim.fn.cursor(11, 12)"
		nvim:settle { quiet = 500 }
		nvim:request("nvim_input", "g")
		nvim:settle { quiet = 700 }
	end,
})

view("which-key", {
	labels_on = "float",
	plugins = { "which-key.nvim" },
	setup = function() require("which-key").setup { delay = 0 } end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:request("nvim_input", "g")
		nvim:settle { quiet = 900 }
	end,
})

view("fzf-lua", {
	plugins = { "fzf-lua" },
	setup = function() require("fzf-lua").setup { winopts = { backdrop = 100 } } end,
	run = function(nvim)
		edit(nvim, "src/app.lua")
		nvim:lua "require('fzf-lua').files()"
		nvim:settle { quiet = 1500 }
		nvim:request("nvim_input", "s")
		nvim:settle { quiet = 800 }
	end,
})

view("mason", {
	draws_no_code = true,
	plugins = { "mason.nvim" },
	setup = function() require("mason").setup { ui = { backdrop = 100 } } end,
	run = function(nvim) cmd(nvim, "Mason", 900) end,
})

view("lazy", {
	labels_on = "float",
	plugins = { "lazy.nvim" },
	setup = function()
		local deps = vim.env.PARHELION_DEPS
		require("lazy").setup({
			{ dir = deps .. "/flash.nvim", keys = { "s" } },
			{ dir = deps .. "/grug-far.nvim", ft = "markdown" },
			{ dir = deps .. "/mason.nvim", cmd = "Mason" },
			{ dir = deps .. "/which-key.nvim", event = "VeryLazy" },
		}, {
			lockfile = vim.fn.stdpath "state" .. "/lazy-lock.json",
			install = { missing = false },
			checker = { enabled = false },
			change_detection = { enabled = false },
			rocks = { enabled = false },
			performance = { reset_packpath = false, rtp = { reset = false } },
			ui = { backdrop = 100 },
		})
	end,
	run = function(nvim) cmd(nvim, "Lazy", 900) end,
})

view("grug-far", {
	plugins = { "grug-far.nvim" },
	setup = function() require("grug-far").setup {} end,
	run = function(nvim)
		edit(nvim, nest)
		cmd(nvim, "GrugFar", 900)
	end,
})

view("trouble", {
	plugins = { "trouble.nvim" },
	setup = function() require("trouble").setup {} end,
	run = function(nvim)
		code_with_lsp(nvim)
		cmd(nvim, "Trouble diagnostics open focus=false", 1000)
	end,
})

view("gitsigns", {
	plugins = { "gitsigns.nvim" },
	setup = function() require("gitsigns").setup { signcolumn = true, word_diff = true, current_line_blame = true } end,
	run = function(nvim)
		edit(nvim, "src/app.lua", 900)
		nvim:lua "vim.fn.cursor(5, 2); require('gitsigns').preview_hunk()"
		nvim:settle { quiet = 800 }
	end,
})

view("overseer", {
	plugins = { "overseer.nvim" },
	setup = function() require("overseer").setup {} end,
	run = function(nvim)
		edit(nvim, nest)
		nvim:lua [[
      local overseer = require("overseer")
      overseer.new_task({ cmd = { "true" }, name = "ok task" }):start()
      overseer.new_task({ cmd = { "false" }, name = "failing task" }):start()
      overseer.new_task({ cmd = { "true" }, name = "pending task" })
      overseer.open({ enter = false })
    ]]
		pcall(function() nvim:settle { quiet = 900, timeout = 4000 } end)
	end,
})

return M
