package terminal

import (
	"strings"

	"charm.land/lipgloss/v2"
	"github.com/mattn/go-runewidth"
)

type cell struct {
	text         string
	fg           Color
	bg           Color
	continuation bool
}

// Canvas stores one logical terminal cell per coordinate, including wide-rune tails.
type Canvas struct {
	width  int
	height int
	cells  []cell
}

func NewCanvas(width, height int) *Canvas {
	if width < 0 {
		width = 0
	}

	if height < 0 {
		height = 0
	}

	c := &Canvas{
		width:  width,
		height: height,
		cells:  make([]cell, width*height),
	}

	for i := range c.cells {
		c.cells[i] = cell{
			text: " ",
			fg:   LightGrey,
			bg:   Black,
		}
	}

	return c
}

func (c *Canvas) inBounds(x, y int) bool {
	return x >= 0 && y >= 0 && x < c.width && y < c.height
}

func (c *Canvas) clearAt(x, y int) {
	if !c.inBounds(x, y) {
		return
	}

	i := y*c.width + x

	if c.cells[i].continuation && x > 0 {
		c.cells[i-1] = cell{
			text: " ",
			fg:   LightGrey,
			bg:   Black,
		}
	}

	if !c.cells[i].continuation && x+1 < c.width && c.cells[i+1].continuation {
		c.cells[i+1] = cell{
			text: " ",
			fg:   LightGrey,
			bg:   Black,
		}
	}

	c.cells[i] = cell{
		text: " ",
		fg:   LightGrey,
		bg:   Black,
	}
}

func (c *Canvas) Put(x, y int, glyph rune, fg, bg Color) {
	if !c.inBounds(x, y) {
		return
	}

	w := runewidth.RuneWidth(glyph)

	if w < 1 || w > 2 || x+w > c.width {
		return
	}

	for dx := 0; dx < w; dx++ {
		c.clearAt(x+dx, y)
	}

	i := y*c.width + x
	c.cells[i] = cell{
		text: string(glyph),
		fg:   fg,
		bg:   bg,
	}

	if w == 2 {
		c.cells[i+1] = cell{
			fg:           fg,
			bg:           bg,
			continuation: true,
		}
	}
}

func (c *Canvas) Write(x, y int, value string, fg, bg Color) {
	start := x

	for _, glyph := range value {
		if glyph == '\n' {
			y++
			x = start
			continue
		}

		w := runewidth.RuneWidth(glyph)

		if w == 0 {
			if c.inBounds(x-1, y) {
				i := y*c.width + x - 1

				if c.cells[i].continuation && x > 1 {
					i--
				}

				c.cells[i].text += string(glyph)
			}

			continue
		}

		c.Put(x, y, glyph, fg, bg)
		x += w
	}
}

func (c *Canvas) PlainRows() []string {
	rows := make([]string, c.height)

	for y := 0; y < c.height; y++ {
		var row strings.Builder

		for x := 0; x < c.width; x++ {
			entry := c.cells[y*c.width+x]

			if !entry.continuation {
				row.WriteString(entry.text)
			}
		}

		rows[y] = row.String()
	}

	return rows
}

func (c *Canvas) Styled() string {
	rows := make([]string, c.height)

	for y := 0; y < c.height; y++ {
		var line strings.Builder
		var run strings.Builder
		var fg Color
		var bg Color
		haveRun := false

		flush := func() {
			if !haveRun {
				return
			}

			line.WriteString(lipgloss.NewStyle().Foreground(styleColor(fg)).Background(styleColor(bg)).Render(run.String()))
			run.Reset()
		}

		for x := 0; x < c.width; x++ {
			entry := c.cells[y*c.width+x]

			if entry.continuation {
				continue
			}

			if haveRun && (entry.fg != fg || entry.bg != bg) {
				flush()
				haveRun = false
			}

			if !haveRun {
				fg = entry.fg
				bg = entry.bg
				haveRun = true
			}

			run.WriteString(entry.text)
		}

		flush()
		rows[y] = line.String()
	}

	return strings.Join(rows, "\n")
}
