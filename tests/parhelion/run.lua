local root = vim.fn.fnamemodify(arg[0], ":p:h:h:h")
package.path = root .. "/tests/parhelion/?.lua;" .. root .. "/lua/?.lua;" .. package.path

local Nvim, compare, views, roles = require "driver", require "compare", require "views", require "roles"
local color, legibility, refinement = require "color", require "legibility", require "parhelion.refinement"
local color_difference_samples, theme_colors = require "color_difference_samples", require "theme_colors"
---@type table<string, table<string, vim.api.keyset.highlight>>
local approved = require "approved"
local approved_files, approved_presets = require "approved_files", require "approved_presets"
local restraint = require "restraint"

local deps = assert(vim.env.PARHELION_DEPS, "PARHELION_DEPS is required")
vim.env.POPULAR_HERE = root .. "/tests/parhelion/popular"
local samples = root .. "/tests/parhelion/samples"
local fixture = vim.fn.tempname()
assert(vim.system({ root .. "/tests/parhelion/fixture.sh", fixture }):wait().code == 0)

local snapshot_code = table.concat(vim.fn.readfile(root .. "/tests/parhelion/snapshot.lua"), "\n")
local semantic_server_code = table.concat(vim.fn.readfile(root .. "/tests/parhelion/semantic_tokens.lua"), "\n")

local base_tables = {
	dark = dofile(root .. "/lua/parhelion/base/dark.lua"),
	light = dofile(root .. "/lua/parhelion/base/light.lua"),
}

local function refined_table(background)
	return {
		groups = vim.tbl_map(
			function(hl) return refinement.highlight(background, hl) end,
			base_tables[background].groups
		),
	}
end

local query_languages = { "css", "scss", "javascript", "tsx", "lua" }

local paths = {
	{ label = "started in dark", first = "dark", background = "dark" },
	{ label = "started in light", first = "light", background = "light" },
	{ label = "toggled from dark to light", first = "dark", background = "light" },
	{ label = "toggled from light to dark", first = "light", background = "dark" },
}

local failures, passes = {}, 0
local filter = vim.env.PARHELION_TEST_FILTER

local function selected(name) return not filter or name:find(filter, 1, true) ~= nil end

io.stdout:setvbuf "line"

local function report(line) io.stdout:write(line, "\n") end

local function record_failure(name, err)
	table.insert(failures, name)
	report("FAIL " .. name .. "\n" .. tostring(err))
end

local function test(name, body)
	if not selected(name) then return end

	local ok, err = xpcall(body, debug.traceback)
	if ok then
		passes = passes + 1
		report("ok   " .. name)
	else
		record_failure(name, err)
	end
end

local function start_world(theme, path, plugins, options)
	local xdg = deps .. "/xdg"
	local world = xdg .. "/" .. theme
	local installed = options == nil or options.installed
	return Nvim.spawn {
		args = { "-u", root .. "/tests/parhelion/init.lua", "-i", "NONE", "-n" },
		cwd = fixture,
		rows = 50,
		cols = 130,
		env = {
			PARHELION_ROOT = root,
			PARHELION_DEPS = deps,
			PARHELION_THEME = theme,
			PARHELION_FIRST = path.first,
			PARHELION_PLUGINS = plugins and "1" or "0",
			PARHELION_INSTALLED = installed and "1" or "0",
			XDG_DATA_HOME = xdg .. "/data",
			XDG_CONFIG_HOME = world .. "/config",
			XDG_STATE_HOME = world .. "/state",
			XDG_CACHE_HOME = world .. "/cache",
		},
	}
end

local function snapshot(nvim) return vim.json.decode(nvim:lua(snapshot_code)) end

local function messages(nvim) return nvim:request("nvim_exec2", "messages", { output = true }).output end

local function toggle_when_path_requires_it(nvim, theme, path)
	if path.first == path.background then return end

	nvim:lua("vim.o.background = ...", path.background)
	nvim:request("nvim_command", "colorscheme " .. theme)
end

local function both_worlds(label, path, plugins, body)
	local base = start_world("base_refined", path, plugins)
	local parhelion = start_world("parhelion", path, plugins)
	local ok, err = xpcall(function()
		toggle_when_path_requires_it(base, "base_refined", path)
		toggle_when_path_requires_it(parhelion, "parhelion", path)
		body(base, parhelion)
	end, debug.traceback)
	base:close()
	parhelion:close()
	if not ok then record_failure(label .. ", " .. path.label, err) end
end

local function in_world(theme, path, body)
	local world = start_world(theme, path, false)
	local ok, err = xpcall(function() body(world) end, debug.traceback)
	world:close()
	if not ok then error(err, 0) end
end

