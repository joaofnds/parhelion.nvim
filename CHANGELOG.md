# Changelog

The changes a user can see, newest release first. A change not yet released goes under an Unreleased heading.

## Unreleased

### Added

- Terminal themes for Ghostty, kitty, WezTerm, Alacritty and iTerm2 in `extras/`, in dark and light, with the page,
  text, cursor, selection and terminal colors parhelion uses in Neovim. The README says how to install each.

### Fixed

- The feline statusline says N-PENDING while an operator waits for its motion, and NORMAL again once the operator
  ends, instead of NORMAL throughout.

## 1.0.0 - 2026-11-08

### Added

- `require("parhelion").setup()` with options for a transparent background, dimmer inactive windows, turning bold and
  italic off, overriding any group, and turning off parhelion's groups for one plugin. Options hold across a
  `background` toggle and a reload.
- `:help parhelion`, covering installation, the options, the supported plugins and their theme files.
- ALE, indentmini.nvim, nvim-surround and fzf's own Vim plugin are listed among the supported plugins, so the
  `plugins` option can turn them off. They already drew in parhelion's colors.

### Changed

- Loading parhelion takes about a third of the time it did, and loading it again in the same mode about two fifths. On
  an Apple M5 Pro a first load takes about 1.65 ms instead of 4.4 ms, or 1.3 ms instead of 3.9 ms with `vim.loader`.
- The lualine, barbecue, feline and reactive theme files take about half the time they did when a plugin requires one
  before parhelion loads.

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
- Added and removed lines in a diff are a clear green and red instead of olive and a muted or orange red, in diff
  windows, Neogit, gitsigns, Snacks, Octo and mini.diff's deleted lines, in both modes. So are the changed words inside
  them in diff windows, Neogit and gitsigns.
