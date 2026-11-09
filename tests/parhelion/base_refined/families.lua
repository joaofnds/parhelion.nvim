-- The views frame the buffers they compare with a tab bar and window separators, run mini.cursorword, open Neogit and
-- Diffview with their diff lines and marks, and one of the buffers is markdown. Neovim links groups such as VisualNOS to
-- the text overlays. Those are restyled on purpose, and every other chrome group is left out so a leak shows up as a
-- difference.
return {
	"bufferline",
	"diff_lines",
	"diff_marks",
	"diffview",
	"markdown_text",
	"mini_cursorword",
	"neogit",
	"tab_line",
	"text_overlays",
	"window_separators",
}
