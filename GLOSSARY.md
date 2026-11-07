# Glossary

**Accent**: one of Solarized's eight saturated colors: yellow, orange, red, magenta, violet, blue,
cyan and green.

**Backdrop**: a translucent layer a plugin draws over the editor behind a float, to push the rest of the screen back.

**Capture**: a treesitter query's name for a syntax node, such as `@function`. Neovim
highlights it with the group of the same name, falling back along the dots, so
`@keyword.export` uses `@keyword` when it has no group of its own.

**Chrome**: the parts of an editor that frame the text being edited, such as borders, titles, lists,
menus, notifications and tab bars.

**Color difference**: how far apart two colors look, where a larger number means further apart.

**Contrast ratio**: a measure of text against its background, from 1:1 to 21:1.

**Extra query**: a treesitter query file a colorscheme ships under `after/queries`, which adds
to the highlighting a parser's own queries give a language.

**Hairline**: the quietest line a theme draws, one step past the surfaces, used for borders and separators.

**Highlight group**: a named set of foreground, background, special color and style
attributes that Neovim applies to text and interface elements.

**Interface accent**: the one accent chrome uses for focus and matches, which is blue.

**Label hue**: the color a kind of short label holds on a plugin screen, such as violet for Neogit's section headers
and yellow for its modified files, so the kind can be found without reading it. It can be violet, orange, magenta or a
lifted cyan, which the interface scale does not hold, or it can reuse the interface accent or a signal color.

**Lightness contrast**: a measure of text against its background, written Lc. It accounts for polarity and runs from 0
to about 106 for dark text on light and 108 for light text on dark.

**Monotone**: one of Solarized's eight low saturation tones, `base03` to `base3`, used for pages and
text.

**Occurrence highlight**: a highlight on the other instances of the word under the cursor, as mini.cursorword and
vim-illuminate draw.

**Polarity**: whether text is lighter than its page, as in dark mode, or darker, as in light mode.

**Selective contrast**: Solarized's idea that brightness contrast stays low while hue carries the
differences between kinds of text, and quiet text recedes.

**Semantic token**: a language server's classification of a piece of source text, which
Neovim highlights through `@lsp.*` groups at a priority above treesitter's.

**Signal color**: an accent that holds one meaning wherever it marks a state: red for errors and removals, yellow for
warnings, conflicts and a change among unchanged things, green for success.

**Surface**: a background on one fixed step of a neutral scale. Parhelion's are float, page, raised and selected.

**Terminal colors**: the 16 ANSI colors Neovim gives to programs running in its terminal
buffers.

**Wash**: a faint tint of a signal or added color that fills a row and sets no text color, so code keeps its syntax.

**Word wash**: a stronger blend of a signal or added color over the page that marks the words that changed inside a
row. It carries strong text.
