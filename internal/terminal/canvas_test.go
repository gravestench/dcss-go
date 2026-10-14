package terminal

import (
	"strings"
	"testing"

	"charm.land/lipgloss/v2"
)

func TestCanvasBoundsAndWideGlyphs(t *testing.T) {
	c := NewCanvas(5, 2)
	c.Put(-1, 0, 'X', White, Black)
	c.Put(5, 0, 'X', White, Black)

	c.Put(4, 0, '界', White, Black)
	c.Write(0, 0, "A界B", Yellow, Black)
	rows := c.PlainRows()

	if len(rows) != 2 || rows[0] != "A界B " || rows[1] != "     " {
		t.Fatalf("canvas rows: %#v", rows)
	}

	c.Put(2, 0, 'x', White, Black)

	if got := c.PlainRows()[0]; got != "A xB " {
		t.Fatalf("overlapping wide glyph left debris: %q", got)
	}
}

func TestCanvasStyledRowsOccupyEveryTerminalCell(t *testing.T) {
	for _, size := range [][2]int{{79, 24}, {120, 40}} {
		c := NewCanvas(size[0], size[1])
		c.Write(0, 0, "界 yellow", Yellow, Black)
		c.Write(size[0]-6, size[1]-1, "bottom", LightRed, Black)
		plain, styled := c.PlainRows(), strings.Split(c.Styled(), "\n")

		if len(plain) != size[1] || len(styled) != size[1] {
			t.Fatalf("%dx%d row counts: %d plain, %d styled", size[0], size[1], len(plain), len(styled))
		}

		for y := range styled {
			if lipgloss.Width(styled[y]) != size[0] || lipgloss.Width(plain[y]) != size[0] {
				t.Fatalf(
					"%dx%d row %d widths: styled %d, plain %d",
					size[0],
					size[1],
					y,
					lipgloss.Width(styled[y]),
					lipgloss.Width(plain[y]),
				)
			}
		}
	}
}
