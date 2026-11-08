# Changelog

The changes a user can see. Parhelion has no releases yet, so they all sit under Unreleased.

## Unreleased

### Added

- `require("parhelion").setup()` with options for a transparent background, dimmer inactive windows, turning bold and
  italic off, overriding any group, and turning off parhelion's groups for one plugin. Options hold across a
  `background` toggle and a reload.
- `:help parhelion`, covering installation, the options, the supported plugins and their theme files.
- ALE, indentmini.nvim, nvim-surround and fzf's own Vim plugin are listed among the supported plugins, so the
  `plugins` option can turn them off. They already drew in parhelion's colors.

### Changed

- Loading parhelion takes about 1.5 to 1.9 ms instead of 3.9 to 4.4 ms, and loading it again in the same mode about
  0.7 ms instead of 1.6 ms.
- The barbecue, feline and reactive theme files load in about 0.1 ms instead of 1 to 1.5 ms.

### Fixed

- A selection, a reference to the symbol under the cursor and an underlined diagnostic keep the code's colors instead of
  painting over them.
- A misspelling has a red undercurl instead of a strikethrough, and the other spelling marks have violet, yellow and
  cyan undercurls.
- The current quickfix entry stands out from the others.
- A TODO in a comment is Solarized's bold magenta instead of the color of a variable, and todo-comments and
  mini.hipatterns draw their TODO and NOTE markers in the same magenta.
- Search matches look different from the selection.
- The terminal's colors sit in their ANSI slots.
- The extra queries no longer recolor code under other colorschemes.
- Staged git signs and nvim-tree's folder arrows are readable.
- A patch's hunk header looks different from its added lines.
- Each kind of code has the same hue in light mode as in dark.
- Code stays readable on reactive.nvim's cursorline fills in light mode.
- snacks.nvim's GitHub views draw their states in the theme's colors, so merged, closed and draft items are readable
  in dark mode.
