# Changelog

The changes a user can see, newest release first. A change not yet released goes under an Unreleased heading.

## Unreleased

### Added

- Terminal themes for Ghostty, kitty, WezTerm, Alacritty and iTerm2 in `extras/`, in dark and light, with the page,
  text, cursor, selection and terminal colors parhelion uses in Neovim. The README says how to install each.
- Types for `setup`'s options. Where lua-language-server loads the plugin, it flags an option of the wrong type in
  the `setup` call, such as `bold = "yes"`. It does not flag a misspelled option name, which `setup` still raises on.

### Changed

- The feline statusline is new. It names the mode in its hue, with the words Neovim's own mode message uses where it
  has them, such as VISUAL LINE and VREPLACE, and shows the git branch, the file name, the diagnostic counts and the
  cursor position. It needs no icon font. A narrow window drops the file's folders, then the branch, the position and
  the counts, so the mode and the file name stay.
- Inlay hints take the comment color in dark mode, as they already did in light, instead of a dim cyan. They read at
  4.02:1 on the page instead of 3.69:1, and stay readable on the cursor line and on diff lines.
- The reactive cursor takes the mode's hue in insert, visual, select, replace and command modes, and keeps parhelion's
  cursor in the others. The reactive cursorline takes the added-line fill in insert mode and the removed-line fill in
  replace mode, and leaves the line as parhelion draws it in the others.
- lazy.nvim's home heading and mason's title are strong and bold on the raised step instead of solid yellow and
  violet, and mason's current tab is strong and bold on the selected step instead of solid blue, with the other tabs
  quiet on raised instead of solid gray.
- Neogit's branch and remote names and the labels that say what happened to a file, such as modified and deleted,
  keep their hue and lose their bold.
- Neogit's hunk headers are quiet on the raised step instead of blue, and the focused one is body text instead of blue.
- The changed words inside a diff line in Neogit and gitsigns keep their word wash and lose their bold, as `DiffText`
  already had.
- The current buffer or tab in Neovim's tab line, bufferline, barbar and mini.tabline keeps its strong text on the
  page and loses its bold.
- The filler rows of a diff window, which stand in for lines the other side lacks, are gray dashes on the page instead
  of on the removed-line wash. With Diffview's `enhanced_diff_hl` on, the lines a change removed take the same look on
  the old side, so they are gray text on the page with no wash.

### Removed

- `require("parhelion.feline").setup()` and its `assets`, `settings`, `mode_colors` and `view` options. A config that
  calls it raises an error, so remove the call.
- The feline statusline's diff counts, language server names, folder name and scroll position, and the macro
  recording and search count it showed when `cmdheight` is 0. Its inactive bar shows the file name instead of the
  file type.
- The reactive cursorline's dimmed line in inactive windows and its selection colors in visual and select modes.

### Fixed

- With `bold` or `italic` set to false, `BoldItalic` drops its bold or italic like every other group, where on
  Neovim's nightly build it used to stay bold and italic. Parhelion now sets `BoldItalic` itself, so the group also
  exists on Neovim 0.12, which defines none.
- The feline statusline names operator-pending mode while an operator waits for its motion, and normal mode again once
  the operator ends, instead of normal mode throughout.
- The reactive cursorline keeps the line number's color in normal mode, where it used to drop it.
- The feline statusline follows a change to 'background'. It used to keep the colors of the mode it was first required
  in until Neovim restarted.
- Bufferline's slanted and sloped separators, its pick labels, its group separator and a visible tab's diagnostics draw
  in parhelion's colors instead of in shades bufferline derives, such as a near black edge on the slant. The selected
  tab draws its indicator, and the name and count of a buffer with an error, on the page instead of on the tab bar's
  fill.
- With `fzf` turned off, a `g:fzf_colors` the user sets to a copy of parhelion's stays set, unless parhelion set the
  variable itself and has not loaded with `fzf` off since.
- `setup` refuses, with parhelion's own message, an override keyed by a number, an override with a color or attribute
  Neovim does not know, and a group name with a character Neovim does not accept. These used to pass `setup` while
  another colorscheme was loaded, and raise at the next `:colorscheme parhelion`. An overrides function whose table has
  such a key raises the same message when parhelion loads.
- The shadows of floats and of the popup menu draw in parhelion's backdrop instead of in Neovim's gray, and keep the
  blends Neovim gives them. Deprecated code is struck through in parhelion's error red instead of in Neovim's.

## 1.0.0 - 2026-11-08

The first release.

### Added

- Dark and light modes that keep Solarized's pages and hues and make its text easier to read where Solarized's is
  faint. In dark mode every accent reaches a 4.5:1 contrast ratio on the page, where Solarized's sit between 3.25 and
  4.75:1, and comments reach 4:1, up from 2.8:1, while staying quieter than code.
- Added and removed lines in a clear green and red, in diff windows and in the git plugins, in both modes.
- Highlight groups for 78 plugins in the same quiet palette, and theme files for lualine, barbecue, bufferline, feline
  and reactive.nvim.
- `require("parhelion").setup()`, with options for a transparent background, dimmer inactive windows, turning bold and
  italic off, overriding any group, and leaving a plugin's groups to the plugin. The options hold across a
  `background` toggle and a reload.
- `:help parhelion`, covering installation, the options, the supported plugins and their theme files.
- A first load takes under 2 ms on an Apple M5 Pro.
