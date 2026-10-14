package terminal

import (
	"image/color"
	"strconv"

	"charm.land/lipgloss/v2"
)

// Color values follow crawl-ref/source/defines.h COLOURS (IRGB order).
type Color uint8

const (
	Black Color = iota
	Blue
	Green
	Cyan
	Red
	Magenta
	Brown
	LightGrey
	DarkGrey
	LightBlue
	LightGreen
	LightCyan
	LightRed
	LightMagenta
	Yellow
	White
)

// ANSI's color cube orders red and blue differently than DCSS's IRGB enum.
var ansiColor = [16]int{
	0,
	4,
	2,
	6,
	1,
	5,
	3,
	7,
	8,
	12,
	10,
	14,
	9,
	13,
	11,
	15,
}

func styleColor(tone Color) color.Color {
	if tone > White {
		tone = LightGrey
	}

	return lipgloss.Color(strconv.Itoa(ansiColor[tone]))
}
