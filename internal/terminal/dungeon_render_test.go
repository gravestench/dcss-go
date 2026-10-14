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

	drawDungeon(canvas, region, view)
	center := canvas.cells[8*canvas.width+18]

	if center.text != "@" || center.fg != White {
		t.Fatalf("player layering = %+v", center)
	}
}
