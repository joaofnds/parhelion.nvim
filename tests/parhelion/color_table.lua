local root = vim.fn.fnamemodify(arg[0], ":p:h:h:h")
package.path = root .. "/tests/parhelion/?.lua;" .. root .. "/lua/?.lua;" .. package.path

local color, legibility, refinement = require "color", require "legibility", require "parhelion.refinement"

local pages = {
  dark = { page = "#002b36", highlight = "#073642" },
  light = { page = "#fdf6e3", highlight = "#eee8d5" },
}

local function contrast(text, background)
  return string.format(
    "%.1f / %.2f",
    math.abs(color.lightness_contrast(text, background)),
    color.contrast_ratio(text, background)
  )
end

local function write(line) io.stdout:write(line, "\n") end

local function print_tones(background)
  write(
    string.format(
      "\n%s: from, to, difference, lightness, hue, then Lc / ratio on the page before and after",
      background
    )
  )
  local sources = vim.tbl_keys(refinement.tones[background])
  table.sort(sources)
  for _, from in ipairs(sources) do
    local to = refinement.tones[background][from]
    local page = pages[background].page
    write(
      string.format(
        "| `%s` | `%s` | %.1f | %+.1f | %+.1f | %s | %s |",
        from,
        to,
        color.color_difference(from, to),
        color.lab(to)[1] - color.lab(from)[1],
        color.hue_shift(from, to),
        contrast(from, page),
        contrast(to, page)
      )
    )
  end
end

local function accent_names()
  local names = vim.tbl_keys(legibility.accents)
  table.sort(names)
  return names
end

local function closest_pairs(tone_of, seen_as)
  local pairs_found = {}
  local names = accent_names()
  for i, first in ipairs(names) do
    for j = i + 1, #names do
      local second = names[j]
      local difference = color.color_difference(
        seen_as(tone_of(legibility.accents[first])),
        seen_as(tone_of(legibility.accents[second]))
      )
      table.insert(pairs_found, { name = first .. "/" .. second, difference = difference })
    end
  end
  table.sort(pairs_found, function(a, b) return a.difference < b.difference end)

  local shown = {}
  for i = 1, 4 do
    table.insert(shown, string.format("%s %.1f", pairs_found[i].name, pairs_found[i].difference))
  end
  return table.concat(shown, ", ")
end

local function print_separation(title, tone_of)
  write("\n" .. title)
  write("  normal vision: " .. closest_pairs(tone_of, function(c) return c end))
  for _, deficiency in ipairs { "deuteranopia", "protanopia" } do
    write("  " .. deficiency .. ": " .. closest_pairs(tone_of, function(c) return color.simulated(c, deficiency) end))
  end
end

print_tones "dark"
print_tones "light"
print_separation("the published accents", function(c) return c end)
for _, background in ipairs { "dark", "light" } do
  print_separation(background, function(c) return refinement.color(background, c) end)
end
