# Parhelion design

Parhelion draws code in a modern take on [Solarized](https://ethanschoonover.com/solarized/), in dark and in light,
with its text colors adjusted for contrast, and gives plugin interfaces a look of their own. [COLOR.md](COLOR.md) gives
the reasoning and every changed color. Plugin support comes from the families in `lua/parhelion/chrome.lua`. See
Plugin support below for how they are checked.

## Terms

[GLOSSARY.md](GLOSSARY.md) holds the words of color and editing. These name parts of this code:

- A **family** is a table in `chrome.lua` that assigns highlight groups to roles. Most serve one plugin, and some serve
  several, such as `jump_labels` for the jump and label plugins and `rainbow` for the bracket colorizers.
- A **role** is a named look in `chrome.lua`, such as `quiet` or `selected_row`, built from the scale's steps, the
  toned accents and the label hues.
- A **link** is an entry in `chrome.links` that makes a plugin group follow another group instead of taking a role. A
  group a family sets cannot also be a link.
- A **load path** is one of the four sequences that can lead to the active colors: started in dark, started in light,
  toggled from dark to light, and toggled from light to dark.
- The **base tables** are `lua/parhelion/base/{dark,light}.lua`: every highlight and terminal color of the Solarized
  look, in Solarized's published colors and some shades of their own, before any refinement.
- A **toned** color has passed through `refinement.color`, which replaces a color from the base tables with parhelion's
  value for that mode.
- A **repaired group** is one `refinement.repaired_groups` sets directly, because no tone can reach it.
- A **plugin-only group** is one parhelion sets and the base tables do not.

## Layout

| Path | Purpose |
| --- | --- |
| `colors/parhelion.lua` | Colorscheme entry point |
| `lua/parhelion/init.lua` | The load sequence below |
| `lua/parhelion/refinement.lua` | The tones parhelion changes from the base tables, and the repaired groups |
| `lua/parhelion/chrome.lua` | How plugin interfaces use color: the scale of steps, the toned accents, the roles, each plugin's family, and the links |
| `lua/parhelion/base/{dark,light}.lua` | The base tables |
| `lua/lualine/themes/parhelion.lua` | The lualine theme, toned |
| `lua/barbecue/theme/parhelion.lua`, `lua/parhelion/bufferline.lua` | The theme files those plugins load. Barbecue's draws from the scale in `chrome.lua`, and bufferline's leaves the tab bar to `chrome.lua`'s groups |
| `lua/reactive/presets/parhelion-*.lua`, `lua/parhelion/feline.lua` | The theme files those plugins load, built from the scale, the accents and the constant hue in `chrome.lua` |
| `after/queries/{css,scss,javascript,tsx,lua}/highlights.scm` | The extra queries |
| `tests/parhelion/` | The test suite |
| `.github/workflows/parhelion.yml` | Runs the suite and the format check in CI |
| `LICENSE.md` | The license |
| `assets/screenshot.png` | The README screenshot |

Neovim loads the extra queries whenever parhelion's `after` directory is on the runtimepath, whatever colorscheme is
active. So they name their captures under `@parhelion`, such as `@parhelion.function`, and the base tables link each one
to the capture it stands for, here `@function`. Neovim falls a capture back along its dots and nothing else defines
`@parhelion`, so under another colorscheme those captures draw nothing and code looks as it does without parhelion.

## How a load works

`require("parhelion").load()` runs these steps:

1. Computes the repaired groups and `chrome.groups`. A failure here, such as a family naming a role `chrome.lua` lacks,
   raises its error and leaves the active colorscheme untouched.
2. `hi clear` when a colorscheme is already active, then `syntax reset`.
3. Sets `colors_name`, the 16 terminal colors, and `g:fzf_colors` unless the user has set it, which makes fzf-lua and
   fzf.vim draw their pickers from highlight groups. Without it, fzf uses its own dark palette, which puts a black
   selection row on a light page.
4. Applies the base tables' groups, toned, with `nvim_set_hl`, which replaces a whole group.
5. Applies the repaired groups.
6. Applies `chrome.groups`, every family's groups and then the links, so a plugin family wins over the base tables. A
   test keeps a repaired group from also being named there. Steps 5 and 6 also stop Neogit deriving its own dimmed
   versions, because Neogit leaves a group alone once it has attributes.

A load depends on its path. `hi clear` leaves previously linked groups listed but empty, so after toggling from dark to
light `@keyword.type` exists and has no attributes. This is why a dark to light toggle reports more groups than a fresh
start in light.

A load takes about 25 ms and leaves about 2440 groups defined, 384 of them Neovim's own, timed around
`vim.cmd.colorscheme` under `nvim --clean --headless -l`.

## Plugin support

`chrome.lua` holds the families for the plugins parhelion supports. Four things check them:

- Every group that sets a foreground clears the text floor on all four load paths. A group
  whose color is meant to vanish, such as an indent guide or a hidden separator, either has a line art word in its name
  or is named in `decorations`, both in `tests/parhelion/legibility.lua`, so a new weak group fails until someone
  decides which it is.
- `tests/parhelion/popular/views.lua` opens the popular plugins in real views, each in dark and light with a throwaway
  language server and git repository, and every text cell has to clear the floor, or a lower one over the selection.
- In each of those views, every drawn color and every group has to stay inside the theme's colors, so a color a plugin
  hard codes fails the test, and no plugin group may spend a hue outside the chrome scale. Two kinds of group are
  exempt: those of the plugins [COLOR.md](COLOR.md) names as using label hues, and those whose names match
  `outside_the_theme_reach` in `tests/parhelion/restraint.lua`, such as `OctoPurple` or `rainbowcol1`.
  [COLOR.md](COLOR.md) gives the measures under How the suite holds this. The fix is the group's name under a role or
  as a link in `lua/parhelion/chrome.lua`, or a new family.
- The theme files barbecue, feline and reactive load draw only from `chrome.lua`, and the lualine theme tones colors of
  its own. Reactive's cursorline preset also darkens its colors. `tests/parhelion/approved_presets.lua` pins the colors
  of the lualine theme, of the feline statusline in normal mode and of both reactive presets.

How far that reaches differs by plugin:

- **In a view**: aerial, alpha, barbar, blink.cmp and nvim-cmp with and without borders, bufferline, dap-ui,
  dashboard-nvim, dropbar, fidget, flash, fzf-lua, gitsigns, grug-far, harpoon, hop, vim-illuminate, indent-blankline,
  rainbow-delimiters, lazy.nvim, leap, lspsaga, markview, mason, mini.nvim's editor modules, mini.files, mini.notify,
  mini.pick, mini.starter, nvim-navic, neo-tree, noice, nvim-notify, nvim-tree, oil, overseer, render-markdown, Snacks'
  dashboard, notifier and picker, telescope, trouble, undotree, vim-sneak and which-key. Neogit and Diffview are
  compared cell by cell in the test suite.
- **A family and no view**: Octo, Avante, Beacon, neotest, headlines, lir, git-graph, buffon,
  operator-sandwich, colorful-winsep, symbols-outline, todo-comments, yanky, artio, nvim-ufo, treesitter-context,
  lightspeed, pounce, window-picker, blink.indent, blink.pairs, coc.nvim, copilot.vim, dadbod-ui, fern, notifier,
  signify, telekasten, vimwiki and nvim-ts-rainbow. Their roles are checked as groups only.
- **The base tables' own groups**: gitgutter, whose groups the base tables set, apart from the added sign and number,
  which the diff marks set.
- **Loaded and nothing else**: `tests/parhelion/plugins.lua` also loads yazi.nvim and nvim-surround, so the group
  comparison runs with them present. Neither has a family or a view.

Passing says the text can be read, and says nothing about how it looks, so the views are also there to be looked at:

```sh
PARHELION_SHOTS=/tmp/shots PARHELION_TEST_FILTER="stays inside the theme's colors in " tests/parhelion/run.sh
python3 tests/parhelion/popular/render.py /tmp/shots /tmp/sheets
```

That writes one HTML sheet for each pair of views, with dark and light side by side. A plugin the views leave out has
only the group check behind it, and nobody has looked at it.

Comparing a sheet's two sides shows code changing hue between modes. The base tables color constants violet in dark and
magenta in light, and types orange and yellow. Plugin interfaces use the same roles in both modes, apart from markdown
headings, lazy.nvim's load reasons, buttons and home heading, which follow the core groups lazy.nvim links them to, and
which-key's and mini.clue's groups, which follow the same swap.

### Adding a plugin

A plugin gets a family in `chrome.lua`, which names each of its groups under the role it takes:

```lua
my_plugin = {
	title = "MyPluginTitle",
	quiet = "MyPluginCount MyPluginPath",
},
```

A group that should look exactly like another group goes in `chrome.links` instead, as
`MyPluginBorder = "FloatBorder"`. A plugin that draws only from core groups needs no family. Nine of mini's modules have
a family, and the others use mini's own links to core groups.

The roles are the looks `chrome.lua` builds in `looks`, and a new one goes there, made from the scale, the accents and
the label hues. The accent roles, such as `violet`, `orange`, `cyan` and `magenta`, are off the scale, so a group under
one fails the off-scale check unless its family uses label hues or its name is in `outside_the_theme_reach`.

A family naming a role that does not exist fails the load with the family's name and keeps the active colorscheme, and
so do a link naming a group a family sets and a read of a scale step or hue `chrome.lua` lacks. The
`every plugin group holds one role` test fails when a group sits under two roles. The
`no plugin family restyles what the buffer owns` test fails when a family names a treesitter capture, a diagnostic or
LSP group, a group from a Vim syntax file, a plugin group that draws inside the buffer such as `GitSignsChange` or
`DiffviewNormal`, or a group in the `core_of_the_buffer` list, apart from the exceptions [COLOR.md](COLOR.md) lists.
Both tests live in `tests/parhelion/run.lua`, and the lists they read live in `tests/parhelion/restraint.lua`.

To check it by eye, add the plugin's pinned commit to `tests/parhelion/deps.txt` and a view to
`tests/parhelion/popular/views.lua`, whose `plugins` list names that dependency, then render the sheets above. Add the
plugin to the list in `README.md`.

Every name in a family needs a look pinned in `tests/parhelion/approved.lua` for the diff lines, the diff marks,
Diffview, gitsigns, headlines, lazy.nvim, markdown text, markview, mason, mini.clue, mini.diff, Neogit, render-markdown
and which-key, and every role in any family needs one, because those pins are what fail when a color changes by
accident. The `has a pinned look` tests name what is missing. Each link's resolved look is pinned there too.

A Neogit update can add groups it derives by dimming. The `every Neogit group clears the text floor` test catches those,
and the fix is the group's name under a role in the `neogit` family, with its pin.

### Theme files

Some plugins load a theme file of their own:

| Plugin | How to use it |
| --- | --- |
| lualine | `theme = "parhelion"` |
| barbecue | `theme = "auto"` finds it through `colors_name`, or `theme = "parhelion"` |
| bufferline | Nothing to set. `highlights = require("parhelion.bufferline").get_theme()` also works and adds nothing, because `chrome.lua` sets `BufferLine*` |
| feline | `require "parhelion.feline"` |
| reactive | `load = { "parhelion-cursor", "parhelion-cursorline" }` |

Barbecue's, feline's and reactive's files read the mode when first required, so after a toggle they keep the earlier
mode's colors until they are reloaded or Neovim restarts.

## The test suite

`tests/parhelion/run.sh` fetches the pinned plugins and parsers, then starts two embedded Neovim instances, one with the
base tables and one with parhelion, and compares them. It needs `nvim` 0.12, `tree-sitter` 0.26.1 or later, `git`,
`tar`, `curl`, `fzf`, and a C compiler.

The base instance loads the `base_refined` colorscheme in `tests/parhelion/base_refined`, which sets the base tables,
applies `lua/parhelion/refinement.lua` on top, and then applies the `chrome.lua` families that frame or fill the buffers
the views compare, or that Neovim links its own groups to: `bufferline`, `tab_line`, `window_separators`,
`markdown_text`, `mini_cursorword`, `diff_lines`, `diff_marks`, `text_overlays`, `diffview` and `neogit`. On a load path
that starts in that mode, this happens before any plugin derives colors from it. On a toggled path the plugins have
already derived from the other mode, and they derive again on the `ColorScheme` event. So in the list below, "same"
means the same as the base tables with those applied, and any other group `chrome.lua` names is left out of the group
comparison and held by its own tests. Both sides share what the base side applies, so `tests/parhelion/approved.lua`
pins what it produces, `tests/parhelion/approved_files.lua` holds a checksum of the base tables and the extra queries,
and `tests/parhelion/approved_presets.lua` pins the theme files' colors, so changing one means changing its pin on
purpose. The tests that judge `refinement.lua` and `chrome.lua` are listed in [COLOR.md](COLOR.md).

The base tables hold 509 groups in dark and 506 in light, from 25 and 24 colors. Set alone on Neovim 0.12.6 with
`--clean`, `nvim_get_hl` lists 711 and 708 groups, from 32 and 31 colors, because it includes the groups Neovim defines
itself. In them `Normal` is `#839496` on `#002b36` and `#657b83` on `#fdf6e3`.

Every comparison runs on all four load paths. The checks on query files run once, since no load path affects them.

- Every base group outside the groups `chrome.lua` names resolves to the same fg, bg, sp and style attributes.
- All 16 terminal colors match.
- `colors_name` is `parhelion`.
- Plugin-only groups' foreground and special colors are ones the base tables set, once refined, or steps of the scale
  and label hues in `chrome.lua`, and their links reach a defined group. No plugin-only group is a
  treesitter capture, which would break capture fallback.
- Plugin-only groups listed in `tests/parhelion/roles.lua` take the color of their nearest equivalent, which catches a
  group given the wrong role. The list is a sample, so a role it leaves out goes unchecked.
- A load sets no Lua global. It raises and keeps the active colorscheme when a family names a role `chrome.lua` lacks,
  and `chrome.groups` raises when a link names a group a family sets.
- Parhelion sets no flash, mason or which-key group outside `chrome.lua`. Plugins that draw only from core groups,
  such as grug-far, oil, trouble and undotree, are held by their views.
- Neogit status, Neogit commit view, Neogit commit popup, diffview, and 16 sample files render the same text, fg, bg, sp
  and flags in every cell of a 130 by 50 grid, lualine and the restyled tabline included, once the families that restyle
  those screens are applied to the base side too, as [COLOR.md](COLOR.md) lists. Neogit builds its hint row in a random
  order, so the cells of that row are sorted before they are compared. Sample files also raise the same messages, and
  every group is compared again after each plugin view opens.
- The css, scss, javascript, tsx and lua samples render the same under a fake language server that marks every
  identifier as a `type` semantic token. The lua and javascript queries only change the screen when a language server is
  attached, because their priorities of 130 and 127 exist to beat semantic tokens at 125. The tsx query also changes it
  with no server.
- Each extra query parses, each of its patterns matches its sample, and each capture it names draws a color.
- Under Neovim's default colorscheme, in dark and light and under the fake language server, the css, scss, javascript,
  tsx and lua samples render the same with parhelion on the runtimepath as without it.
- The base tables and the extra queries hold the contents `tests/parhelion/approved_files.lua` pins, and every query
  file has a pin. The lualine theme, the feline statusline and the reactive presets hold the colors
  `tests/parhelion/approved_presets.lua` pins.
- Every Neogit group clears the text floor once Neogit has derived its own, and the pinned look holds with each plugin
  view open.
- The popular plugin views and the plugin side theme files, as described under Plugin support.

Set `PARHELION_TEST_FILTER=<substring>` to run the tests whose name contains it. A filter that matches nothing exits
non-zero. The whole suite takes about seven minutes.

`.github/workflows/parhelion.yml` runs the suite and a StyLua check on a pull request and on a push to `main`, which
needs the repository hosted on GitHub. In a clone with no such remote they only run by hand, the check as `stylua
--check --config-path=stylua.toml .`.

### When a parser update breaks a query

Neovim raises an error whenever it highlights a language whose query names a node or field the parser no longer has. The
weekly `parser-drift` CI job runs the suite against the newest nvim-treesitter, while the pinned job stays green. With
no CI, a break shows up first as an error in the editor. An editor that tracks nvim-treesitter's `main` can also hit the
break before that job runs. To check at any time, which also reinstalls the parsers:

```sh
PARHELION_TREESITTER_REF=main tests/parhelion/run.sh
```

The fix has three parts:

1. Rename the node or field in `after/queries/<language>/highlights.scm`, keeping the capture and priority. Delete the
   pattern if the parser dropped the node with no replacement. The file's test prints its new checksum, which goes in
   `tests/parhelion/approved_files.lua`.
2. Move the `nvim-treesitter` commit in `tests/parhelion/deps.txt` to one that has the new parser, then delete the
   directory `PARHELION_DEPS` points at, by default `${XDG_CACHE_HOME:-$HOME/.cache}/parhelion-test-deps`, because
   installed parsers are kept otherwise.
3. Run `tests/parhelion/run.sh` with no overrides.

GitHub turns scheduled workflows off in a public repository after 60 days with no activity. That stops this job without
a failure, so check that it is enabled.

## Plugin-only colors

Octo's diff tints are named in its family and take the washes, so a change in an Octo review looks the same as in a diff
window.