local function expect_none(differences, what)
	if #differences == 0 then return end

	local shown = {}
	for i = 1, math.min(#differences, 8) do
		table.insert(shown, vim.inspect(differences[i], { newline = " ", indent = "" }))
	end
	error(string.format("%d %s:\n  %s", #differences, what, table.concat(shown, "\n  ")), 0)
end

local function expect_same_render(base, parhelion)
	expect_none(compare.cell_differences(base:capture(), parhelion:capture()), "cells differ")
end

local function expect_legible_text(parhelion)
	expect_none(
		legibility.illegible_text(parhelion:capture(), legibility.is_separator),
		"color pairs fall under the text floor"
	)
end

local function nearest_hue(background, hex)
	local nearest, smallest
	for name, hue in pairs(require("parhelion.chrome").hues[background]) do
		local difference = color.color_difference(hex, hue)
		if smallest == nil or difference < smallest then
			nearest, smallest = name, difference
		end
	end
	return nearest
end

local function expect_close(actual, expected, tolerance, what)
	local message = string.format("%s is %.4f, known to be %.4f", what, actual, expected)
	assert(math.abs(actual - expected) <= tolerance, message)
end

local function selected_any(names)
	for _, name in ipairs(names) do
		if selected(name) then return true end
	end
	return false
end

for _, case in ipairs {
	{ text = "#000000", background = "#ffffff", ratio = 21 },
	{ text = "#777777", background = "#ffffff", ratio = 4.478 },
	{ text = "#ff0000", background = "#ffffff", ratio = 3.998 },
	{ text = "#0000ff", background = "#ffffff", ratio = 8.592 },
	{ text = "#00ff00", background = "#000000", ratio = 15.304 },
} do
	test(
		string.format("contrast ratio of %s on %s has its known value", case.text, case.background),
		function() expect_close(color.contrast_ratio(case.text, case.background), case.ratio, 0.002, "ratio") end
	)
end

for _, case in ipairs {
	{ text = "#888888", background = "#ffffff", lightness = 63.056 },
	{ text = "#ffffff", background = "#888888", lightness = -68.541 },
	{ text = "#000000", background = "#aaaaaa", lightness = 58.146 },
	{ text = "#aaaaaa", background = "#000000", lightness = -56.241 },
	{ text = "#ff0000", background = "#ffffff", lightness = 64.126 },
	{ text = "#0000ff", background = "#ffffff", lightness = 85.821 },
	{ text = "#ffffff", background = "#0000ff", lightness = -90.653 },
	{ text = "#00ff00", background = "#000000", lightness = -86.489 },
	{ text = "#268bd2", background = "#002b36", lightness = -34.289 },
	{ text = "#657b83", background = "#fdf6e3", lightness = 65.671 },
	{ text = "#2c4e56", background = "#002b36", lightness = -8.254 },
	{ text = "#073642", background = "#002b36", lightness = 0 },
	{ text = "#002b36", background = "#073642", lightness = 0 },
	{ text = "#888888", background = "#888888", lightness = 0 },
} do
	test(
		string.format("lightness contrast of %s on %s has its known value", case.text, case.background),
		function() expect_close(color.lightness_contrast(case.text, case.background), case.lightness, 0.002, "Lc") end
	)
end

for row, case in ipairs(color_difference_samples) do
	test(
		string.format("the color difference gives %.4f for sample %d", case.difference, row),
		function()
			expect_close(color.color_difference_of_labs(case.first, case.second), case.difference, 0.0002, "difference")
		end
	)
end

for _, case in ipairs {
	{ color = "#ff0000", lab = { 53.2408, 80.0925, 67.2032 } },
	{ color = "#0000ff", lab = { 32.2970, 79.1875, -107.8602 } },
	{ color = "#ffffff", lab = { 100, 0, 0 } },
} do
	test(string.format("CIELAB of %s has its known value", case.color), function()
		local lab = color.lab(case.color)

		for channel, expected in ipairs(case.lab) do
			expect_close(lab[channel], expected, 0.002, "channel " .. channel)
		end
	end)
end

for _, case in ipairs {
	{ color = "#ff0000", lightness = 0.6280, chroma = 0.2577, hue = 29.23 },
	{ color = "#008000", lightness = 0.5198, chroma = 0.1769, hue = 142.50 },
	{ color = "#0000ff", lightness = 0.4520, chroma = 0.3132, hue = 264.05 },
} do
	test(string.format("the perceptual lightness, chroma and hue of %s have their known values", case.color), function()
		local lch = color.perceptual_lch(case.color)

		expect_close(lch.lightness, case.lightness, 0.0005, "lightness")
		expect_close(lch.chroma, case.chroma, 0.0005, "chroma")
		expect_close(lch.hue, case.hue, 0.03, "hue")
	end)
end

for _, case in ipairs {
	{ from = "#ff0000", to = "#0000ff", shift = -125.17 },
	{ from = "#0000ff", to = "#ff0000", shift = 125.17 },
} do
	test(
		string.format("the hue shift from %s to %s takes the short way around", case.from, case.to),
		function() expect_close(color.hue_shift(case.from, case.to), case.shift, 0.01, "shift") end
	)
end

for _, case in ipairs {
	{ xyz = { 0.950, 1.000, 1.089 }, lab = { 1.000, 0.000, 0.000 } },
	{ xyz = { 1.000, 0.000, 0.000 }, lab = { 0.450, 1.236, -0.019 } },
	{ xyz = { 0.000, 1.000, 0.000 }, lab = { 0.922, -0.671, 0.263 } },
	{ xyz = { 0.000, 0.000, 1.000 }, lab = { 0.153, -1.415, -0.449 } },
} do
	test(string.format("the perceptual lab of XYZ %.1f %.1f %.1f has its known value", unpack(case.xyz)), function()
		local lab = color.perceptual_lab_from_xyz(case.xyz)

		for channel, expected in ipairs(case.lab) do
			expect_close(lab[channel], expected, 0.001, "channel " .. channel)
		end
	end)
end

for background, tones in pairs(refinement.tones) do
	for from, to in pairs(tones) do
		test(string.format("%s stays close to %s in %s", to, from, background), function()
			local drift = color.color_difference(from, to)

			assert(drift <= legibility.largest_drift, string.format("moved %.1f", drift))
		end)

		if color.perceptual_lch(from).chroma >= legibility.smallest_chroma_with_visible_hue then
			test(string.format("%s keeps the hue of %s in %s", to, from, background), function()
				local shift = math.abs(color.hue_shift(from, to))
				local limit = from == legibility.accents.orange and legibility.largest_orange_hue_shift
					or legibility.largest_hue_shift

				assert(shift <= limit, string.format("hue moved %.2f degrees", shift))
			end)
		end

		test(string.format("%s is a color the base tables use in %s", from, background), function()
			local used = vim.tbl_map(string.lower, compare.colors_used_by(base_tables[background]))

			assert(vim.list_contains(used, from), from .. " is not in the base tables")
		end)
	end

	for _, page in ipairs(legibility.page_colors) do
		test(
			string.format("the page color %s keeps its value in %s", page, background),
			function()
				assert(refinement.color(background, page) == page, "moved to " .. refinement.color(background, page))
			end
		)
	end

	test("accent pairs stay apart in " .. background, function()
		local close = {}
		for first_name, first in pairs(legibility.accents) do
			for second_name, second in pairs(legibility.accents) do
				local difference =
					color.color_difference(refinement.color(background, first), refinement.color(background, second))
				if first_name < second_name and difference < legibility.smallest_accent_difference then
					table.insert(close, string.format("%s/%s %.1f", first_name, second_name, difference))
				end
			end
		end

		expect_none(close, "accent pairs are too close")
	end)
end

test("every extra query file has a pin", function()
	local unpinned = {}
	for name, kind in vim.fs.dir(root .. "/after/queries", { depth = 2 }) do
		local file = "after/queries/" .. name
		if kind == "file" and approved_files[file] == nil then table.insert(unpinned, file) end
	end

	expect_none(unpinned, "query files without a pin")
end)

for file, digest in pairs(approved_files) do
	test(file .. " holds its approved contents", function()
		local contents = table.concat(vim.fn.readfile(root .. "/" .. file), "\n")

		local actual = vim.fn.sha256(contents)

		assert(actual == digest, "its contents changed, its checksum is now " .. actual)
	end)
end

for _, path in ipairs(paths) do
	both_worlds("worlds without plugins", path, false, function(base_world, parhelion_world)
		local base, parhelion = snapshot(base_world), snapshot(parhelion_world)

		for name, look in pairs(approved[path.background]) do
			test(
				string.format("%s has its approved look, %s", name, path.label),
				function() expect_none(compare.look_differences(parhelion, { [name] = look }), "looks differ") end
			)
		end

		test("every base group resolves identically, " .. path.label, function()
			assert(parhelion.background == path.background, "parhelion background is " .. parhelion.background)
			assert(base.background == path.background, "base background is " .. base.background)
			local restyled = require("parhelion.chrome").groups(path.background)

			expect_none(compare.outside(compare.group_differences(base, parhelion), restyled), "groups differ")
		end)

		test(
			"terminal colors match, " .. path.label,
			function() expect_none(compare.terminal_differences(base, parhelion), "terminal colors differ") end
		)

		for position, hue in ipairs { "red", "green", "yellow", "blue", "magenta", "cyan" } do
			for _, slot in ipairs { position, position + 8 } do
				test(string.format("terminal color %d is %s, %s", slot, hue, path.label), function()
					local nearest = nearest_hue(path.background, parhelion.terminal[tostring(slot)])

					assert(nearest == hue, "it is nearest " .. nearest)
				end)
			end
		end

		for slot, name in pairs { ["0"] = "black", ["15"] = "bright white" } do
			test(string.format("terminal %s stands apart from the page, %s", name, path.label), function()
				local difference = color.color_difference(parhelion.terminal[slot], parhelion.groups.Normal.bg)

				assert(
					difference >= legibility.smallest_neutral_step,
					string.format("the difference is %.2f", difference)
				)
			end)
		end

		test("terminal white, bright black and bright white differ from each other, " .. path.label, function()
			local terminal = parhelion.terminal

			local too_close = vim.tbl_filter(
				function(pair)
					return color.color_difference(terminal[pair[1]], terminal[pair[2]])
						< legibility.smallest_neutral_step
				end,
				{ { "7", "8" }, { "7", "15" }, { "8", "15" } }
			)

			expect_none(too_close, "pairs of terminal neutrals too close")
		end)

		test("plugin-only text uses only colors the base tables or the chrome set, " .. path.label, function()
			local chrome = require "parhelion.chrome"
			local steps = vim.list_extend(
				vim.tbl_values(chrome.scale[path.background]),
				vim.tbl_values(chrome.label_hues[path.background])
			)

			local foreign = compare.foreign_colors(base, parhelion, refined_table(path.background), steps)

			expect_none(foreign, "plugin-only colors are foreign")
		end)

		test(
			"every group but the named decorations clears the text floor, " .. path.label,
			function() expect_none(legibility.groups_under_text_floor(parhelion), "groups fall under the floor") end
		)

		for _, tier in ipairs(legibility.tiers[path.background]) do
			test(
				string.format("%s text clears its contrast floors, %s", tier.name, path.label),
				function() expect_none(legibility.below_tier(parhelion, tier), "groups fall under the floors") end
			)
		end

		test("comments sit a clear step below body text, " .. path.label, function()
			local function lightness(name) return math.abs(color.lightness_contrast(legibility.pair(parhelion, name))) end

			local step = lightness "Normal" - lightness "Comment"

			assert(step >= legibility.smallest_step_below_body, string.format("the step is Lc %.1f", step))
		end)

		for _, role in ipairs(roles) do
			test(
				string.format("%s %s takes the role of %s, %s", role.group, role.attribute, role.equivalent, path.label),
				function() expect_none(compare.role_difference(role, base, parhelion), "role differs") end
			)
		end

		test("plugin-only groups never shadow a capture fallback, " .. path.label, function()
			local captures = vim.tbl_filter(
				function(name) return name:sub(1, 1) == "@" end,
				compare.parhelion_only_groups(base, parhelion)
			)
			expect_none(captures, "plugin-only capture groups")
		end)

		test(
			"plugin-only links reach a defined group, " .. path.label,
			function() expect_none(compare.dangling_links(base, parhelion), "plugin-only links dangle") end
		)

		test("flash, mason and which-key take their groups from chrome alone, " .. path.label, function()
			local restyled = require("parhelion.chrome").groups(path.background)

			local leaked = vim.tbl_filter(function(name)
				local lower = name:lower()
				local from_a_chrome_plugin = vim.startswith(lower, "flash")
					or vim.startswith(lower, "mason")
					or vim.startswith(lower, "whichkey")
				return from_a_chrome_plugin and restyled[name] == nil
			end, compare.parhelion_only_groups(base, parhelion))

			expect_none(leaked, "groups outside chrome")
		end)

		test("colors_name identifies the theme, " .. path.label, function()
			local name = parhelion_world:lua "return vim.g.colors_name"
			assert(name == "parhelion", "colors_name is " .. tostring(name))
		end)
	end)
end

for _, path in ipairs(paths) do
	both_worlds("semantic token worlds", path, false, function(base, parhelion)
		for _, language in ipairs(query_languages) do
			local sample = samples .. "/" .. views.sample_for(language)
			test(language .. " sample renders identically under semantic tokens, " .. path.label, function()
				views.open_with_semantic_tokens(base, sample, semantic_server_code)
				views.open_with_semantic_tokens(parhelion, sample, semantic_server_code)

				expect_same_render(base, parhelion)
			end)
		end
	end)
end

for _, language in ipairs(query_languages) do
	test("the extra " .. language .. " query parses and every pattern matches its sample", function()
		in_world("parhelion", paths[1], function(parhelion)
			local unmatched = parhelion:lua(
				[[
				local language, query_path, sample = ...
				local query_source = table.concat(vim.fn.readfile(query_path), "\n")
				local query = vim.treesitter.query.parse(language, query_source)
				local source = table.concat(vim.fn.readfile(sample), "\n")
				local tree = vim.treesitter.get_string_parser(source, language):parse()[1]
				local seen = {}
				for pattern in query:iter_matches(tree:root(), source, 0, -1) do
					seen[pattern] = true
				end

				local pattern_count = 0
				for node in vim.treesitter.get_string_parser(query_source, "query"):parse()[1]:root():iter_children() do
					if node:named() and node:type() ~= "comment" then pattern_count = pattern_count + 1 end
				end
				assert(pattern_count > 0, "no patterns in " .. query_path)

				local missing = {}
				for pattern = 1, pattern_count do
					if not seen[pattern] then table.insert(missing, pattern) end
				end
				return missing
			]],
				language,
				root .. "/after/queries/" .. language .. "/highlights.scm",
				samples .. "/" .. views.sample_for(language)
			)
			expect_none(unmatched, "patterns match nothing")
		end)
	end)
end

for _, language in ipairs(query_languages) do
	test("every capture the extra " .. language .. " query names draws a color under parhelion", function()
		in_world("parhelion", paths[1], function(parhelion)
			local uncolored = parhelion:lua(
				[[
				local language, query_path = ...
				local query = vim.treesitter.query.parse(language, table.concat(vim.fn.readfile(query_path), "\n"))

				local function drawn_fg(name)
					while name do
						local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
						if next(hl) then return hl.fg end
						name = name:match "^(.*)%.[^.]*$"
					end
				end

				return vim.tbl_filter(
					function(capture) return drawn_fg("@" .. capture .. "." .. language) == nil end,
					query.captures
				)
			]],
				language,
				root .. "/after/queries/" .. language .. "/highlights.scm"
			)

			expect_none(uncolored, "captures draw no color")
		end)
	end)
end

for _, path in ipairs { paths[1], paths[2] } do
	local installed = start_world("default", path, false)
	local absent = start_world("default", path, false, { installed = false })
	local ok, err = xpcall(function()
		for _, language in ipairs(query_languages) do
			local sample = samples .. "/" .. views.sample_for(language)
			test(
				string.format(
					"the %s sample draws the same under another colorscheme with parhelion installed, %s",
					language,
					path.label
				),
				function()
					views.open_with_semantic_tokens(absent, sample, semantic_server_code)
					views.open_with_semantic_tokens(installed, sample, semantic_server_code)

					expect_same_render(absent, installed)
				end
			)
		end
	end, debug.traceback)
	installed:close()
	absent:close()
	if not ok then record_failure("worlds under another colorscheme, " .. path.label, err) end
end

local group_colors_code = [[
local colors = {}
for name in pairs(vim.api.nvim_get_hl(0, {})) do
	local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
	colors[name] = vim.empty_dict()
	for _, attribute in ipairs { "fg", "bg" } do
		if hl[attribute] then colors[name][attribute] = string.format("#%06x", hl[attribute]) end
	end
end
return vim.json.encode(colors)
]]

for _, path in ipairs(paths) do
	both_worlds("code views", path, true, function(base, parhelion)
		base:settle { quiet = 500 }
		parhelion:settle { quiet = 500 }

		test("every Neogit group clears the text floor, " .. path.label, function()
			local neogit_groups = vim.tbl_filter(
				function(found) return vim.startswith(found.group, "Neogit") end,
				legibility.groups_under_text_floor(snapshot(parhelion))
			)
			expect_none(neogit_groups, "groups fall under the floor")
		end)

		for _, view in ipairs(views.code_views(samples)) do
			local render_test = view.name .. " renders identically and raises the same messages, " .. path.label
			local legibility_test = view.name .. " keeps its text legible, " .. path.label
			if selected_any { render_test, legibility_test } then
				local opened, err = xpcall(function()
					view.run(base)
					view.run(parhelion)
				end, debug.traceback)

				if opened then
					test(render_test, function()
						expect_same_render(base, parhelion)
						assert(messages(parhelion) == messages(base), "parhelion messages: " .. messages(parhelion))
					end)

					test(legibility_test, function() expect_legible_text(parhelion) end)
				else
					record_failure(view.name .. " opens, " .. path.label, err)
				end
			end
		end
	end)

	for _, view in ipairs(views.plugin_views()) do
		local render_test = view.name .. " renders identically, " .. path.label
		local groups_test = "every group resolves identically in " .. view.name .. ", " .. path.label
		local legibility_test = view.name .. " keeps its text legible, " .. path.label
		local approved_test = view.name .. " leaves the approved look in place, " .. path.label
		local color_ceiling_test = view.name .. " keeps its text under the color ceiling, " .. path.label
		local color_floor_test = view.name .. " keeps a share of its text in color, " .. path.label
		local scale_test = view.name .. " stays on the scale, " .. path.label
		local word_tests = {}
		for _, wash in ipairs(view.word_washes or {}) do
			word_tests[wash] = string.format("%s draws the %s, %s", view.name, wash, path.label)
		end
		if
			selected_any(vim.list_extend({
				render_test,
				groups_test,
				legibility_test,
				approved_test,
				color_ceiling_test,
				color_floor_test,
				scale_test,
			}, vim.tbl_values(word_tests)))
		then
			both_worlds(view.name, path, true, function(base, parhelion)
				base:settle { quiet = 500 }
				parhelion:settle { quiet = 500 }
				view.run(base)
				view.run(parhelion)

				test(render_test, function() expect_same_render(base, parhelion) end)

				test(legibility_test, function() expect_legible_text(parhelion) end)

				test(scale_test, function()
					local groups = vim.json.decode(parhelion:lua(group_colors_code))
					assert(groups[view.own_group], "the plugin defined no groups of its own")

					local off_the_scale = vim.tbl_filter(
						function(found) return found.group:find "^Neogit" or found.group:find "^Diffview" end,
						restraint.hues_off_the_scale(path.background, groups)
					)

					expect_none(off_the_scale, "groups hold a hue off the scale")
				end)

				if view.draws_labels then
					test(color_ceiling_test, function()
						local share = restraint.share_of_text_in_color(parhelion:capture(), legibility.is_icon)

						local limit = restraint.largest_share_in_color_with_labels
						assert(share <= limit, string.format("%.1f%% of the text is in color", share * 100))
					end)

					test(color_floor_test, function()
						local share = restraint.share_of_text_in_color(parhelion:capture(), legibility.is_icon)

						local limit = restraint.smallest_share_in_color_with_labels
						assert(share >= limit, string.format("%.1f%% of the text is in color", share * 100))
					end)
				end

				for wash, word_test in pairs(word_tests) do
					test(word_test, function()
						local step = require("parhelion.chrome").scale[path.background][wash]

						local drawn = restraint.cells_on(parhelion:capture(), step)

						assert(#drawn > 0, "no cell sits on " .. step)
					end)
				end

				test(groups_test, function()
					local restyled = require("parhelion.chrome").groups(path.background)
					local differences = compare.group_differences(snapshot(base), snapshot(parhelion))

					expect_none(compare.outside(differences, restyled), "groups differ")
				end)

				test(
					approved_test,
					function()
						expect_none(
							compare.look_differences(snapshot(parhelion), approved[path.background]),
							"looks differ"
						)
					end
				)
			end)
		end
	end
end

local colors_returned_by = [[
	local function colors_in(value, found)
		if type(value) == "string" and value:match "^#%x%x%x%x%x%x$" then table.insert(found, value:lower()) end
		if type(value) == "table" then
			for key, inner in pairs(value) do
				colors_in(key == "hl" and type(inner) == "function" and inner() or inner, found)
			end
		end
		return found
	end

	local entry_point = loadstring(...)
	return colors_in(entry_point(), {})
]]

local function known_colors(background)
	local chrome = require "parhelion.chrome"
	local known = {}
	for _, colors in ipairs { chrome.scale[background], chrome.hues[background] } do
		for _, hex in pairs(colors) do
			known[hex:lower()] = true
		end
	end

	return known
end

local feline_statusline = [[
	package.preload["feline.providers.lsp"] = function() return {} end
	local feline = require "parhelion.feline"
	feline.setup {}
	return feline.get_statusline()
]]

for _, path in ipairs(paths) do
	in_world("parhelion", path, function(world)
		local groups = snapshot(world).groups

		for _, name in ipairs {
			"Visual",
			"LspReferenceRead",
			"LspReferenceText",
			"LspReferenceWrite",
			"DiagnosticUnderlineError",
			"DiagnosticUnderlineWarn",
			"DiagnosticUnderlineInfo",
			"DiagnosticUnderlineHint",
			"DiagnosticUnderlineOk",
			"SpellBad",
			"SpellCap",
			"SpellLocal",
			"SpellRare",
		} do
			test(
				string.format("%s keeps the colors of the code under it, %s", name, path.label),
				function() assert(groups[name].fg == nil, vim.inspect(groups[name])) end
			)
		end

		test("a misspelled word is underlined in color and not struck through, " .. path.label, function()
			local misspelled = groups.SpellBad

			assert(misspelled.sp and misspelled.undercurl and not misspelled.strikethrough, vim.inspect(misspelled))
		end)

		test("the current quickfix entry stands apart from the other entries, " .. path.label, function()
			local current = groups.QuickFixLine

			assert(current.bg and current.bg ~= groups.Normal.bg, vim.inspect(current))
		end)

		test("a search match, the current match and a selection each draw their own fill, " .. path.label, function()
			local close = {}
			for _, pair in ipairs { { "Search", "CurSearch" }, { "Search", "Visual" }, { "CurSearch", "Visual" } } do
				local difference = color.color_difference(groups[pair[1]].bg, groups[pair[2]].bg)
				if difference < legibility.smallest_difference_between_overlays then
					table.insert(close, string.format("%s/%s %.1f", pair[1], pair[2], difference))
				end
			end

			expect_none(close, "fills too close")
		end)

		for _, name in ipairs { "Todo", "SpellCap" } do
			test(string.format("%s does not draw in the variable color, %s", name, path.label), function()
				local drawn = groups[name].fg or groups[name].sp

				assert(drawn ~= groups["@variable"].fg, vim.inspect(groups[name]))
			end)
		end
	end)
end

local search_inside_a_selection = [[
	vim.cmd.enew()
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "plain match plain match" })
	vim.o.hlsearch = true
	vim.fn.setreg("/", "match")
	vim.v.hlsearch = 1
	vim.api.nvim_feedkeys("$V", "n", false)
]]

local function cell_at(shot, text)
	for _, row in ipairs(shot.rows) do
		local line = table.concat(vim.tbl_map(function(cell) return cell.text end, row))
		local column = line:find(text, 1, true)
		if column then return row[vim.str_utfindex(line, "utf-32", column - 1) + 1] end
	end
	error(text .. " is not on the screen")
end

for _, path in ipairs { paths[1], paths[2] } do
	test("a search match inside a selection still shows, " .. path.label, function()
		in_world("parhelion", path, function(world)
			world:lua(search_inside_a_selection)

			local shot = world:capture()

			local plain, match = cell_at(shot, "plain match plain"), cell_at(shot, "match plain match")
			assert(plain.bg == snapshot(world).groups.Visual.bg, "the line is not selected: " .. vim.inspect(plain))
			local difference = color.color_difference(plain.fg, match.fg)
			assert(
				difference >= legibility.smallest_difference_between_overlays,
				string.format("%.1f %s", difference, vim.inspect { plain = plain, match = match })
			)
		end)
	end)
end

for _, entry_point in ipairs {
	{ name = "the reactive cursor preset", code = [[return require "reactive.presets.parhelion-cursor"]] },
	{ name = "the feline statusline", code = feline_statusline },
} do
	for _, path in ipairs { paths[1], paths[2] } do
		test(string.format("%s uses parhelion's colors, %s", entry_point.name, path.label), function()
			in_world("parhelion", path, function(world)
				local colors = world:lua(colors_returned_by, entry_point.code)

				local known = known_colors(path.background)
				local foreign = vim.tbl_filter(function(found) return not known[found] end, colors)

				assert(#colors > 0, "it returned no color")
				expect_none(foreign, "colors come from outside the theme")
			end)
		end)
	end
end

local colors_by_slot = [[
	local function flatten(value, slot, found)
		if type(value) == "string" and value:match "^#%x%x%x%x%x%x$" then found[slot] = value:lower() end
		if type(value) == "table" then
			for key, inner in pairs(value) do
				flatten(inner, slot .. "." .. (type(key) == "table" and key[1] or tostring(key)), found)
			end
		end
		return found
	end

	return flatten(require(...), "", {})
]]

for _, preset in ipairs { "cursor", "cursorline" } do
	for _, path in ipairs { paths[1], paths[2] } do
		test(string.format("the reactive %s preset has its approved colors, %s", preset, path.label), function()
			in_world("parhelion", path, function(world)
				local colors = world:lua(colors_by_slot, "reactive.presets.parhelion-" .. preset)

				local want = approved_presets[path.background][preset]
				assert(vim.deep_equal(colors, want), vim.inspect { got = colors, want = want })
			end)
		end)
	end
end

for _, path in ipairs { paths[1], paths[2] } do
	test("the lualine theme has its approved colors, " .. path.label, function()
		in_world("parhelion", path, function(world)
			local colors = world:lua(colors_by_slot, "lualine.themes.parhelion")

			local want = approved_presets[path.background].lualine
			assert(vim.deep_equal(colors, want), vim.inspect { got = colors, want = want })
		end)
	end)
end

local feline_colors_by_slot = [[
	local function flatten(value, slot, found)
		if type(value) == "function" and slot:match "%.hl$" then value = value() end
		if type(value) == "string" and value:match "^#%x%x%x%x%x%x$" then found[slot] = value:lower() end
		if type(value) == "table" then
			for key, inner in pairs(value) do
				flatten(inner, slot .. "." .. tostring(key), found)
			end
		end
		return found
	end

	return flatten(loadstring(...)(), "", {})
]]

for _, path in ipairs { paths[1], paths[2] } do
	test("the feline statusline has its approved colors in normal mode, " .. path.label, function()
		in_world("parhelion", path, function(world)
			local colors = world:lua(feline_colors_by_slot, feline_statusline)

			local want = approved_presets[path.background].feline
			assert(vim.deep_equal(colors, want), vim.inspect { got = colors, want = want })
		end)
	end)
end

for _, case in ipairs {
	{ path = paths[1], fg = "#002731", bg = "#40a0e8" },
	{ path = paths[2], fg = "#fdf6e3", bg = "#117fc5" },
} do
	test("the feline statusline writes its mode in the page color, " .. case.path.label, function()
		in_world("parhelion", case.path, function(world)
			local cell =
				world:lua("local components = loadstring(...)() return components.active[1][1].hl()", feline_statusline)

			assert(cell.fg == case.fg and cell.bg == case.bg, vim.inspect(cell))
		end)
	end)
end

for _, path in ipairs { paths[1], paths[2] } do
	test("the barbecue theme writes text in the body color, " .. path.label, function()
		in_world("parhelion", path, function(world)
			local text = world:lua [[return require("barbecue.theme.parhelion").normal.fg]]

			assert(text == snapshot(world).groups.Normal.fg, "text is " .. text)
		end)
	end)

	test("the barbecue theme draws from the surface scale only, " .. path.label, function()
		in_world("parhelion", path, function(world)
			local scale_colors = vim.tbl_values(require("parhelion.chrome").scale[path.background])

			local colors = world:lua(colors_returned_by, [[return require "barbecue.theme.parhelion"]])

			local off_scale = vim.tbl_filter(
				function(found) return not vim.list_contains(scale_colors, found) end,
				colors
			)
			expect_none(off_scale, "colors sit off the scale")
		end)
	end)

	test("the bufferline theme leaves the tab bar to the theme's groups, " .. path.label, function()
		in_world("parhelion", path, function(world)
			local theme = world:lua [[return vim.tbl_count(require("parhelion.bufferline").get_theme()())]]

			assert(theme == 0, "it answered with " .. theme .. " groups")
		end)
	end)

	in_world("parhelion", path, function(world)
		local scale = require("parhelion.chrome").scale[path.background]
		local resolved_code = [[
			local key = ...
			local attribute, group = unpack(vim.g.fzf_colors[key])
			local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attribute]
			return value and string.format("#%06x", value) or vim.NIL
		]]

		for key, step in pairs {
			["bg"] = "float",
			["bg+"] = "selected",
			["border"] = "hairline",
			["fg"] = "body",
			["fg+"] = "strong",
			["gutter"] = "float",
			["header"] = "quiet",
			["hl"] = "accent",
			["hl+"] = "accent",
			["info"] = "quiet",
			["marker"] = "accent",
			["pointer"] = "accent",
			["prompt"] = "quiet",
			["query"] = "body",
			["scrollbar"] = "hairline",
			["separator"] = "hairline",
			["spinner"] = "accent",
		} do
			test(string.format("the fzf color %s paints the %s step, %s", key, step, path.label), function()
				local painted = world:lua(resolved_code, key)

				assert(painted == scale[step], string.format("%s paints %s", key, tostring(painted)))
			end)
		end

		world:lua [[
			local shipped = vim.fn.globpath(vim.env.VIMRUNTIME, "colors/*.vim", false, true)
			table.sort(shipped)
			vim.cmd.colorscheme(vim.fn.fnamemodify(shipped[1], ":t:r"))
		]]
		for _, key in ipairs(vim.tbl_keys(world:lua "return vim.g.fzf_colors")) do
			test(
				string.format("the fzf color %s survives another colorscheme, %s", key, path.label),
				function() assert(world:lua(resolved_code, key) ~= vim.NIL, key .. " resolves to nothing") end
			)
		end
	end)

	test("a loaded theme leaves the user's fzf colors alone, " .. path.label, function()
		in_world("parhelion", path, function(world)
			local kept = world:lua [[
				vim.g.fzf_colors = { fg = { "fg", "Comment" } }
				vim.cmd.colorscheme "parhelion"
				return vim.g.fzf_colors
			]]

			assert(vim.deep_equal(kept, { fg = { "fg", "Comment" } }), vim.inspect(kept))
		end)
	end)

	for _, lualine_mode in ipairs { "normal", "insert", "visual", "replace", "command" } do
		test(string.format("lualine's %s section keeps its label legible, %s", lualine_mode, path.label), function()
			in_world("parhelion", path, function(world)
				local section = world:lua([[return require("lualine.themes.parhelion")[...].a]], lualine_mode)

				local lightness = math.abs(color.lightness_contrast(section.fg, section.bg))

				assert(lightness >= legibility.text_floor, string.format("Lc %.1f", lightness))
			end)
		end)
	end
end

for _, case in ipairs {
	{ name = "the dark page", hex = "#002b36" },
	{ name = "an even mix of blue and the dark page", hex = "#135b84" },
} do
	test(case.name .. " sits inside the theme's colors", function()
		local distance = theme_colors.distance_from_the_theme(case.hex)

		assert(distance <= theme_colors.largest_distance, string.format("%.1f away", distance))
	end)
end

for _, case in ipairs {
	{ name = "Neovim's default message green", hex = "#b3f6c0" },
	{ name = "a plugin's hard coded dark gray", hex = "#222222" },
} do
	test(case.name .. " sits outside the theme's colors", function()
		local distance = theme_colors.distance_from_the_theme(case.hex)

		assert(distance > theme_colors.largest_distance, string.format("%.1f away", distance))
	end)
end

do
	local stranger, page = "#b3f6c0", "#002b36"

	for _, case in ipairs {
		{
			name = "reports a stranger drawn as text",
			cell = { text = "x", fg = stranger, bg = page },
			found = { { attribute = "fg", color = stranger, cell = "x" } },
		},
		{
			name = "reports a stranger drawn behind a blank",
			cell = { text = " ", fg = page, bg = stranger },
			found = { { attribute = "bg", color = stranger, cell = " " } },
		},
		{
			name = "ignores the text color of a blank",
			cell = { text = " ", fg = stranger, bg = page },
			found = {},
		},
		{
			name = "ignores the color of an icon",
			cell = { text = "\u{f015}", fg = stranger, bg = page },
			found = {},
		},
	} do
		test("the check on drawn colors " .. case.name, function()
			local found = theme_colors.drawn_outside({ rows = { { case.cell } } }, legibility.is_icon)

			assert(vim.deep_equal(found, case.found), vim.inspect(found))
		end)
	end

	test("the check on groups reports a stranger", function()
		local found = theme_colors.groups_outside { OkMsg = { fg = stranger } }

		assert(vim.deep_equal(found, { { group = "OkMsg", attribute = "fg", color = stranger } }), vim.inspect(found))
	end)

	test("the check on groups lets an icon group hold a stranger", function()
		local found = theme_colors.groups_outside { DevIconLua = { fg = stranger } }

		expect_none(found, "groups hold strangers")
	end)
end

local off_every_scale = "#205074"

for _, case in ipairs {
	{ name = "a hue off every scale on a picker", group = "TelescopeNormal", color = off_every_scale },
	{ name = "violet on a picker", group = "TelescopeNormal", color = "#8188dd" },
	{ name = "magenta on a plugin it has no name for", group = "SomeNewPluginTitle", color = "#ef5299" },
	{ name = "a description's cyan on a file tree", group = "NvimTreeGitNew", color = "#3fb3a9" },
	{ name = "a hue off every scale on a group Neogit derives", group = "NeogitStashes", color = off_every_scale },
	{ name = "a code hue on a group lazy.nvim does not define", group = "LazyGitFloat", color = "#2aa198" },
	{ name = "a hue off every scale on a group lazy.nvim links", group = "LazyReasonKeys", color = off_every_scale },
	{ name = "a hue off every scale on a staged sign", group = "GitSignsStagedAdd", color = off_every_scale },
} do
	test("the scale check reports " .. case.name, function()
		local found = restraint.hues_off_the_scale("dark", { [case.group] = { fg = case.color } })

		assert(
			vim.deep_equal(found, { { group = case.group, attribute = "fg", color = case.color } }),
			vim.inspect(found)
		)
	end)
end

for _, case in ipairs {
	{ name = "the accent on a picker", background = "dark", group = "TelescopeMatching", hl = { fg = "#40a0e8" } },
	{ name = "an error on a file tree", background = "dark", group = "NvimTreeGitDeleted", hl = { fg = "#f95148" } },
	{
		name = "the added color on a file tree",
		background = "light",
		group = "NvimTreeGitNew",
		hl = { fg = "#708101" },
	},
	{ name = "a row wash on a preview", background = "dark", group = "GitSignsAddPreview", hl = { bg = "#23381f" } },
	{ name = "a word wash on a preview", background = "light", group = "GitSignsAddInline", hl = { bg = "#c7cc7d" } },
	{ name = "violet on a Neogit header", background = "dark", group = "NeogitSectionHeader", hl = { fg = "#8188dd" } },
	{ name = "orange on a Neogit branch", background = "light", group = "NeogitBranch", hl = { fg = "#b74a00" } },
	{ name = "magenta on a heading", background = "dark", group = "RenderMarkdownH6", hl = { fg = "#ef5299" } },
	{
		name = "a description's cyan in which-key",
		background = "dark",
		group = "WhichKeyDesc",
		hl = { fg = "#3fb3a9" },
	},
	{
		name = "violet on a section Neogit derives",
		background = "dark",
		group = "NeogitStashes",
		hl = { fg = "#8188dd" },
	},
	{
		name = "a heading's hue on the sign render-markdown combines from it",
		background = "dark",
		group = "RenderMarkdown_RenderMarkdownH2_RenderMarkdownSign",
		hl = { fg = "#8188dd" },
	},
	{
		name = "a code hue on a group lazy.nvim links to a core group",
		background = "dark",
		group = "LazyReasonFt",
		hl = { fg = "#2aa198" },
	},
} do
	test("the scale check accepts " .. case.name, function()
		local found = restraint.hues_off_the_scale(case.background, { [case.group] = case.hl })

		assert(vim.deep_equal(found, {}), vim.inspect(found))
	end)
end

for _, background in ipairs { "dark", "light" } do
	local scale = require("parhelion.chrome").scale[background]

	test("a description stays readable on the float in " .. background, function()
		local description = require("parhelion.chrome").label_hues[background].description

		local contrast = color.contrast_ratio(description, scale.float)

		assert(contrast >= legibility.smallest_description_contrast, string.format("%.2f:1", contrast))
	end)

	for _, wash in ipairs { "added_wash", "changed_wash", "removed_wash" } do
		test(string.format("a comment clears the text floor on the %s in %s", wash, background), function()
			local comment = refined_table(background).groups.Comment.fg

			local lightness = math.abs(color.lightness_contrast(comment, scale[wash]))

			assert(lightness >= legibility.text_floor, string.format("Lc %.1f", lightness))
		end)

		test(string.format("body text stays readable on the %s in %s", wash, background), function()
			local contrast = color.contrast_ratio(scale.body, scale[wash])

			assert(contrast >= legibility.smallest_body_contrast_on_a_wash, string.format("%.2f:1", contrast))
		end)

		test(string.format("the %s stands apart from the cursor line in %s", wash, background), function()
			local difference = color.color_difference(scale[wash], scale.raised)

			assert(
				difference >= legibility.smallest_wash_difference_from_the_cursor_line,
				string.format("%.1f", difference)
			)
		end)
	end

	test("a search match stays readable in " .. background, function()
		local match = require("parhelion.chrome").groups(background).Search

		local contrast = color.contrast_ratio(match.fg, match.bg)

		assert(contrast >= legibility.smallest_word_contrast, string.format("%.2f:1", contrast))
	end)

	test("a search match stands apart from the cursor line in " .. background, function()
		local difference = color.color_difference(scale.match_wash, scale.raised)

		assert(
			difference >= legibility.smallest_wash_difference_from_the_cursor_line,
			string.format("%.1f", difference)
		)
	end)

	test("a changed line differs from an unchanged one in " .. background, function()
		local changed = require("parhelion.chrome").groups(background).DiffChange

		assert(changed.bg == scale.changed_wash, vim.inspect(changed))
	end)

	for _, case in ipairs {
		{
			name = "a context row under the cursor",
			row = "NeogitDiffContextCursor",
			neighbor = "NeogitDiffContextHighlight",
		},
		{ name = "an added row under the cursor", row = "NeogitDiffAddCursor", neighbor = "NeogitDiffAddHighlight" },
		{
			name = "a removed row under the cursor",
			row = "NeogitDiffDeleteCursor",
			neighbor = "NeogitDiffDeleteHighlight",
		},
		{ name = "the focused file's header", row = "NeogitDiffHeaderHighlight", neighbor = "NeogitDiffHeader" },
	} do
		test(string.format("%s differs from its neighbors in %s", case.name, background), function()
			local groups = require("parhelion.chrome").groups(background)
			local function drawn(hl) return { fg = hl.fg or scale.body, bg = hl.bg, bold = hl.bold } end

			assert(
				not vim.deep_equal(drawn(groups[case.row]), drawn(groups[case.neighbor])),
				vim.inspect(groups[case.row])
			)
		end)
	end

	for _, case in ipairs {
		{ name = "an added word in neogit", word = "NeogitDiffAddInline", line = "NeogitDiffAddHighlight" },
		{ name = "a removed word in neogit", word = "NeogitDiffDeleteInline", line = "NeogitDiffDeleteHighlight" },
		{ name = "an added word in a gitsigns preview", word = "GitSignsAddInline", line = "GitSignsAddPreview" },
		{
			name = "a removed word in a gitsigns preview",
			word = "GitSignsDeleteInline",
			line = "GitSignsDeletePreview",
		},
		{ name = "an added word on a gitsigns line", word = "GitSignsAddLnInline", line = "GitSignsAddPreview" },
		{ name = "a removed word on a gitsigns line", word = "GitSignsDeleteLnInline", line = "GitSignsDeletePreview" },
		{ name = "a changed word in gitsigns", word = "GitSignsChangeInline", line = "DiffChange" },
		{ name = "a changed word in a mini.diff overlay", word = "MiniDiffOverChange", line = "DiffChange" },
		{ name = "a changed word in a diff window", word = "DiffText", line = "DiffChange" },
		{ name = "an added word in a changed line", word = "DiffTextAdd", line = "DiffChange" },
	} do
		test(string.format("%s stands out from its line in %s", case.name, background), function()
			local groups = require("parhelion.chrome").groups(background)

			local difference = color.color_difference(groups[case.word].bg, groups[case.line].bg)

			assert(difference >= legibility.smallest_word_difference_from_its_line, string.format("%.1f", difference))
		end)

		test(string.format("%s stays readable in %s", case.name, background), function()
			local word = require("parhelion.chrome").groups(background)[case.word]

			local contrast = color.contrast_ratio(word.fg, word.bg)

			assert(contrast >= legibility.smallest_word_contrast, string.format("%.2f:1", contrast))
		end)
	end
end

test("a command a plugin defines after a slow start is ready once the screen settles", function()
	local nvim = Nvim.spawn {
		args = {
			"--cmd",
			"lua vim.uv.sleep(800)",
			"--cmd",
			"autocmd UIEnter * ++once lua vim.schedule(function() vim.api.nvim_create_user_command('Later', '', {}) end)",
			"-u",
			"NONE",
			"-i",
			"NONE",
			"-n",
		},
		cwd = fixture,
		rows = 10,
		cols = 40,
	}

	local ok, err = pcall(function()
		nvim:settle { quiet = 500 }
		nvim:request("nvim_command", "Later")
	end)
	nvim:close()

	assert(ok, err)
end)

test("the scale check leaves a plugin's own derived line highlight alone", function()
	local found = restraint.hues_off_the_scale("dark", { GitSignsStagedAddLn = { fg = off_every_scale } })

	assert(vim.deep_equal(found, {}), vim.inspect(found))
end)

for _, case in ipairs {
	{
		name = "accepts a quiet word over a selection",
		fg = "#71888f",
		groups = { Visual = { bg = "#2c4e56" } },
		found = 0,
	},
	{ name = "reports a quiet word on a fill that is not the selection", fg = "#71888f", groups = {}, found = 1 },
	{
		name = "reports a word that vanishes into a selection",
		fg = "#3a5c64",
		groups = { Visual = { bg = "#2c4e56" } },
		found = 1,
	},
} do
	test("the floor check " .. case.name, function()
		local shot = { rows = { { { text = "x", fg = case.fg, bg = "#2c4e56", flags = "" } } }, groups = case.groups }

		local found = legibility.illegible_text(shot, legibility.is_line_art_or_icon)

		assert(#found == case.found, vim.inspect(found))
	end)
end

for _, case in ipairs {
	{ name = "counts colored text", fg = "#f95148", share = 1 },
	{ name = "ignores neutral text", fg = "#93a1a1", share = 0 },
} do
	test("the share of text in color " .. case.name, function()
		local shot = { rows = { { { text = "x", fg = case.fg } } } }

		assert(restraint.share_of_text_in_color(shot, legibility.is_icon) == case.share)
	end)
end

test("a screen with half its text in color exceeds the ceiling for a screen of labels", function()
	local shot = { rows = { { { text = "x", fg = "#f95148" }, { text = "x", fg = "#93a1a1" } } } }

	local share = restraint.share_of_text_in_color(shot, legibility.is_icon)

	assert(share > restraint.largest_share_in_color_with_labels, share)
end)

test("a screen with a fifth of its text in color exceeds the ceiling for a screen of plain text", function()
	local row = { { text = "x", fg = "#f95148" } }
	vim.list_extend(row, vim.fn["repeat"]({ { text = "x", fg = "#93a1a1" } }, 4))

	local share = restraint.share_of_text_in_color({ rows = { row } }, legibility.is_icon)

	assert(share > restraint.largest_share_in_color_without_code, share)
end)

test("a screen with a twentieth of its text in color falls under the floor", function()
	local row = { { text = "x", fg = "#f95148" } }
	vim.list_extend(row, vim.fn["repeat"]({ { text = "x", fg = "#93a1a1" } }, 19))

	local share = restraint.share_of_text_in_color({ rows = { row } }, legibility.is_icon)

	assert(share < restraint.smallest_share_in_color_with_labels, share)
end)

test("a difference outside the restyled groups stays reported", function()
	local found = compare.outside({ { name = "Normal" } }, { WhichKeyDesc = {} })

	assert(#found == 1 and found[1].name == "Normal", vim.inspect(found))
end)

test(
	"a difference in a restyled group is skipped in any letter case",
	function() assert(#compare.outside({ { name = "whichkeydesc" } }, { WhichKeyDesc = {} }) == 0) end
)

test("the structure check reports an accent on a border of a plugin it has no name for", function()
	local found = restraint.colored_structure { SomeNewPluginBorder = { fg = "#40a0e8" } }

	assert(#found == 1, vim.inspect(found))
end)

for _, case in ipairs {
	{ name = "a picker's title", group = "TelescopeTitle" },
	{ name = "a description in a picker", group = "SomeNewPluginDesc" },
	{ name = "a header in a file tree", group = "SomeNewPluginHeader" },
} do
	test("the structure check reports a hue on " .. case.name, function()
		local found = restraint.colored_structure { [case.group] = { fg = "#ef5299" } }

		assert(
			vim.deep_equal(found, { { group = case.group, attribute = "fg", color = "#ef5299" } }),
			vim.inspect(found)
		)
	end)
end

for _, case in ipairs {
	{ name = "Neogit's section header", group = "NeogitSectionHeader", color = "#8188dd" },
	{ name = "which-key's description", group = "WhichKeyDesc", color = "#3fb3a9" },
} do
	test("the structure check leaves its label hue on " .. case.name, function()
		local found = restraint.colored_structure { [case.group] = { fg = case.color } }

		assert(vim.deep_equal(found, {}), vim.inspect(found))
	end)
end

test("the scale check leaves a statusline its mode colors", function()
	local found = restraint.hues_off_the_scale("dark", { MiniStatuslineModeVisual = { bg = off_every_scale } })

	assert(vim.deep_equal(found, {}), vim.inspect(found))
end)

test("the scale check leaves a syntax group its hue", function()
	local found = restraint.hues_off_the_scale("dark", { Constant = { fg = off_every_scale } })

	assert(vim.deep_equal(found, {}), vim.inspect(found))
end)

test("the scale check accepts a monotone on a plugin group", function()
	local found = restraint.hues_off_the_scale("dark", { TelescopeNormal = { fg = "#71888f", bg = "#0d414e" } })

	assert(vim.deep_equal(found, {}), vim.inspect(found))
end)

test("the structure check reports an accent on a border", function()
	local found = restraint.colored_structure { TelescopeBorder = { fg = "#40a0e8" } }

	assert(
		vim.deep_equal(found, { { group = "TelescopeBorder", attribute = "fg", color = "#40a0e8" } }),
		vim.inspect(found)
	)
end)

test("the structure check lets a severity color a notification border", function()
	local found = restraint.colored_structure { NotifyERRORBorder = { fg = "#f95148" } }

	assert(vim.deep_equal(found, {}), vim.inspect(found))
end)

for _, case in ipairs {
	{ name = "a diagnostic", group = "DiagnosticVirtualTextError", found = true },
	{ name = "a gutter sign", group = "GitSignsChange", found = true },
	{ name = "a gutter number", group = "GitSignsAddNr", found = true },
	{ name = "Neogit's gutter number", group = "NeogitCursorLineNr", found = true },
	{ name = "Neogit's cursor line", group = "NeogitCursorLine", found = true },
	{ name = "Neogit's sign column", group = "NeogitSignColumn", found = true },
	{ name = "Neogit's fold column", group = "NeogitFoldColumn", found = true },
	{ name = "Neogit's page", group = "NeogitNormal", found = true },
	{ name = "Diffview's cursor line", group = "DiffviewCursorLine", found = true },
	{ name = "Diffview's page", group = "DiffviewNormal", found = true },
	{ name = "Diffview's end of buffer", group = "DiffviewEndOfBuffer", found = true },
	{ name = "Diffview's status line", group = "DiffviewStatusLine", found = true },
	{ name = "Diffview's inactive status line", group = "DiffviewStatuslineNC", found = true },
	{ name = "a gutter line", group = "GitSignsAddLn", found = true },
	{ name = "gitgutter's changed sign", group = "GitGutterChange", found = true },
	{ name = "gitgutter's changed number", group = "GitGutterChangeLineNr", found = true },
	{ name = "the fold column", group = "FoldColumn", found = true },
	{ name = "a closed fold", group = "Folded", found = true },
	{ name = "a lualine section", group = "lualine_a_normal", found = true },
	{ name = "an inactive statusline", group = "StatusLineNC", found = true },
	{ name = "the float's default", group = "NormalFloat", found = true },
	{ name = "a matching bracket", group = "MatchParen", found = true },
	{ name = "concealed text", group = "Conceal", found = true },
	{ name = "the cursor column", group = "CursorColumn", found = true },
	{ name = "an LSP group", group = "LspInlayHint", found = true },
	{ name = "a diagnostic", group = "DiagnosticError", found = true },
	{ name = "a reference to the symbol under the cursor", group = "LspReferenceRead", found = false },
	{ name = "a diagnostic's underline", group = "DiagnosticUnderlineError", found = false },
	{ name = "the selection", group = "Visual", found = false },
	{ name = "a todo mark", group = "Todo", found = false },
	{ name = "a syntax group", group = "Function", found = true },
	{ name = "an unscoped capture", group = "@markup.heading.1", found = true },
	{ name = "a markdown capture", group = "@markup.heading.1.markdown", found = true },
	{ name = "an inline markdown capture", group = "@markup.raw.markdown_inline", found = true },
	{ name = "a heading band", group = "RenderMarkdownH1Bg", found = true },
	{ name = "a markdown quote", group = "@markup.quote.markdown", found = true },
	{ name = "a legacy markdown heading", group = "markdownH1", found = false },
	{ name = "a completion kind", group = "LspKindFunction", found = false },
	{ name = "a Neogit group", group = "NeogitBranch", found = false },
	{ name = "a Diffview group", group = "DiffviewFilePanelTitle", found = false },
	{ name = "a diff line", group = "DiffAdd", found = false },
	{ name = "a gutter preview", group = "GitSignsAddInline", found = false },
	{ name = "the gutter's added sign", group = "GitSignsAdd", found = false },
	{ name = "a staged sign", group = "GitSignsStagedAdd", found = false },
	{ name = "a staged gutter number", group = "GitSignsStagedChangeNr", found = false },
	{ name = "the added syntax group", group = "Added", found = false },
	{ name = "an added line in a diff file", group = "@diff.plus", found = false },
	{ name = "gitgutter's added sign", group = "GitGutterAdd", found = false },
	{ name = "gitgutter's added number", group = "GitGutterAddLineNr", found = false },
	{ name = "a picker group", group = "TelescopeNormal", found = false },
} do
	test(string.format("the boundary check %s %s", case.found and "reports" or "accepts", case.name), function()
		local found = restraint.restyled_past_the_boundary { family = { quiet = case.group } }

		assert(#found == (case.found and 1 or 0), vim.inspect(found))
	end)
end

for _, path in ipairs { paths[1], paths[2] } do
	test("the base side leaves completion menus as the base tables draw them, " .. path.label, function()
		in_world("base_refined", path, function(world)
			local menu =
				world:lua [[return string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Pmenu", link = false }).bg)]]
			local restyled = require("parhelion.chrome").groups(path.background).Pmenu.bg

			assert(menu ~= restyled, menu)
		end)
	end)
end

for _, path in ipairs(paths) do
	test("a load sets no global, " .. path.label, function()
		in_world("parhelion", path, function(world)
			toggle_when_path_requires_it(world, "parhelion", path)

			local added = world:lua [[
				local before = vim.g.globals_before_the_first_load

				return vim.tbl_filter(function(name) return not vim.list_contains(before, name) end, vim.tbl_keys(_G))
			]]

			expect_none(added, "globals appeared")
		end)
	end)
end

for _, table_name in ipairs { "scale", "hues", "label_hues" } do
	test(string.format("reading a color the %s lacks raises", table_name), function()
		local colors = require("parhelion.chrome")[table_name].dark

		local ok, message = pcall(function() return colors.no_such_color end)

		assert(ok == false, "the read returned " .. tostring(message))
		assert(message:find("the dark " .. table_name .. " has no color named no_such_color", 1, true), message)
	end)
end

test("a family that names a role the looks lack raises", function()
	local chrome = require "parhelion.chrome"
	chrome.families.with_a_typo = { no_such_role = "TypoGroup" }

	local ok, message = pcall(chrome.groups, "dark")

	chrome.families.with_a_typo = nil
	assert(ok == false, "the family loaded")
	assert(message:find("the with_a_typo family names no_such_role, which is not a look", 1, true), message)
end)

for _, case in ipairs {
	{ name = "its own case", link = "OilDir" },
	{ name = "another case", link = "oildir" },
} do
	test("a link that names a group a family sets raises, in " .. case.name, function()
		local chrome = require "parhelion.chrome"
		chrome.links[case.link] = "Directory"

		local ok, message = pcall(chrome.groups, "dark")

		chrome.links[case.link] = nil
		assert(ok == false, "the link loaded")
		assert(message:find(case.link .. " is both in a family and a link", 1, true), message)
	end)
end

test("a load that fails keeps the active colorscheme and raises its error", function()
	in_world("parhelion", paths[1], function(world)
		local before = world:lua [[return vim.api.nvim_get_hl(0, { name = "Normal" }).fg]]

		local ok, message, name, after = unpack(world:lua [[
			require("parhelion.chrome").families.with_a_typo = { no_such_role = "TypoGroup" }

			local ok, message = pcall(require("parhelion").load)

			return { ok, message, vim.g.colors_name, vim.api.nvim_get_hl(0, { name = "Normal" }).fg }
		]])

		assert(ok == false, "the load succeeded")
		assert(message:find("the with_a_typo family names no_such_role, which is not a look", 1, true), message)
		assert(name == "parhelion" and after == before, vim.inspect { name, before, after })
	end)
end)

for _, background in ipairs { "dark", "light" } do
	for _, family_name in ipairs {
		"diff_lines",
		"diff_marks",
		"diffview",
		"gitsigns",
		"headlines",
		"lazy",
		"markdown_text",
		"markview",
		"mason",
		"mini_clue",
		"mini_diff",
		"neogit",
		"render_markdown",
		"which_key",
	} do
		test(string.format("every name in %s has a pinned look in %s", family_name, background), function()
			local unpinned = vim.tbl_filter(
				function(name) return approved[background][name] == nil end,
				vim.tbl_keys(require("parhelion.chrome").family_groups(background, family_name))
			)

			expect_none(unpinned, "names without a pin")
		end)
	end

	test("every tone has a pinned look in " .. background, function()
		local pinned = {}
		for _, look in pairs(approved[background]) do
			for _, attribute in ipairs(refinement.color_attributes) do
				if look[attribute] then pinned[look[attribute]:lower()] = true end
			end
		end

		local unpinned = vim.tbl_filter(
			function(tone) return not pinned[tone] end,
			vim.tbl_values(refinement.tones[background])
		)

		expect_none(unpinned, "tones without a pin")
	end)

	test("every role in every family has a pinned look in " .. background, function()
		local unpinned = {}
		for family_name, family in pairs(require("parhelion.chrome").families) do
			for role, names in pairs(family) do
				local pinned = vim.iter(names:gmatch "%S+")
					:any(function(name) return approved[background][name] ~= nil end)
				if not pinned then table.insert(unpinned, family_name .. "." .. role) end
			end
		end

		expect_none(unpinned, "roles without a pin")
	end)
end

test("no plugin family restyles what the buffer owns", function()
	local families = require("parhelion.chrome").families

	expect_none(restraint.restyled_past_the_boundary(families), "groups restyled past the boundary")
end)

for background, base_table in pairs(base_tables) do
	for level = 1, 6 do
		test(string.format("a level %d heading band holds a tint and a hue in %s", level, background), function()
			local name = string.format("RenderMarkdownH%dBg", level)

			local band = refinement.repaired_groups(background, base_table.groups)[name] or base_table.groups[name]

			local steps = require("parhelion.chrome").scale[background]
			local is_tinted = band and band.bg and band.bg:lower() ~= steps.raised and band.bg:lower() ~= steps.page
			assert(is_tinted and band.fg, vim.inspect(band))
		end)
	end

	test("no repaired group is overwritten by chrome in " .. background, function()
		local restyled = require("parhelion.chrome").groups(background)
		local repaired = refinement.repaired_groups(background, base_table.groups)

		local overwritten = vim.tbl_filter(function(name) return restyled[name] ~= nil end, vim.tbl_keys(repaired))

		expect_none(overwritten, "repaired groups never reach the screen")
	end)
end

local stock_backdrop_opacity, widest_dimming = 0.4, 1.5

for _, background in ipairs { "dark", "light" } do
	for _, group in ipairs { "FzfLuaBackdrop", "LazyBackdrop", "MasonBackdrop" } do
		test(group .. " dims the page without blacking it out in " .. background, function()
			local page = require("parhelion.chrome").scale[background].page
			local backdrop = require("parhelion.chrome").groups(background)[group].bg

			local dimmed = color.mix(page, backdrop, stock_backdrop_opacity)

			assert(color.contrast_ratio(page, dimmed) < widest_dimming, page .. " dims to " .. dimmed)
		end)
	end

	test("a toast title stays neutral and leaves severity to its icon in " .. background, function()
		local groups = require("parhelion.chrome").groups(background)
		local scale = require("parhelion.chrome").scale[background]

		local colored = {}
		for _, level in ipairs { "ERROR", "WARN", "INFO" } do
			table.insert(colored, groups["Notify" .. level .. "Title"].fg)
		end
		for _, level in ipairs { "Error", "Warn", "Info" } do
			table.insert(colored, groups["SnacksNotifierTitle" .. level].fg)
		end

		expect_none(
			vim.tbl_filter(function(fg) return fg ~= scale.strong end, colored),
			"toast titles carrying a color"
		)
	end)
end

test("the one role check reports a group given two roles", function()
	local found = restraint.groups_in_two_roles { first = { quiet = "OilDir" }, second = { strong = "OilDir" } }

	assert(#found == 1 and found[1].group == "OilDir", vim.inspect(found))
end)

test("the one role check reads names in any letter case", function()
	local found = restraint.groups_in_two_roles {
		first = { quiet = "MiniTablineCurrent" },
		second = { strong = "MiniTabLineCurrent" },
	}

	assert(#found == 1, vim.inspect(found))
end)

test("every plugin group holds one role", function()
	local families = require("parhelion.chrome").families

	expect_none(restraint.groups_in_two_roles(families), "groups hold two roles")
end)

local popular = dofile(root .. "/tests/parhelion/popular/views.lua")
local popular_views = popular.list
local shots_directory = vim.env.PARHELION_SHOTS

local function start_popular(view, mode)
	local state = deps .. "/xdg/popular/" .. view.name .. "-" .. mode
	vim.fn.delete(state, "rf")
	assert(vim.system({ root .. "/tests/parhelion/fixture.sh", fixture }):wait().code == 0)

	return Nvim.spawn {
		args = { "-u", root .. "/tests/parhelion/popular/init.lua", "-i", "NONE", "-n" },
		cwd = fixture,
		rows = 36,
		cols = 112,
		env = {
			PARHELION_ROOT = root,
			PARHELION_DEPS = deps,
			POPULAR_HERE = vim.env.POPULAR_HERE,
			POPULAR_VIEW = view.name,
			POPULAR_MODE = mode,
			XDG_DATA_HOME = deps .. "/xdg/data",
			XDG_CONFIG_HOME = state .. "/config",
			XDG_STATE_HOME = state .. "/state",
			XDG_CACHE_HOME = state .. "/cache",
		},
	}
end

local function keep_shot(view, mode, shot)
	if not shots_directory then return end

	vim.fn.mkdir(shots_directory, "p")
	shot.view, shot.mode = view.name, mode
	vim.fn.writefile({ vim.json.encode(shot) }, string.format("%s/%s-%s.json", shots_directory, view.name, mode))
end

for _, mode in ipairs { "dark", "light" } do
	for _, view in ipairs(popular_views) do
		local legible_test = view.name .. " keeps its text legible in " .. mode
		local errors_test = view.name .. " raises no error in " .. mode
		local theme_test = view.name .. " stays inside the theme's colors in " .. mode
		local theme_groups_test = view.name .. " stays inside the theme's colors, by group, in " .. mode
		local scale_test = view.name .. " groups stay on the scale in " .. mode
		local structure_test = view.name .. " groups draw structure without color in " .. mode
		local color_ceiling_test = view.draws_no_code
				and view.name .. " keeps a screen with no code under the color ceiling in " .. mode
			or theme_test
		local color_floor_test = view.labels_on
				and view.name .. " keeps a share of its window's text in color in " .. mode
			or theme_test
		if
			selected_any {
				legible_test,
				errors_test,
				theme_test,
				theme_groups_test,
				scale_test,
				structure_test,
				color_ceiling_test,
				color_floor_test,
			}
		then
			local nvim = start_popular(view, mode)
			local opened, shot = xpcall(function()
				nvim:settle { quiet = 500 }
				view.run(nvim)
				local captured = nvim:capture()
				captured.groups = vim.json.decode(nvim:lua(group_colors_code))
				return captured
			end, debug.traceback)

			if opened then
				keep_shot(view, mode, shot)

				test(
					legible_test,
					function()
						expect_none(
							legibility.illegible_text(shot, legibility.is_line_art_or_icon),
							"color pairs fall under the text floor"
						)
					end
				)

				test(
					errors_test,
					function() assert(not messages(nvim):find "E%d+:", "raised an error: " .. messages(nvim)) end
				)

				test(
					theme_test,
					function()
						expect_none(theme_colors.drawn_outside(shot, legibility.is_icon), "drawn colors are strangers")
					end
				)

				test(
					theme_groups_test,
					function() expect_none(theme_colors.groups_outside(shot.groups), "groups hold strangers") end
				)

				test(
					scale_test,
					function()
						expect_none(restraint.hues_off_the_scale(mode, shot.groups), "groups hold a hue off the scale")
					end
				)

				test(
					structure_test,
					function() expect_none(restraint.colored_structure(shot.groups), "structural groups are colored") end
				)

				if view.draws_no_code then
					test(color_ceiling_test, function()
						local share = restraint.share_of_text_in_color(shot, legibility.is_icon)

						local limit = restraint.largest_share_in_color_without_code
						assert(share <= limit, string.format("%.1f%% of the text is in color", share * 100))
					end)
				end

				if view.labels_on then
					test(color_floor_test, function()
						local surface = require("parhelion.chrome").scale[mode][view.labels_on]
						local window = { rows = { restraint.cells_on(shot, surface) } }

						local share = restraint.share_of_text_in_color(window, legibility.is_icon)

						local limit = restraint.smallest_share_in_color_with_labels
						assert(share >= limit, string.format("%.1f%% of the text is in color", share * 100))
					end)
				end
			else
				record_failure(view.name .. " opens in " .. mode, shot)
			end

			nvim:close()
		end
	end
end

local function groups_of_popular_view(view, mode)
	local nvim = start_popular(view, mode)
	local ok, groups = xpcall(function()
		nvim:settle { quiet = 500 }
		view.run(nvim)
		return vim.json.decode(nvim:lua(group_colors_code))
	end, debug.traceback)
	nvim:close()
	if not ok then error(groups, 0) end

	return groups
end

local staged_signs = {}
for _, kind in ipairs { "Add", "Change", "Delete", "Changedelete", "Topdelete", "Untracked" } do
	for _, column in ipairs { "", "Cul", "Nr" } do
		table.insert(
			staged_signs,
			{ staged = "GitSignsStaged" .. kind .. column, unstaged = "GitSigns" .. kind .. column }
		)
	end
end

for _, mode in ipairs { "dark", "light" } do
	local names = {}
	for _, sign in ipairs(staged_signs) do
		table.insert(names, string.format("gitsigns' %s reads on the gutter in %s", sign.staged, mode))
		table.insert(
			names,
			string.format("gitsigns' %s recedes visibly from %s in %s", sign.staged, sign.unstaged, mode)
		)
	end

	if selected_any(names) then
		local opened, groups = pcall(groups_of_popular_view, popular.by_name.gitsigns, mode)
		local function contrast_on_gutter(name)
			assert(opened, groups)
			return color.contrast_ratio(groups[name].fg, groups[name].bg or groups.SignColumn.bg)
		end

		for _, sign in ipairs(staged_signs) do
			test(string.format("gitsigns' %s reads on the gutter in %s", sign.staged, mode), function()
				local ratio = contrast_on_gutter(sign.staged)

				assert(ratio >= legibility.smallest_staged_sign_contrast, string.format("it reads %.2f:1", ratio))
			end)

			test(
				string.format("gitsigns' %s recedes visibly from %s in %s", sign.staged, sign.unstaged, mode),
				function()
					local staged, unstaged = contrast_on_gutter(sign.staged), contrast_on_gutter(sign.unstaged)
					local difference = color.color_difference(groups[sign.staged].fg, groups[sign.unstaged].fg)

					assert(staged < unstaged, string.format("it reads %.2f:1 against %.2f:1", staged, unstaged))
					assert(
						difference >= legibility.smallest_staged_sign_difference,
						string.format("it differs by %.1f", difference)
					)
				end
			)
		end
	end
end

for _, mode in ipairs { "dark", "light" } do
	local arrows = { "NvimTreeFolderArrowClosed", "NvimTreeFolderArrowOpen" }
	local names = vim.tbl_map(
		function(arrow) return string.format("nvim-tree's %s reads on the tree in %s", arrow, mode) end,
		arrows
	)

	if selected_any(names) then
		local opened, groups = pcall(groups_of_popular_view, popular.by_name["nvim-tree"], mode)

		for index, arrow in ipairs(arrows) do
			test(names[index], function()
				assert(opened, groups)

				local ratio = color.contrast_ratio(groups[arrow].fg, groups.NvimTreeNormal.bg)

				assert(ratio >= legibility.smallest_control_contrast, string.format("it reads %.2f:1", ratio))
			end)
		end
	end
end

vim.fn.delete(fixture, "rf")
report(string.format("\n%d passed, %d failed", passes, #failures))
if passes == 0 and #failures == 0 then report "no test matched PARHELION_TEST_FILTER" end
os.exit((#failures == 0 and passes > 0) and 0 or 1)
