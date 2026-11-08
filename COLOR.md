# Parhelion's colors

Parhelion starts from the look of [Solarized](https://ethanschoonover.com/solarized/) and changes it in two ways. It
changes how light its text colors are, because measured against the Solarized specification, Solarized's text is too
faint in specific, nameable places. Pages and hues stay, apart from orange. And it gives plugin interfaces a system of
their own, described under How plugins use color, where surfaces and text stay neutral and short labels hold the hue.
The base tables, `lua/parhelion/base/`, began as the output of
[solarized.nvim](https://github.com/maxmx03/solarized.nvim), which gives each highlight group one of Solarized's
published colors or a shade of its own. Every color changed from them is listed in `lua/parhelion/refinement.lua` or
`lua/parhelion/chrome.lua`. In the Neogit, Diffview and sample file views the suite compares parhelion against the base
tables with those changes applied, and fails on any other difference.

The first file is the refinement, and it holds two kinds of change. A tone is a color that replaces one color from the
base tables everywhere it appears, in one mode. A repaired group is a highlight group parhelion sets directly, because a
plugin derives or hard codes a color for it that is unreadable or foreign to the theme, and no tone can reach that, or
because the base tables leave out one of a set.

To print the tone tables under What changed from the current code:

```sh
nvim -l tests/parhelion/color_table.lua
```

The other tables of measurements in this document were taken once and are not rerun. The tones, the floors and the
chrome scale are enforced, as How the suite holds this lists.

## What the specification says

The [Solarized README](https://github.com/altercation/solarized) makes four claims that matter here:

- "Solarized reduces *brightness contrast* but, unlike many low contrast colorschemes, retains
  *contrasting hues*."
- "The monotones have symmetric CIELAB lightness differences, so switching from dark to light mode
  retains the same perceived contrast in brightness between each value. Each mode is equally
  readable."
- The accents are "based off specific colorwheel relations and subsequently translated to CIELAB to
  ensure perceptual uniformity in terms of lightness".
- Body text on a dark page is `base03:base0`, and on a light page the values are "simply inverted".

Solarized sets comments to `base01` and offers a high contrast mode, which moves each text tone up one step, so body
text becomes `base1` and comments become `base00`. The author therefore shipped the idea that body text can sit one step
higher. That mode alone does not settle the problem, because it leaves dark accents at 3.25 to 3.43:1 and dark comments
at Lc 27.3.

The specification's table states its CIELAB values against a D50 white point, and they match its hex colors there to
within a color difference of 0.9. Under D65 the gap reaches 4.3, on blue, so its numbers should not be read as D65.

## What measuring it shows

Two measures are used throughout. The contrast ratio runs from 1:1 to 21:1, and this document uses 4.5:1 as its floor
for text. Lightness contrast, written Lc, accounts for polarity, whether text is lighter or darker than its page. Where
the two disagree on a dark page this document reports both. In practice 4.5:1 is what set the dark accents, as the
floors below show.

`tests/parhelion/color.lua` defines every measure here: `contrast_ratio`, `lightness_contrast`, `color_difference`, and
`perceptual_lch` for perceptual lightness, chroma and hue.

Equal CIELAB lightness differences do not give equal readability:

| Pair | Ratio | Lc |
| --- | --- | --- |
| Body, dark, `#839496` on `#002b36` | 4.75 | 39.5 |
| Body, light, `#657b83` on `#fdf6e3` | 4.13 | 65.7 |
| Comment, dark, `#586e75` on `#002b36` | 2.79 | 21.5 |
| Comment, light, `#93a1a1` on `#fdf6e3` | 2.48 | 46.7 |

The two measures even disagree on which mode wins, and both comment colors are under 3:1. This document judges that a
dark page has more need of help, and it acts on that for the accents and not for the monotones.

Fixed accents have a second problem. Orange, red, magenta and violet sit at L\* 50. Yellow, green and
cyan sit at L\* 60, and blue at 55. A dark page favors the light group and a light page favors the dark
group, so half the accents are weak in each mode:

| Group | Dark page | Light page |
| --- | --- | --- |
| Orange, red, magenta, violet | 3.25 to 3.43, Lc 27 to 28 | 4.06 to 4.29, Lc 65 to 66 |
| Blue | 4.08, Lc 34 | 3.41, Lc 59 |
| Yellow, green, cyan | 4.68 to 4.75, Lc 39 to 40 | 2.93 to 2.98, Lc 53 to 54 |

Orange and red are also close to each other, with a color difference of 10.1, the smallest of any accent pair by a wide
margin.

Here is where Solarized, its high contrast mode and parhelion put their text:

| Theme | Body Lc | Body ratio | Comment Lc | Comment ratio |
| --- | --- | --- | --- | --- |
| Solarized dark | 39.5 | 4.75 | 21.5 | 2.79 |
| Solarized high contrast, dark | 46.4 | 5.61 | 27.3 | 3.37 |
| **Parhelion dark** | 46.4 | 5.61 | 33.3 | 4.02 |
| Solarized light | 65.7 | 4.13 | 46.7 | 2.48 |
| Solarized high contrast, light | 71.6 | 4.99 | 53.5 | 2.93 |
| **Parhelion light** | 71.6 | 4.99 | 60.0 | 3.50 |

The base tables add a third problem. Neogit computes many colors by darkening a highlight group's foreground by 18%, and
under the base tables that makes a `deleted` label Lc 18 and 2.35:1 on a dark page. Neogit's active item row puts a
commit hash at Lc 0, which is unreadable.

## The rules parhelion follows

These rules govern the tones in `lua/parhelion/refinement.lua`. Plugin interfaces follow rules of their own under How
plugins use color, and they go further: `Directory` moves from blue to the neutral strong step.

1. Page colors keep their values: `#002b36`, `#073642` and `#002731` in dark, `#fdf6e3`, `#eee8d5` and
   `#fbf3db` in light. They are most of what makes the theme look like Solarized.
2. Color moves in lightness and keeps its hue. The move happens in a perceptual lightness, chroma and hue space,
   because CIELAB shifts hue as lightness changes, most of all in blue, the accent this theme uses most. Chroma stays
   the same unless sRGB cannot hold it, apart from dark body, which moves to the published `base1` and loses 19% of its
   chroma, and the cursor line number's background. With chroma held and lightness raised, dark mode's orange, red,
   magenta and violet each lose about 12% of their saturation, measured as chroma over lightness, so a brighter red does
   not also become a more vivid one. Light mode's blue, cyan and violet go the other way and gain 7 to 10%, since
   darkening a color at the same chroma raises that ratio.
3. Body text moves one step up Solarized's own ladder and stops there. Dark body is the published
   `base1`, and light body is the published `base01`.
4. Each accent gets its own value per mode. Green and cyan in dark and red and magenta in light keep
   their published values. Yellow in dark, and orange and violet in light, cleared the floors and moved
   anyway, because rule 6 needs them apart from the accents around them.
5. No tone moves further than a color difference of 10.5 from its source. That limit is a judgment and not a standard.
   It sits just above the largest tone, 10.2, and holds the result in place as the floors below do.
6. Lightness stays uneven on purpose. Making all accents equally light removes the cue a red-green
   colorblind reader relies on, as simulating it showed, so blue and yellow stay lighter than the others
   in dark, and orange and violet stay darker than the others in light.

The floors, tested on every load path:

| Text | Dark | Light |
| --- | --- | --- |
| Body | 5.5:1, Lc 46 | 4.9:1, Lc 71 |
| Code and interface accents | 4.5:1, Lc 38 | 4:1, Lc 64 |
| Comments, line numbers, inlay hints | 3:1, Lc 30 | 3:1, Lc 55 |
| Any text cell in a tested view, and any group's text | Lc 30 | Lc 30 |
| A text cell over the selection in a tested view | Lc 20 | Lc 20 |

These floors are not standards. Each one sits just under what the chosen tones reach, so they hold the result in place
and do not show that the result is right. The selection's sits under comments over the dark selection, at Lc 23.9. Dark
accents stop at 4.5:1, and their Lc follows from that. A cell at Lc 30 is present and findable, not comfortable.
Comments stay at least Lc 10 below body text, so selective contrast survives.

The floors are measured on the page. On the cursor line, which is a step closer to the text, dark body
falls to 4.86:1, dark accents to 3.90 to 4.70:1 and dark comments to 3.48:1. Light body falls to 4.39:1,
light accents to 3.52 to 4.29:1 and light comments to 3.08:1.

## What changed

Difference is measured from the source color, computed under D65, and lightness is the change in L\*. Hue
is the shift in degrees of perceptual hue, which means little for the near neutral monotones. Each contrast column gives
Lc and ratio on the page.

Dark:

| From | To | Difference | Lightness | Hue | Before | After | Role |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `#839496` | `#93a1a1` | 4.5 | +5.1 | -8.4 | 39.5 / 4.75 | 46.4 / 5.61 | Body text |
| `#93a1a1` | `#a3b1b1` | 4.7 | +6.0 | +0.0 | 46.4 / 5.61 | 55.1 / 6.78 | Keywords, statusline |
| `#586e75` | `#71888f` | 10.2 | +10.2 | -1.0 | 21.5 / 2.79 | 33.3 / 4.02 | Comments, line numbers |
| `#268bd2` | `#40a0e8` | 6.9 | +7.8 | -0.2 | 34.3 / 4.08 | 44.4 / 5.30 | Functions, identifiers |
| `#6c71c4` | `#8188dd` | 8.3 | +8.8 | -0.4 | 28.0 / 3.43 | 38.8 / 4.65 | Constants, special characters |
| `#cb4b16` | `#e56824` | 9.6 | +9.4 | +5.3 | 27.2 / 3.26 | 38.5 / 4.53 | Types |
| `#dc322f` | `#f95148` | 9.1 | +9.4 | +0.1 | 27.7 / 3.25 | 38.7 / 4.50 | Errors, deletions |
| `#d33682` | `#ef5299` | 8.7 | +9.1 | +0.2 | 28.0 / 3.30 | 38.7 / 4.53 | Regexes, markup emphasis |
| `#b58900` | `#c1951e` | 3.9 | +4.5 | +0.3 | 39.2 / 4.68 | 45.2 / 5.42 | Warnings, modified |
| `#0c4e53` | `#0b474c` | 2.3 | -2.8 | +0.7 | | | Cursor line number background |

Light:

| From | To | Difference | Lightness | Hue | Before | After | Role |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `#657b83` | `#586e75` | 5.2 | -5.2 | -2.8 | 65.7 / 4.13 | 71.6 / 4.99 | Body text |
| `#586e75` | `#4c6168` | 4.8 | -5.2 | +1.0 | 71.6 / 4.99 | 77.1 / 6.05 | Keywords |
| `#93a1a1` | `#798686` | 9.0 | -10.3 | -0.1 | 46.7 / 2.48 | 60.0 / 3.50 | Comments, inlay hints |
| `#839496` | `#728284` | 6.4 | -6.9 | +0.5 | 53.5 / 2.93 | 62.1 / 3.71 | Quiet interface text |
| `#268bd2` | `#117fc5` | 4.4 | -4.5 | -0.1 | 58.7 / 3.41 | 64.1 / 4.00 | Functions, identifiers |
| `#2aa198` | `#018880` | 8.7 | -9.2 | +0.2 | 53.1 / 2.93 | 64.3 / 4.03 | Strings |
| `#859900` | `#708101` | 8.6 | -8.8 | -0.0 | 53.8 / 2.97 | 64.7 / 4.03 | Statements, added lines |
| `#b58900` | `#997401` | 8.4 | -8.6 | +0.5 | 53.8 / 2.98 | 64.5 / 4.01 | Warnings, modified |
| `#cb4b16` | `#b74a00` | 5.5 | -3.7 | +5.3 | 65.8 / 4.27 | 70.0 / 4.88 | Types |
| `#6c71c4` | `#6165b7` | 4.7 | -4.7 | +0.1 | 65.0 / 4.06 | 70.3 / 4.80 | Constants, special characters |

Orange is the only saturated hue that moves. Five degrees toward yellow, in both modes, takes its difference
from red from 10.1 to 13.8 in dark and 14.6 in light. The specification's author made the same kind of
adjustment, since its hues "have been adjusted within a small range to achieve the most pleasing combination
of colors".

`refinement.repaired_groups` then fixes what the tones cannot reach, in both modes unless a row says
otherwise:

| Groups | Before | After |
| --- | --- | --- |
| Neogit graph grey, Buffon unloaded buffers | As low as Lc 8.3 in dark and 22 in light | The comment color |
| `LspInlayHint` | A dim cyan in dark and the comment color in light, so its hue changed with the mode | The comment color |
| `LineNr`, `NonText`, `Whitespace`, light only | Darker than body text, so the gutter read louder than the code | Lighter than body text, `#6c7c80` on the gutter and `#728284` on the page |
| `OkMsg`, Neogit's white graph rows, fzf.vim's status line | Fixed colors from Neovim or the plugin, such as `#b3f6c0` and white on black | The theme's success and body colors, and the status line |

The one color above that appears in neither the base tables nor the tone tables is light's `#6c7c80`.

## How plugins use color

Code needs many hues, because hue is what tells kinds of code apart. A plugin screen needs them for another reason. It
is mostly short labels, and this document infers, with no study behind it, that a reader finds a kind of label faster by
its color than by reading it. So the labels hold hue and the text between them does not. That holds where a screen puts
many kinds of label side by side, as Neogit, Diffview, which-key and markdown do. A picker, a menu or a file tree shows
rows of one kind, where a hue on every row would mark nothing and would take attention from the match, so they keep to
neutrals, the accent and the signal colors. That split is a judgment from looking at the screens and not a measurement.

`lua/parhelion/chrome.lua` gives the first group Solarized's hues on Neogit, Diffview, which-key, mason and markdown,
and gives mini.clue which-key's looks. It works through a scale of steps, the eight accents toned, a short table of
label hues, roles built from those, families that assign plugin groups to a role, and links that make a plugin group
follow another group.

The rules, in both modes:

1. Text and structure stay neutral. Surfaces, borders, separators, guides and the text between labels are steps on one
   scale. Which-key's descriptions are the exception, and mini.clue's match them: they hold a label hue.
2. In a plugin with label families, each kind of label holds one hue within that plugin, so it can be found without
   being read. Neogit, Diffview, which-key, mini.clue, mason, lazy.nvim, todo-comments, mini.hipatterns and the markdown
   plugins have them. A TODO or NOTE marker from todo-comments or mini.hipatterns holds the magenta the core `Todo`
   group takes, so a marker looks the same whichever of them draws it. Mason's headers and tags are filled blocks of
   violet, blue, green, yellow and the quiet step, and its secondary highlight is magenta. lazy.nvim's load reasons and
   buttons follow the core groups lazy.nvim links them to, such as `Constant` for an event and `Statement` for keys, so
   they take the code's colors. Its home heading links to `IncSearch` and takes the current match's yellow fill. Its
   section titles and times take the core `Bold` group, which parhelion sets to bold alone, and its dimmed text is
   quiet. The same kind of label can differ between plugins, so a key is violet in a Neogit popup and blue in which-key.
   A title adds bold to its hue in Neogit, Diffview and mason. Elsewhere a window's main title holds the strong step and
   bold, as `FloatTitle`, `TelescopeTitle` and `NeoTreeRootName` do, and a secondary one is quiet. Hashes and kinds stay
   quiet. Counts stay quiet too, apart from Neogit's section headers and Diffview's panel, where they are body.
3. One interface accent, Solarized blue, marks focus and matches. In Neogit, Diffview and Trouble it also marks paths,
   folders and popup titles. Other plugins' directories and paths stay neutral.
4. A signal color keeps one meaning everywhere: red for errors and removals, yellow for warnings, conflicts and a change
   among unchanged things, as in the gutter or a file tree, and green for success and for added things. Diffs are where
   parhelion leaves Solarized's mapping, whose dark tables paint added lines blue, the accent's color, while a reader
   expects a diff in green and red. So `Added`, `@diff.plus`, the gutter's added sign and every plugin's added mark are
   green in both modes. A diff's changed rows and words are tinted blue, the one place the accent's hue marks a change,
   while the gutter's changed sign stays yellow. Neovim's `PreInsert` and fzf-lua's `FzfLuaCmdBuf` link to `Added`
   without showing a diff, so they keep the base tables' color. For the same reason oil's pending create takes the
   accent as its copy and restore do, and operator-sandwich draws every highlight on the selected step, so neither turns
   green or red. Hints share the accent, as the base tables' diagnostics do. A label may reuse these hues without the
   meaning, which is how a Neogit tag is yellow, a remote green, and markdown's headings run through the base tables'
   colors.
5. A changed word sits on a word wash, a stronger tint of its row's green, blue or red, and takes strong text. Solid
   fills are for jump labels, which are a character wide, window picker labels, which fill a status line, and the
   current search match, which is one match at a time. Severity sits on an icon or a bar and the text stays
   neutral.
6. A selected row is a neutral step with brighter text, and a focused Neogit hunk header keeps its accent there. That
   borrows the idea of the specification's highlighted pair `base02:base1` and not its values, since dark body is
   already `base1`. The pairs are `#0d414e:#c9ccc3` and `#e2dbc7:#2a4c55`. Most pickers let the row's foreground replace
   the match color, so a match on the selected row keeps only its weight.

| Step | Used for | Dark | L | Light | L |
| --- | --- | --- | --- | --- | --- |
| float | Bordered floats, sidebars | `#002731` | 25.2 | `#fbf3db` | 96.4 |
| page | The buffer | `#002b36` | 26.7 | `#fdf6e3` | 97.4 |
| raised | Cursor line, code blocks, menus with no border | `#073642` | 30.9 | `#eee8d5` | 93.1 |
| selected | List selection, occurrence highlights | `#0d414e` | 34.9 | `#e2dbc7` | 89.2 |
| hairline | Borders, separators, indent guides | `#27505b` | 40.6 | `#c9c6b6` | 82.5 |
| quiet | Icons, kinds, hashes, most counts, the paths beside a file name | `#71888f` | 61.1 | `#728284` | 59.4 |
| body | Text | `#93a1a1` | 69.8 | `#586e75` | 52.3 |
| strong | Titles outside the label families, directories, selected text | `#c9ccc3` | 84.0 | `#2a4c55` | 39.4 |

L is perceptual lightness times 100. Page to raised and raised to selected are each about 4 in both modes, so a
selection reads the same on a page and on a menu. Float against page is only 1.05:1 in dark and 1.03:1 in light, which
is enough behind a hairline and not enough alone, so completion menus, which have no border by default, sit on raised.
which-key has no border by default either and stays on float, which leaves its window's edge faint. On selected, strong
reads at 6.85:1 and 6.71:1, body at 4.17:1 and 3.89:1, and the accent at 3.94:1 and 3.12:1. Quiet is left off a selected
row because it falls under 3:1 there in both modes, and under the legibility floor in dark.

Selected, hairline, strong and the backdrop are not published or toned, and were chosen by eye against these measures.

Selected is the step that keeps the spacing above. Hairline reads at 1.70:1 and 1.59:1 on the page, enough to see a line
and too little to read as content, which also leaves it under 3:1. Strong sits about 60% of the way from body to the
next published monotone, `base2` in dark and `base02` in light, at 9.23:1 and 8.60:1. `base2` itself reaches 12.25:1 in
dark, which reads as white beside body, and strong only has to lead it. The backdrop is below, and the washes are
further down this section.

The `dim_inactive` option puts windows without focus on a dimmed surface. In dark it is `#002029`, L 22.5, 1.13:1 below
the page. Light has no free step below its page, since raised is the only one apart from both the page and the text, so
inactive windows take raised, and their cursor line and gutter, which are raised too, blend into it. On the dimmed
surface quiet text reads at Lc 34.9 in dark and 53.8 in light, and the weakest accent at Lc 40.1, orange, and 55.7,
blue.

Label hues sit apart from the scale, and only the plugins rule 2 names may hold them:

| Hue | Dark | Light |
| --- | --- | --- |
| Description | `#3fb3a9` | `#007a72` |
| Magenta | `#ef5299` | `#d33682` |
| Orange | `#e56824` | `#b74a00` |
| Violet | `#8188dd` | `#6165b7` |

The others are the toned accents, and the description's value is its own. A description is read and not scanned, so it
is held to 4.5:1 where light accents stop at 4:1. That takes light's to a color difference of 5.1 from the toned cyan
and 14.0 from the published one, which is further than a tone may go, as rule 5 of The rules parhelion follows says.

A backdrop dims what sits behind a float. fzf-lua, lazy.nvim and mason default to black at 40%, which suits a dark page,
taking it to `#001a20` at 1.20:1. On a light page the same black gives `#989488` at 2.81:1, a muddy gray larger than the
window it frames. So light mode's backdrop is `#a39c87`, which dims the page to `#d9d2be` at 1.40:1 and keeps its
warmth.

Every group `chrome.lua` names may differ from the base tables, and that file is the complete list. It takes in the
plugins the base tables style, such as telescope, nvim-tree, neo-tree, nvim-notify and noice, the plugins that draw from
core groups, such as which-key, blink.cmp, trouble, flash, fzf-lua and grug-far, and some core groups: `Directory`,
`Title`, `FloatBorder`, `FloatTitle`, `FloatFooter`, `Pmenu*`, `PreInsert`, `WinBar`, `WildMenu`, the tab line, window
separators in every window, the diff lines, `Added`, `@diff.plus`, markdown's Vim syntax headings, `markdownH1` to
`markdownH6`, and the command line's expression groups `NvimFigureBrace`, `NvimInternalError`,
`NvimInvalidSingleQuotedUnknownEscape` and `NvimSingleQuotedUnknownEscape`. A plugin whose default links to one of those
core groups follows it, and gets a family when the result needs a role.

Code syntax, `Normal`, `NormalFloat`, `Comment`, diagnostics, the cursor line and column, the gutter and fold column,
`MatchParen`, `Conceal`, the status line, lualine and the gutter's signs do not differ, apart from the text overlays
below, gitsigns' and gitgutter's added sign and number, which rule 4 makes green, gitsigns' staged signs, and lualine's
count of added lines, which takes that sign's color. gitsigns' line highlights follow the diff lines they link to. A
staged sign takes its unstaged sign's hue mixed 40% of the way toward quiet text in dark and 35% toward the gutter in
light, so it reads at 2.16:1 or more, stays quieter than the sign of a change not yet staged and sits at least 6 from
it. Dark mixes toward quiet text because its unstaged signs sit only Lc 36.5 to 43 over the gutter, and darkening them
enough to set them apart would put them under the text floor. A check in `tests/parhelion/restraint.lua` fails when a
family names one of them, a group Neogit or Diffview uses to stand in for one of them, or a group from a Vim syntax
file. The exceptions are `Added`, `@diff.plus`, `GitSignsAdd`, `GitGutterAdd` and `GitGutterAddLineNr`, which rule 4
colors, the `GitSignsStaged` signs, the text overlays `Visual`, `Search`, `IncSearch`, `LspReferenceRead`,
`LspReferenceText`, `LspReferenceWrite` and the `DiagnosticUnderline` groups, `Todo`, `markdownH1` to `markdownH6`,
`LspKind*`, lspsaga's `DiagnosticText`, nvim-ts-rainbow's `rainbowcol1` to `rainbowcol7` and telekasten's `tk` groups.
render-markdown's heading bands count as the base tables'.

mini.cursorword marks each other instance of the word under the cursor. The base tables recolor those instances teal in
dark and bold magenta on pink in light, which spends the page's strongest color wherever the cursor happens to rest. It
takes the selected step with strong text, which is neutral and stays legible over any word. It marks words inside
comments and plugin views too, where the selected step alone would leave quiet text at Lc 28.2 in dark, under the text
floor, as Neogit's status view shows.

The text overlays are the marks Neovim draws over code. A selection, a reference, a diagnostic and a misspelling tint or
underline it and leave its colors alone, so they never hide what kind of token they cover. A search match and the
current quickfix entry set a text color of their own, because each marks a place to land on and not a kind of token. A
selection keeps the base tables' fill, `#2c4e56` in dark and the pink `#f8e2d9` in light, and sets no text color, where
the base tables also set body text in dark and bold magenta in light. On those fills the accents read at 2.70:1 to
3.25:1 in dark and 3.47:1 to 4.23:1 in light, body at 3.37:1 and 4.32:1, and comments at 2.41:1 and 3.03:1. A search
match takes strong text on a warm fill, toned yellow blended over the light page and toned orange over the dark page,
since yellow over the dark page turns olive. The text reads at 5.18:1 in dark and 5.64:1 in light,
where the base tables draw a dark match as a bold selection. The current match is page text on solid yellow and bold, at
5.42:1 and 4.01:1, so it stands out from the others, and `CurSearch` and `Substitute` follow it. Inside a selection
Neovim draws the selection's fill under a match and keeps the match's text color, so the match still shows in strong
text. A reference to the symbol under the cursor takes the selected step alone, as vim-illuminate's references do, since
a language server marks symbols and never the inside of a comment. A diagnostic underlines its text in the signal color
and leaves the text's own color. A misspelling has a red undercurl, a capitalization hint a violet one, a word from
another region a yellow one and a rare word a cyan one, as Solarized publishes them, where the base tables strike a
misspelling through and color the other three's text. The current quickfix entry takes the selected step with strong
text, where the base tables draw it like every other entry. `Todo`, which is syntax and not an overlay, is magenta and
bold, Solarized's own mark, where the base tables give it the blue of a variable. Neovim links the active signature
parameter, snippet tabstops and `VisualNOS` to the selection and a reference's target to the reference, so those follow.

Neogit's kinds of label hold hue, and two kinds can share one. A section header is violet and bold with a body count, a
branch orange and bold, the checked out branch underlined as well, a remote green and bold, a tag yellow, its distance
blue, and a file's path in a diff or commit view blue. A file's label says what happened to it, in bold: deleted is red,
modified and unmerged yellow, new the added color, renamed violet, updated orange and copied magenta. A popup's titles
are blue and bold, its keys violet, and what is switched on blue. An author is violet, which matches the commit age
Neogit draws with `Special`. Hashes take the comment color. A hunk header is blue on the raised step, and the focused
one is bold on selected. A bad or revoked signature is red, and an expired or unknown one is yellow.

Diffview's panel does the same. Its title and folders are blue and bold, the root path violet and bold, its keys blue,
and the status letters yellow for a modification, a rename or a copy, red for a deletion and the added color for an
addition or an untracked file, so a renamed file differs in hue between Neogit and Diffview. Insertions and deletions
match those letters, the file count is body and hashes stay quiet.

Which-key shows a key in blue and a group in the color the base tables give constants, violet. A description is a lifted
cyan, `#3fb3a9` in dark and `#007a72` in light, which read at 6.17:1 and 4.70:1 on the float where the toned cyan reads
at 4.98:1 and 3.92:1. Its separators and icons are quiet. mini.clue's keys, descriptions and groups take the same looks.

Trouble's file names and directories are blue, its messages body, and its counts, positions and icons quiet.

Markdown keeps the base tables' colors, toned, so headings run through six hues, blue, violet, yellow, orange, red and
magenta in both modes, and emphasis, inline code, links and quotes keep theirs. render-markdown's headings, markview's
and headlines' follow the same order, and render-markdown's bullets and quote bars are quiet. Plain text is the body
step, `#93a1a1` in dark and `#586e75` in light, where the base tables have `#839496` and `#657b83`.

Diff lines are washes and not colored text. The base tables paint added lines blue in dark and green in light, changed
lines yellow, changed words solid teal and the filler solid red, which hides the code's syntax and makes a diff the
loudest screen in the editor. The washes take the hues a reader expects of a diff: green for added, blue for changed and
red for removed, while the gutter's changed sign stays yellow. `DiffAdd` and `DiffChange` tint the row and set no text
color, so code keeps its syntax. `DiffText`, Neogit's inline groups, gitsigns' and mini.diff's put a changed word on a
word wash with strong text. Each word wash differs from its row by a color difference of 10.3 to 14.7, and strong text
reads at 4.52:1 to 6.01:1 on it. That costs a changed word its syntax colors. On a word wash the accents reach 2.20:1 to
2.75:1 in dark and 2.34:1 to 3.40:1 in light, body text 2.75:1 to 3.48:1 and the keyword monotone at most 4.23:1.
Neogit's inline words are bold and `DiffText` is not. `DiffTextAdd`, the text a changed line gains, takes the added word
wash, which differs from the changed row by 15.7 to 32.4. Light's changed row is nearly neutral, a cool tint at hue 202
and chroma 0.015, because a faint blend of blue over the cream page passes through gray, and a bluer row falls outside
the theme's colors. `DiffDelete` draws only the filler rows of a diff window, as quiet dashes on its wash. `DiffChange`
needs its own wash and not the raised step, which is the cursor line's, because a changed line does not always hold a
changed word: undotree, gitsigns' line highlights and `diffopt` `inline:none` draw the row alone. Neogit's hunks,
gitsigns' previews and deleted lines, mini.diff's deleted overlay and Snacks' diffs use the same washes with no text
color, so a change looks the same in each. Neogit's cursor brightens the text on a tinted row and steps up to selected
on a context row.

| Wash | Dark | On page | Light | On page |
| --- | --- | --- | --- | --- |
| Added | `#133c29` | 1.22:1 | `#dcf0e0` | 1.11:1 |
| Changed | `#023751` | 1.19:1 | `#e0eeef` | 1.10:1 |
| Removed | `#4b2730` | 1.17:1 | `#fee6e4` | 1.10:1 |
| Added word | `#256139` | 2.04:1 | `#a9d5bc` | 1.51:1 |
| Changed word | `#135b84` | 2.04:1 | `#9ac5db` | 1.71:1 |
| Removed word | `#853e3e` | 1.97:1 | `#f9c3c0` | 1.43:1 |

The changed word wash is a blend of Solarized's blue over the page, 50% in dark and 46% in light. The added and removed
washes are picked for their hue and not blended from Solarized's green and red, since most of those blends miss the
hue at the strength a wash needs. Green over the cream page stays a yellow green at a perceptual hue of 101 to 113 at
every strength, so it reads as olive rather than as an added line. Green over the dark page keeps an added hue only up
to 28%, which sits too close to its row for a word wash, since a changed word needs a difference of 10. Red over the
cream page leans orange at a row's strength, 63 to 38 at 8% to 25%. Red over the dark page passes through blue, violet
and magenta up to 25%, and at 30% it is a muted red at a chroma of 0.033, under the page's 0.049. A few blends would
pass the checks, such as green at 15% for dark's added row, 2.2 from the picked `#133c29`, but no blend serves all
eight. The added washes sit at a perceptual hue of 152 to 160 and the removed washes at 5 to 23, and the gutter's added
and removed signs and the `Added` and `Removed` groups keep Solarized's green and red. The checks accept an added wash
at 145 to 170 and a removed one at -10 to 30, with more chroma than the page. Those ranges are a judgment, wide enough
to hold each wash here and narrow enough to shut out the olive and orange those blends make. A word's hue can sit away
from its row's: light's changed word by 28.2 degrees, dark's removed word by 17.1, the added words by 8.4 and 8.5, and
the others under 3.

Four measures place the three row washes. A comment clears the floor on each, at Lc 30.2 or more in dark, where the base
tables' dark `#0b4764`, which their `NeogitDiffAddHighlight` uses, leaves it at Lc 25.9. Body text reaches 4.5:1 on
each, which the base tables' light `#f9e2d1`, from `NeogitDiffDeleteHighlight`, misses at 4.31:1. Each sits at a color
difference of at least 6 from the raised step, so a tinted row does not read as the cursor line, which the base tables'
light `#f1eccc`, from `NeogitDiffAddHighlight`, misses at 4.6. And each stays under the chroma of 0.07 that the color
checks read as color. Four rows sit at a limit: dark's added row at the comment floor, Lc 30.2, light's added row at
the body floor, 4.51:1, dark's changed row at the chroma ceiling, 0.069, and light's removed row at the edge of the
theme's colors, 3.95 of the 4 that check allows. Their contrast with the page sits together, 1.17:1 to 1.22:1 in
dark and 1.10:1 to 1.11:1 in light, so the three kinds of line differ in hue and not in lightness.

Every plugin group takes a role in a family or follows a link. A group named for a color, such as `OctoGreen`, takes
that accent, toned, and rainbow delimiters and git graph branches keep their hues.

## Where parhelion agrees with the specification, and where it does not

Agrees:

- The pages, the hue relationships within about one degree apart from orange, and the idea that the
  body color is one tone on a ladder of monotones.
- Reduced brightness contrast. Dark body text sits at 5.61:1.
- Selective contrast, meaning comments recede and hue carries syntax.
- Symmetric L\* steps. Dark body is `base1` and light body is `base01`, which are published values. The
  comment and emphasis tones are not published values, and they still sit within 2.4 L\* of each other's
  distance from the page, against 2.3 in the specification.
- A patch's hunk header links to `Identifier`, blue, as Solarized's own Vim scheme links it. Vim's diff syntax would
  link it to `Statement`, the green of the added lines it heads.

Departs:

- Each mode has its own accents. The specification's shared accents are its elegant idea, and also why
  half of them are weak in each mode.
- Comments and the other quiet monotones leave the published ladder. The published comment tones fall under
  3:1 in both modes, and the next published step up is the body color. Both modes moved by about the same
  L\*, so symmetric L\* steps stay, and with them the gap in readability between the modes.
- "Each mode is equally readable" is not a goal. Light mode stays more readable by Lc, 71.6 against
  46.4. Closing the gap takes dark body to about the strong step, `#c9ccc3`, at Lc 71.5 and a difference of 18.1 from
  `#839496`, and titles and selected text would have nothing left to stand out with. Going part of the way, `#a9bbbd`
  reaches Lc 60.3 at a difference of 11.6, just past the limit, which is a judgment, so this is a choice to keep body
  on the published ladder and not something the numbers force. Darkening the page would also close it, and that stops
  being Solarized.
- The terminal keeps Solarized's published order for black and the six accents it shares with ANSI, and leaves it for
  the rest. Solarized gives the bright slots its monotones, orange and violet, so a program's bright green prints gray,
  and its white and bright white are the light mode's surfaces. Parhelion repeats the six accents in the bright slots,
  so a bright color keeps its hue, and makes white `base1` and bright black `base01`, toned like every other color.
  Black is `base02` in both modes and bright white `base3` in dark and `base2` in light, so each end sits one surface
  step from the page it would vanish into.
- Code keeps its hue across modes, as Solarized's does, but not Solarized's hues. Constants are violet, types orange,
  and imports, includes and macros the bold neutral of keywords, where Solarized gives `Constant` cyan, `Type` yellow
  and `PreProc` orange. Markdown's headings run blue, violet, yellow, orange, red and magenta. Light mode takes these
  from dark mode, so a reader who switches modes keeps the colors they know.

## What this does not do

- Plenty of text stays under 4.5:1. Light mode's yellow, green, cyan and blue sit at about 4.0:1, and
  reaching 4.5:1 costs a difference of about 12 and turns yellow to brown. They match the level the
  specification's L\* 50 accents reach on the same page. Light red and magenta sit at 4.29 and 4.21, and comments
  and inlay hints at 4.02 in dark and 3.50 in light.
- The chrome scale has pairs under 4.5:1 as well, in dark and then light: body on raised at 4.86 and 4.39, body on
  selected at 4.17 and 3.89, the accent on selected at 3.94 and 3.12, quiet on raised at 3.48 and 3.27, and quiet on
  float at 4.21 and 3.61. Quiet text is counts, paths and kinds that the row around it already explains. Raising these
  pairs means less separation between the steps, which is what the hierarchy is made of.
- On the washes, in dark and then light, quiet text reads at 3.29 to 3.44 and 3.35 to 3.37, comments at 3.29 to 3.44 and
  3.16 to 3.17, and the accent and signals at 3.69 to 4.65 and 3.61 to 3.89.
- Red-green colorblind vision is worse served in one respect. Simulated at full severity, the accent pairs closer than a
  difference of 5 go from 3 in the specification to 6 in each mode under deuteranopia, and from 1 to 2 in dark and 1 in
  light under protanopia. Green and orange go from 5.8 to 2.6 in dark and 2.2 in light. Diffs pair green with red, the
  pair this vision confuses most, and carry `+` and `-` signs.
- "Easy on the eyes" is not measured. Everything here measures contrast, and nothing here measures
  comfort over a long session.
- Some plugin colors are out of the theme's reach:
  - File icons keep nvim-web-devicons' own colors, which it sets again after every `ColorScheme`, so a few are dim on
    a dark page: css at 1.87:1 and tsx at 2.28:1 on a float. `color_icons = false` in its setup draws them all in
    `#6d8086`.
  - `cmp.config.window.bordered()` maps a selected row to `Visual`, so it is gray in dark and pink in light. On Neovim
    0.11 and later it also draws no border unless `winborder` is set or a border is passed, and with `Normal:Normal`
    that leaves the menu's text directly over the code. The stock menu, which has neither problem, is what the
    `cmp` view shows, and the `cmp-bordered` view passes `border = "rounded"`.
  - Lualine's default layout puts the diff and diagnostic counts in section b, which this theme inverts, so they
    read at Lc 7.5 to 14. In section c they read clearly, and the suite tests that layout.
  - Bufferline computes its tab backgrounds from `Normal`. With `show_buffer_icons` on it draws each inactive icon on
    a shade the scale does not hold, `#ded8c7` in light and `#002028` in dark. Turning it off avoids this.
  - alpha's stock dashboard paints its header with `Type`, and lspsaga's hover paints its rule with `Type`
    (`lspsaga/hover.lua:146`), so both come out orange. Changing `Type` would change code syntax. alpha's
    `dashboard.section.header.opts.hl` takes another group.
  - neo-tree colors a changed file's name with the same group as its change symbol, and gives the stage symbol its
    own. Parhelion leaves those names colored, since a changed file is what a tree is there to show. `name = {
    use_git_status_colors = false }` in its config keeps the names neutral, as nvim-tree's are.
  - nvim-notify's default renderer draws the title rule with the border's group in a heavy glyph, and it maps
    its inactive window to `NormalNC:NONE`, so its cards have no surface of their own.
  - fidget draws its finished mark with `Constant`, so it is violet.
  - Neogit draws a commit's age with `Special` and a commit view's file count with `Number`. Both are code groups, so
    the age is violet in both modes.
  - Diffview derives `DiffviewDiffAddAsDelete` from `DiffDelete` when `enhanced_diff_hl` is on, so the old side of an
    added block draws in quiet gray at Lc 31.0 with its syntax gone.
  - `LineNr`, `SignColumn` and `DiagnosticSign*` keep the base tables' raised gutter, so a float that turns on line
    numbers or draws a sign shows a short raised strip.
  - `Visual` keeps the base tables' fill, which is gray in dark and pink in light, so a selection changes hue between
    modes.
  - dashboard-nvim's README sets shortcut colors with `@property` and `Label`, which are code syntax groups, so a
    config that copies it shows them in syntax colors.
  - mini.notify blends its window by default, so code shows faintly through it. The view turns blending off, because
    the legibility check reads that faint code as text.
  - The lualine, feline and reactive theme files read the scale, the accents, the mode hues and a few groups from the
    built tables directly, with no roles, so an override does not reach them.
- Staying inside the theme's colors is not looking good. That check finds strangers. A neutral gray or a
  tint of orange on a page passes it, whether or not it looks right, so the plugin sheets are there to be looked
  at.
- Ratio and Lc predict legibility and are not legibility. Nobody has run a reading study on this palette.
  They also describe sRGB values, and take no account of the display or the terminal's font rendering.

## How the suite holds this

The suite renders the base tables with `refinement.lua` applied on top, renders parhelion, and compares every cell and
every group. Only the groups `chrome.lua` names may differ. On the base side it applies ten chrome families and no
others: bufferline, the tab line, window separators, markdown text, mini.cursorword, the diff lines, the diff marks, the
text overlays, Neogit and Diffview, because they frame or fill the buffers the views compare, or Neovim links its own
groups to them. So any other chrome group that reaches a code, Neogit or Diffview screen by accident shows up as a
difference. A change to `refinement.lua`, the base tables or the extra queries applies to both sides and that comparison
stays green, so these tests judge those files and `chrome.lua` themselves:

- `tests/parhelion/approved_files.lua` holds a checksum of the base tables and the extra queries, and
  `tests/parhelion/approved_presets.lua` pins the lualine theme's colors, so changing one means changing its pin on
  purpose. A new query file fails until it has a pin.
- `tests/parhelion/approved.lua` lists one group for each tone, every repaired group and at least one group for each
  role in each family of `chrome.lua` with their exact look, per mode, and each row is a test on the two load paths that
  end in that mode. A test fails when a tone or a role has no pinned group, or when a name has none in the diff lines,
  the diff marks, Diffview, gitsigns, headlines, lazy.nvim, markdown text, markview, mason, mini.clue, mini.diff,
  Neogit, render-markdown or which-key, since those are the families whose hues and washes the other checks accept.
  Changing a tone, a repair, a step or a role means changing this table on purpose.
- On each wash a comment clears Lc 30, body text reaches 4.5:1, and the raised step sits at least 5 away. `DiffChange`
  holds its wash, and Neogit's cursor rows and focused header differ from the rows around them.
- Each added wash sits at a perceptual hue of 145 to 170 and each removed wash at -10 to 30, in both modes, with more
  chroma than the page, so an added line reads green and not olive, and a removed line red and not orange or gray.
- A changed word in a diff window, in Neogit, in gitsigns or in mini.diff differs from its row by a color difference of
  at least 10, and its text holds 4.5:1 on it. Neogit's status and commit views draw the added and removed word washes,
  and Diffview the changed one, in cells on the screen, on every load path.
- A which-key or mini.clue description holds 4.5:1 on the float in both modes.
- With Neogit or Diffview open, on every load path, none of their groups holds a color with perceptual chroma over 0.07
  unless it is a step of the chrome scale or a label hue.
- No family names a group that holds code, a Vim syntax file's group, a diagnostic, an LSP reference, the gutter, the
  fold column, the status line or lualine, or a Neogit or Diffview group that stands in for the page, cursor line,
  gutter or status line, apart from the added syntax groups and gutter signs, gitsigns' staged signs, markdown's Vim
  syntax headings, completion kinds, lspsaga's `DiagnosticText`, nvim-ts-rainbow's columns and telekasten's syntax
  groups. render-markdown's heading bands count as the base tables' too.
- Each new tone stays within the difference limit, and each saturated tone within a degree of its source
  hue, with orange named as the exception. Its source color is one the base tables really use.
- The page colors stay fixed.
- On all four load paths, terminal colors 1 to 6 and 9 to 14 are nearest the toned accent their ANSI names give them,
  black and bright white sit at least 3 from the page, about the step between the page and the raised surface, and
  white, bright black and bright white sit at least 3 from each other.
- Accent pairs stay at least 13 apart.
- Every capture and standard syntax group is the same accent, or neutral, in both modes.
- In a patch, the hunk header sits at least 13 from its added and removed lines in both modes, under Vim syntax and
  under treesitter.
- In the gitsigns view, each staged sign reads at 2:1 or more on the gutter, below the unstaged sign of the same change
  and at least 6 from it, and in the nvim-tree view the folder arrows read at 3:1 or more on the tree, in both modes.
- Code, comments and strong text clear Lc 30 on every line reactive's cursorline preset fills, in both modes.
- Code, comments and strong text clear Lc 30 on the surface `dim_inactive` gives inactive windows, in both modes.
- The groups in the floors table clear them on all four load paths, and comments stay Lc 10 below body.
- Every group that sets a foreground clears Lc 30, unless its name marks it as line art, such as a border, separator
  or guide, or it is on the list of decorations. Both lists are in `tests/parhelion/legibility.lua`.
- Every text cell in Neogit status, the commit view, the commit popup, diffview and 16 sample files clears Lc 30. Only
  the tabline's `▎`, window separators and lualine's two section arrows are exempt.
- Every text cell in the views of `tests/parhelion/popular` clears Lc 30 in both modes. Box drawing, block
  elements and icon glyphs are exempt there, since plugins draw lines with them and pick icon colors
  themselves. A cell over the selection's fill clears Lc 20 instead, because the selection keeps the text's own color
  and quiet text reads at Lc 23.9 on it in dark. nvim-cmp's bordered menu draws its selected row that way.
- Every color those views draw, and every group each view leaves defined, sits within 4 units of straight line CIELAB
  distance of a mix of two theme colors, because plugins derive shades by mixing and a color a
  plugin hard codes lands further out. It is a straight line distance because each color is compared against every mix.
  The 4 sits just above the furthest colors the views hold: light's removed wash `#fee6e4` at 3.95, its added and
  removed word washes at 3.84 and 3.81, and bufferline's computed `#002028` at 3.62. Some strangers pass, such as
  `#888888` at 1.71, and the next check is what catches a hue among them.
  `tests/parhelion/theme_colors.lua` names the groups the theme cannot reach: barbar's fallback target groups, which are
  never drawn because the theme sets the groups they fall back from, the groups lspsaga sets whatever the theme says,
  file icons, Neovim's own debug groups and `Diagnostic*Reverse` groups, and backdrops,
  which are shades under a blended window.
- In those views, no plugin group holds a color with perceptual chroma over 0.07 unless the color is a step of the
  chrome scale, a label hue on a group of Neogit, Diffview, which-key, mini.clue, mason, todo-comments, mini.hipatterns,
  headlines, markview, render-markdown or markdown's headings, or on a sign render-markdown combines from one of those,
  or one of the code's toned accents on a group lazy.nvim's own table links to a core group. A label hue on any other
  plugin fails, and so does one that is on neither table. No border, separator, guide, icon or similar structural group
  outside those label families holds one at all unless its name carries a meaning `tests/parhelion/restraint.lua` lists,
  such as a severity, a git state or the place the interface is waiting on. A plugin group is any group a bare Neovim
  does not define, apart from those on that file's lists, so a plugin added later is checked without anyone naming it.
  The check reads colors and not meaning, so red on a group that is not an error passes, which is why roles are pinned
  and the sheets are looked at. `tests/parhelion/restraint.lua` holds both checks, and names what keeps its color:
  groups named for a hue, hue features such as rainbow delimiters and git graph branches, mini.statusline's mode fills,
  which match lualine's, and groups the plugin sets whatever the theme says, such as file icons and backdrops.
- A view marked as drawing no code, which four are, shows at most 10% of its text in color. Neogit's status, commit and
  popup views show at most 40%. The other views are not bounded. alpha is left out, for the reason given under What this
  does not do, which also means its header is about half of that screen's text.
- Neogit's status, commit and popup views show at least 10% of their text in color, and so does which-key's window, so
  a change that flattens their labels fails. Markdown has no such floor, since a page's color is mostly its syntax. The
  boundary check and the pins on its families hold it.
- No plugin group is assigned two roles in any letter case, which would otherwise leave its color to table order.
- fzf-lua's, lazy.nvim's and mason's backdrops dim the page by under 1.5:1 at those plugins' stock 40%, in both modes.
- An error, warning or info toast's title holds the strong step, in nvim-notify and in snacks, so severity stays on the
  icon.
- Every `g:fzf_colors` key paints the step it means, and still resolves under another colorscheme.
- The metrics reproduce known values.
