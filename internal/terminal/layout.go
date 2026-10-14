package terminal

// Region uses zero-based terminal cells; W and H are extents, not last indices.
type Region struct {
	X, Y, W, H int
}

type Layout struct {
	Dungeon, Gutter, HUD, Monsters, Messages Region
}

// ComputeLayout follows the source's 79x24 inline panes, expanding only the dungeon.
// Source anchors: crawl-ref/source/viewgeom.cc, HUD_WIDTH=42 and HUD_HEIGHT=13.
func ComputeLayout(width, height int) (Layout, bool) {
	if width < 79 || height < 24 {
		return Layout{}, false
	}

	dungeonW, dungeonH := width-46, height-7
	return Layout{
		Dungeon: Region{
			X: 0,
			Y: 0,
			W: dungeonW,
			H: dungeonH,
		},
		Gutter: Region{
			X: dungeonW,
			Y: 0,
			W: 4,
			H: dungeonH,
		},
		HUD: Region{
			X: dungeonW + 4,
			Y: 0,
			W: 42,
			H: 13,
		},
		Monsters: Region{
			X: dungeonW + 4,
			Y: 13,
			W: 42,
			H: dungeonH - 13,
		},
		Messages: Region{
			X: 0,
			Y: dungeonH,
			W: width,
			H: 7,
		},
	}, true
}
