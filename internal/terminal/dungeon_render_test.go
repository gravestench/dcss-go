package terminal

import (
	"reflect"
	"testing"

	"crawl/internal/game"
	"crawl/internal/terrain"
)

// Both directions of the Ossuary portal keep distinct terrain IDs, while
// the dungeon renderer draws their shared arch glyph at the visible cell.
func TestDrawDungeonOssuaryPortals(t *testing.T) {
	for _, id := range []terrain.ID{
		terrain.EnterOssuary,
		terrain.ExitOssuary,
	} {
		t.Run(string(id), func(t *testing.T) {
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
						Glyph: terrain.Glyph(id),
						State: game.Visible,
					},
				},
			}

			drawDungeon(canvas, region, view, testPresentationPolicy(t))

			cell := canvas.cells[8*canvas.width+18]

			if cell.text != "∩" {
				t.Fatalf("Ossuary portal %s drew %q", id, cell.text)
			}
		})
	}
}

// The live Bailey gate and its return arch use the original portal glyph
// while Lua travel distinguishes their separate terrain identities.
func TestDrawDungeonBaileyPortals(t *testing.T) {
	for _, id := range []terrain.ID{
		terrain.EnterBailey,
		terrain.ExitBailey,
		terrain.StoneArch,
	} {
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
					Glyph: terrain.Glyph(id),
					State: game.Visible,
				},
			},
		}

		drawDungeon(canvas, region, view, testPresentationPolicy(t))

		if got := canvas.cells[8*canvas.width+18].text; got != "∩" {
			t.Errorf("Bailey portal %s drew %q", id, got)
		}
	}
}

// Source portal arches share the glyph while separate feature IDs let Lua
// distinguish paid entry, temporary return, and expired outside gates.
func TestDrawDungeonPortals(t *testing.T) {
	for _, id := range []terrain.ID{
		terrain.EnterIceCave,
		terrain.ExitIceCave,
		terrain.EnterVolcano,
		terrain.ExitVolcano,
		terrain.EnterTrove,
		terrain.ExitTrove,
		terrain.ExpiredPortal,
	} {
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
					Glyph: terrain.Glyph(id),
					State: game.Visible,
				},
			},
		}

		drawDungeon(canvas, region, view, testPresentationPolicy(t))

		if got := canvas.cells[8*canvas.width+18].text; got != "∩" {
			t.Errorf("portal %s drew %q", id, got)
		}
	}
}

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

// A saved vault colour belongs to the terrain cell and reaches the palette
// through the same Lua presentation policy as other terminal colours.
func TestDrawDungeonUsesLiveCellColour(t *testing.T) {
	g, err := game.NewScenario(7, "WPN_RAPIER", "Presenter")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

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
				Glyph:   '#',
				State:   game.Visible,
				ColorID: "lightmagenta",
			},
		},
	}

	drawDungeon(canvas, region, view, g.PresentationPolicy)

	cell := canvas.cells[8*canvas.width+18]

	if cell.fg != LightMagenta {
		t.Fatalf("live cell tint = %d, want %d", cell.fg, LightMagenta)
	}
}

// Source ETC_RANDOM draws from a separate UI stream on every redraw.
// Rendering must change visible colour without advancing saved game RNG.
func TestDrawDungeonAnimatesRandomColourWithoutGameState(t *testing.T) {
	g, err := game.NewScenario(7, "WPN_RAPIER", "Presenter")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	before := g.Snapshot()
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
				Role:          "monster",
				KindID:        "MONS_KILLER_KLOWN",
				Glyph:         'p',
				ColorID:       "ETC_RANDOM",
				AnimatedColor: true,
			},
		},
	}

	region := Region{
		X: 0,
		Y: 0,
		W: 37,
		H: 17,
	}

	seen := make(map[Color]bool)

	for range 32 {
		canvas := NewCanvas(79, 24)

		drawDungeon(canvas, region, view, g.PresentationPolicy)

		color := canvas.cells[8*canvas.width+18].fg

		if color < Blue || color > White {
			t.Fatalf("random element colour %d is outside source IRGB range", color)
		}

		seen[color] = true
	}

	if len(seen) < 2 {
		t.Fatal("random element colour did not change across redraws")
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("UI colour draws changed saved gameplay state")
	}
}

// The app needs an idle redraw only when an animated source entity or cloud
// is visible; static dungeon screens have no recurring visual timer.
func TestVisibleAnimatedColorChecksEntitiesAndClouds(t *testing.T) {
	view := game.View{}

	if visibleAnimatedColor(view) {
		t.Fatal("empty view requested animation")
	}

	view.Entities = []game.EntityView{
		{AnimatedColor: true},
	}

	if !visibleAnimatedColor(view) {
		t.Fatal("animated actor did not request redraw")
	}

	view.Entities = nil
	view.Clouds = []game.EntityView{
		{AnimatedColor: true},
	}

	if !visibleAnimatedColor(view) {
		t.Fatal("animated cloud did not request redraw")
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
