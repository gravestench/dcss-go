package terminal

import (
	"testing"

	"dcrawl-go/internal/game"
)

func TestDrawDungeonKeepsPlayerAboveFloorItems(t *testing.T) {
	canvas := NewCanvas(79, 24)
	region := Region{
		X: 0,
		Y: 0,
		W: 37,
		H: 17,
	}

	view := game.View{
		Width: 1,
		Cells: []game.CellView{
			{
				Glyph: '.',
				State: game.Visible,
			},
		},

		Entities: []game.EntityView{
			{
				Role:  "player",
				Glyph: '@',
			},

			{
				Role:  "item",
				Glyph: '!',
			},
		},
	}

	drawDungeon(canvas, region, view, testPresentationPolicy(t))
	center := canvas.cells[8*canvas.width+18]

	if center.text != "@" || center.fg != White {
		t.Fatalf("player layering = %+v", center)
	}
}

func TestDrawDungeonUsesAuthoredMonsterColour(t *testing.T) {
	canvas := NewCanvas(79, 24)
	region := Region{
		X: 0,
		Y: 0,
		W: 37,
		H: 17,
	}

	view := game.View{
		Width: 2,
		Cells: []game.CellView{
			{
				Glyph: '.',
				State: game.Visible,
			},

			{
				Glyph: '.',
				State: game.Visible,
			},
		},
		Entities: []game.EntityView{
			{
				Role:    "monster",
				KindID:  "MONS_PLANT",
				Glyph:   'P',
				ColorID: "red",
			},

			{
				Role:   "monster",
				KindID: "MONS_PLANT",
				Glyph:  'P',
				X:      1,
			},
		},
	}

	drawDungeon(canvas, region, view, testPresentationPolicy(t))
	center := 8*canvas.width + 18

	if canvas.cells[center].fg != Red ||
		canvas.cells[center+1].fg != Brown {
		t.Fatalf("vault colour did not override one monster: %+v %+v",
			canvas.cells[center], canvas.cells[center+1])
	}
}
