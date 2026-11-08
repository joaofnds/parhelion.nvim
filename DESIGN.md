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
  look, in Solarized's published colors and some shades of their own, before any refinement. They began as the output
  of [solarized.nvim](https://github.com/maxmx03/solarized.nvim).
- A **toned** color has passed through `refinement.color`, which replaces a color from the base tables with parhelion's
  value for that mode.
- A **repaired group** is one `refinement.repaired_groups` sets directly, because no tone can reach it.
- A **plugin-only group** is one parhelion sets and the base tables do not.
- The **built tables** are `lua/parhelion/built/{dark,light}.lua`: every group and terminal color, the named colors an
  override function and the theme files read, the hue the theme files give each mode and the fill `dim_inactive` gives,
  written ahead of time from the base tables, `refinement.lua` and `chrome.lua`. A load reads one and builds nothing.

## Layout

| Path | Purpose |
| --- | --- |
| `colors/parhelion.lua` | Colorscheme entry point |
| `lua/parhelion/init.lua` | The load sequence below, and `setup` |
| `lua/parhelion/build.lua` | Builds the groups from the base tables, `refinement.lua` and `chrome.lua`, and writes the built tables and the terminal themes |
| `lua/parhelion/built/{dark,light}.lua` | The built tables, which `build.lua` writes |
| `lua/parhelion/extras.lua` | Makes the terminal themes from a built table |
| `extras/<terminal>/` | The terminal themes for Ghostty, kitty, WezTerm, Alacritty and iTerm2, which `build.lua` writes |
| `lua/parhelion/plugins.lua` | Each supported plugin's name and the patterns its group names match, for the `plugins` option |
| `lua/parhelion/refinement.lua` | The tones parhelion changes from the base tables, and the repaired groups |
| `lua/parhelion/chrome.lua` | How plugin interfaces use color: the scale of steps, the toned accents, the roles, each plugin's family, and the links |
| `lua/parhelion/base/{dark,light}.lua` | The base tables |
| `lua/lualine/themes/parhelion.lua` | The lualine theme, from the colors in the built tables and their `StatusLine` text. It began as solarized.nvim's |
| `lua/barbecue/theme/parhelion.lua`, `lua/parhelion/bufferline.lua` | The theme files those plugins load. Barbecue's draws from the colors in the built tables, and bufferline's returns no highlights, so the groups bufferline's options name come from `chrome.lua` |
| `lua/reactive/presets/parhelion-*.lua`, `lua/parhelion/feline.lua` | The theme files those plugins load, built from the colors, mode hues and groups in the built tables |
| `after/queries/{css,scss,javascript,tsx,lua}/highlights.scm` | The extra queries, which began as solarized.nvim's |
| `tests/parhelion/` | The test suite |
| `.github/workflows/parhelion.yml` | Runs the suite and the format check in CI |
| `doc/parhelion.txt` | The `:help` page |
| `CHANGELOG.md` | The changes a user can see |
| `LICENSE.md` | The license |
| `assets/*.png`, `assets/shoot/` | The README screenshots, and the script that shoots them: `assets/shoot/shoot.sh assets` re-shoots them after a color change, fetching the suite's plugins first. It needs what the suite needs, agent-browser, oxipng and the Iosevka Term SS08 font, and two runs with the same browser and font give the same images, byte for byte |

Neovim loads the extra queries whenever parhelion's `after` directory is on the runtimepath, whatever colorscheme is
active. So they name their captures under `@parhelion`, such as `@parhelion.function`, and the base tables link each one
to the capture it stands for, here `@function`. Neovim falls a capture back along its dots and nothing else defines
`@parhelion`, so under another colorscheme those captures draw nothing and code looks as it does without parhelion.

## How a load works

`require("parhelion").load()` runs these steps:

1. Reads the built table for the mode, once per Neovim session, with `loadfile` and the table's path, since a
   `require` would search the runtimepath first.
2. Applies the options, as Options below says.
3. `hi clear` when a colorscheme is already active, and otherwise `syntax reset`, which only restores Neovim's default
   groups, as `hi clear` does after clearing every group.
4. Sets `colors_name`, the 16 terminal colors, and `g:fzf_colors` unless the user has set it, which makes fzf-lua and
   fzf.vim draw their pickers from highlight groups. Without it, fzf uses its own dark palette, which puts a black
   selection row on a light page.
5. Sets every group with `nvim_set_hl`, which replaces a whole group. The repaired groups and the families also stop
   Neogit deriving its own dimmed versions, because Neogit leaves a group alone once it has attributes.

`lua/parhelion/build.lua` builds the groups in three layers: the base tables' groups, toned, then the repaired groups,
then `chrome.groups`, every family's groups and then the links. A later layer replaces a group an earlier one set,
whatever case either spells its name in, so a plugin family wins over the base tables. A test keeps a repaired group
from also being named in `chrome.groups`. A failure there, such as a family naming a role `chrome.lua` lacks, raises
when the built tables are written, so it never reaches a load. Groups with the same look share one table in the built
tables, which makes them faster to read, so nothing may change a group's table in place.

After a change to the base tables, `refinement.lua` or `chrome.lua`, write the built tables and the terminal themes
again from the repository's root:

```sh
nvim --headless --clean --cmd "set rtp^=." -c "lua require('parhelion.build').write()" -c "qa!"
```

The `the built tables are what the sources build` tests fail, naming each stale group, until they are written, and a
test named for each stale terminal theme fails too. A running Neovim keeps the table it read first, so restart it to
see the new one.

A load depends on its path. `hi clear` leaves previously linked groups listed but empty, so after toggling from dark to
light `@keyword.type` exists and has no attributes. This is why a dark to light toggle reports more groups than a fresh
start in light.

### Options

`setup` stores the options for every later load and reloads parhelion when it is the active colorscheme. A load applies
them to the built groups in this order: it drops the groups of each plugin turned off, then applies `transparent`,
`dim_inactive`, `bold` and `italic`, and then the overrides, so an override can set what an earlier option removed.
A load collects only the groups the options change, each mapped to a new table, or to `false` for a group it leaves
unset, and writes the built groups around them. So it leaves the built table as it was, and a load with the defaults
copies nothing. The `setup with no options undoes the <option> option` tests fail when an option writes into the built
table.
Each override is first set in a namespace no window draws with, so one Neovim refuses raises before step 3 clears the
active colorscheme, and a `setup` whose reload raises puts the earlier options back.
`:help parhelion-options` says what each one means to a user. The option tests at the end of `tests/parhelion/run.lua`
check each one when started in dark and in light, and that they hold across a toggle and a reload.

### Load time

A load leaves about 2450 groups defined, 384 of them Neovim's own. `tests/parhelion/bench.sh` times it against its
floor, a colorscheme that only reads the same built table and writes its groups, as the median of 40 fresh
`nvim --clean` starts for each mode, with `vim.loader` off and on:

```sh
bash tests/parhelion/bench.sh
```

On an Apple M5 Pro with Neovim 0.12.6, a first load takes about 1.65 ms with `vim.loader` off and 1.3 ms with it on,
1.08 to 1.15 times its floor, and loading again in the same mode takes about 0.65 ms. Timing each step in a copy of
the code puts reading the built table at about 0.75 ms, or 0.4 ms with `vim.loader`, and writing the groups at another
0.73 ms, both of which the floor pays too. What the floor does not pay is reading `init.lua`, about 0.13 ms or 0.08 ms
with `vim.loader`, `syntax reset`, 0.07 ms, and the terminal and fzf colors, 0.02 ms. Taking those timings costs a
little, so they add up to slightly more than the script's. `colors/parhelion.lua` reads `init.lua` by its path when
nothing has required it yet, since a `require` would search the runtimepath first, about 0.05 to 0.1 ms here, and it
stores the module where a later `require("parhelion")` finds it.

The script fails when a load fails or when a first load takes more than 1.25 times its floor. CI does not run it, so
run it after a change to the load or to the built tables. The suite's guards count rather than time, so their results
are the same on every machine:

- `a load with the default options requires no module but parhelion` and `a load with the <option> option requires
  nothing that builds the groups` fail when a load builds the groups again, which takes 2.6 to 2.8 times the floor.
- `a reload with the default options copies no groups` fails when a reload through `:colorscheme parhelion`, the path
  a user takes, allocates more than 32 KB of Lua memory. It allocates about 6 KB, and a table that only holds every
  group takes about 100 KB.
- `a reload with the <option> option copies only the groups it changes` fails when a reload with that option allocates
  more than 32 KB past a copy of the groups it changes. A reload with `bold = false`, which changes about 180 groups,
  allocates about 39 KB, where a copy of every group takes about 500 KB.
- `a reload with the default options runs little more Lua than writing its groups` counts the Lua VM instructions of a
  reload through `:colorscheme parhelion` with the JIT off, and fails at 1.25 times those of a loop that only writes
  the groups. A reload runs 1.03 times as many.

None of them sees work Neovim does in C, such as a second `hi clear`, which only the script catches. Time a load under
`-c luafile`, never `-l`, since `-l` turns on 'verbose', which makes every `nvim_set_hl` many times slower.

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
- The theme files lualine, barbecue, feline and reactive load draw only from the colors of the built tables, and
  from their groups only for these: lualine's and feline's bar text from `StatusLine`, feline's inactive bar from
  `StatusLineNC` and its diagnostic counts from the `Diagnostic` groups, and reactive's resting cursor and line number
  from `Cursor` and `CursorLineNr`. Lualine, feline and reactive's cursor give each mode the hue the built tables'
  `mode_hues` name, so the three agree. Reactive's cursorline preset fills the line with the washes diff lines use, so
  the code drawn over it keeps its contrast. None of these files sees an override, since they read the built tables.
  `tests/parhelion/approved_presets.lua` pins the colors of the lualine theme, of the feline statusline in normal mode
  and of both reactive presets. Feline itself draws parhelion's statusline in every mode a test can reach, which is
  all of them but the prompts, the shell and Ex mode, and the statusline must name the mode in each.

How far that reaches differs by plugin:

- **In a view**: aerial, alpha, barbar, blink.cmp and nvim-cmp with and without borders, bufferline, dap-ui,
  dashboard-nvim, dropbar, fidget, flash, fzf-lua, gitsigns, grug-far, harpoon, hop, vim-illuminate, indent-blankline,
  rainbow-delimiters, lazy.nvim, leap, lspsaga, markview, mason, mini.nvim's editor modules, mini.files, mini.notify,
  mini.pick, mini.starter, nvim-navic, neo-tree, noice, nvim-notify, nvim-tree, oil, overseer, render-markdown, Snacks'
  dashboard, notifier and picker, telescope, trouble, undotree, vim-sneak and which-key. Neogit and Diffview are
  compared cell by cell in the test suite.
- **A family and no view**: Octo, Avante, Beacon, neotest, headlines, lir, git-graph, buffon,
  operator-sandwich, colorful-winsep, symbols-outline, todo-comments, yanky, artio, nvim-ufo, treesitter-context,
  lightspeed, pounce, window-picker, blink.indent, blink.pairs, indentmini, coc.nvim, copilot.vim, dadbod-ui, fern,
  notifier, signify, telekasten, vimwiki and nvim-ts-rainbow. Their roles are checked as groups only.
- **The base tables' own groups**: gitgutter, whose groups the base tables set, apart from the added sign and number,
  which the diff marks set, ALE, whose two signs they set, and fzf's Vim plugin, whose three statusline groups the
  repaired groups link to `StatusLine`.
- **Loaded and nothing else**: `tests/parhelion/plugins.lua` also loads yazi.nvim and nvim-surround, so the group
  comparison runs with them present. Neither has a family or a view, and nvim-surround's one group links to `Visual`.

Passing says the text can be read, and says nothing about how it looks, so the views are also there to be looked at:

```sh
PARHELION_SHOTS=/tmp/shots PARHELION_TEST_FILTER="stays inside the theme's colors in " tests/parhelion/run.sh
python3 tests/parhelion/popular/render.py /tmp/shots /tmp/sheets
```

That writes one HTML sheet for each pair of views, with dark and light side by side. A plugin the views leave out has
only the group check behind it, and nobody has looked at it.

Comparing a sheet's two sides shows each kind of code, and each plugin label, in the same hue in both modes. A suite
test holds that for every capture and standard syntax group.

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

A load reads the built tables, not `chrome.lua`, so write them again after each of these changes, as How a load works
says, before running the views or rendering the sheets.

A family naming a role that does not exist raises with the family's name when the built tables are written, and so do
a link naming a group a family sets and a read of a scale step or hue `chrome.lua` lacks. The
`every plugin group holds one role` test fails when a group sits under two roles. The
`no plugin family restyles what the buffer owns` test fails when a family names a treesitter capture, a diagnostic or
LSP group, a group from a Vim syntax file, a plugin group that draws inside the buffer such as `GitSignsChange` or
`DiffviewNormal`, or a group in the `core_of_the_buffer` list, apart from the exceptions [COLOR.md](COLOR.md) lists.
Both tests live in `tests/parhelion/run.lua`, and the lists they read live in `tests/parhelion/restraint.lua`.

To check it by eye, add the plugin's pinned commit to `tests/parhelion/deps.txt` and a view to
`tests/parhelion/popular/views.lua`, whose `plugins` list names that dependency, then render the sheets above. Add the
plugin to the list in `README.md`.

Add the plugin's repository name to `lua/parhelion/plugins.lua` with the patterns its group names match, and the name to
the list under Plugins in `doc/parhelion.txt`, so the `plugins` option can turn it off. The test
`every group parhelion sets is Neovim's, its own or one plugin's` fails on a group no plugin claims or two claim, and
three more fail on a pattern that matches nothing, on a README plugin with no entry, and on a help list that differs
from the entries.

Every name in a family needs a look pinned in `tests/parhelion/approved.lua` for the diff lines, the diff marks,
Diffview, gitsigns, headlines, lazy.nvim, markdown text, markview, mason, mini.clue, mini.diff, Neogit, render-markdown
and which-key, and every role in any family needs one, because those pins are what fail when a color changes by
accident. The `has a pinned look` tests name what is missing. Each link's resolved look is pinned there too.

A Neogit update can add groups it derives by dimming. The `every Neogit group clears the text floor` test catches those,
and the fix is the group's name under a role in the `neogit` family, with its pin.

### Theme files

Lualine, barbecue, bufferline, feline and reactive load a theme file of their own, and `:help parhelion-theme-files`
says how to point each at parhelion's. Lualine runs its theme file again on every `ColorScheme` event, so it follows a
toggle. Barbecue's, feline's and reactive's files read the mode when first required, so after a toggle they keep the
earlier mode's colors until Neovim restarts. Bufferline's returns no highlights, because `chrome.lua` sets every
group bufferline's `highlights` option names. Bufferline still builds the groups for its icons, for the items of its
`groups` option and for its custom areas from the backgrounds it computes.

The lualine, barbecue, feline and reactive files read their colors from the built table for the mode, through
`require("parhelion").built`, which hands out the table a load uses. Nothing stops a caller changing that table, and a
change to one group's look reaches every group that shares it, so they must not change it. Reading a name the table's
`colors` lack raises, as reading one the scale or the accents lack in `chrome.lua` does. A theme file required after a
load takes about 0.16 to 0.27 ms. One required before any load reads the built table itself, about 1.1 ms or 0.7 ms
with `vim.loader`, and the load then reuses it. The `<theme file> requires no other parhelion module` tests fail when
one requires `chrome.lua`, the refinement or the base tables, which take 1 to 1.7 ms to load.

## The test suite

`tests/parhelion/run.sh` fetches the pinned plugins and parsers through `tests/parhelion/fetch.sh`, then starts two
embedded Neovim instances, one with the base tables and one with parhelion, and compares them. It needs `nvim` 0.12,
`tree-sitter` 0.26.1 or later, `git`, `tar`, `curl`, `fzf`, and a C compiler.

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

The base tables hold 517 groups in dark and 515 in light, from 25 and 24 colors. Set alone on Neovim 0.12.6 with
`--clean`, `nvim_get_hl` lists 719 and 717 groups, from 32 and 31 colors, because it includes the groups Neovim defines
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
- A load sets no Lua global and, with the defaults or any one option, requires nothing that builds the groups. A reload
  copies no groups and runs little more Lua than writing them, and the built tables are what the sources build.
  `chrome.groups` raises when a family names a role `chrome.lua` lacks or a link names a group a family sets.
- The terminal themes in `extras/` are what the built tables give, and every file git tracks there is one of them.
  The Ghostty theme's page, text, cursor, selection and terminal colors are the ones Neovim shows, so a theme that
  maps a color from the wrong group fails. The other four formats take the same colors, but nothing checks that each
  writes them under the right key.
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
