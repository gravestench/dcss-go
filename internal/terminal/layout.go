package terminal

// Region uses zero-based terminal cells; W and H are extents, not last indices.
type Region struct{ X, Y, W, H int }

type Layout struct{ Dungeon, Gutter, HUD, Monsters, Messages Region }

// ComputeLayout follows the source's 79x24 inline panes, expanding only the dungeon.
// Source anchors: crawl-ref/source/viewgeom.cc, HUD_WIDTH=42 and HUD_HEIGHT=13.
func ComputeLayout(width, height int) (Layout, bool) {
	if width < 79 || height < 24 {
		return Layout{}, false
	}
	dungeonW, dungeonH := width-46, height-7
	return Layout{
		Dungeon: Region{
			0,
			0,
			dungeonW,
			dungeonH,
		},
		Gutter: Region{
			dungeonW,
			0,
			4,
			dungeonH,
		},
		HUD: Region{
			dungeonW + 4,
			0,
			42,
			13,
		},
		Monsters: Region{
			dungeonW + 4,
			13,
			42,
			dungeonH - 13,
		},
		Messages: Region{
			0,
			dungeonH,
			width,
			7,
		},
	}, true
}
