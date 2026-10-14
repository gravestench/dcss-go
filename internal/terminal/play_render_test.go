package terminal

import (
	"strings"
	"testing"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
)

func playView(t *testing.T) game.View {
	t.Helper()
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	g, err := game.NewScenario(7, catalog, "WPN_RAPIER", "Alice")

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	return g.View()
}

func TestDrawPlayMinimumHUDAndCenteredMap(t *testing.T) {
	view := playView(t)
	canvas := NewCanvas(79, 24)
	layout, ok := ComputeLayout(79, 24)

	if !ok {
		t.Fatal("minimum size rejected")
	}

	DrawPlay(canvas, layout, view, "Unavailable: quaffing")
	rows := canvas.PlainRows()

	for _, tc := range []struct {
		y    int
		x    int
		text string
	}{
		{
			y:    0,
			x:    37,
			text: "Alice the Shield-Bearer",
		},

		{
			y:    1,
			x:    37,
			text: "Human",
		},

		{
			y:    2,
			x:    37,
			text: "Health: 18/18",
		},

		{
			y:    3,
			x:    37,
			text: "Magic:  1/1",
		},

		{
			y:    4,
			x:    37,
			text: "AC: 6",
		},

		{
			y:    5,
			x:    37,
			text: "EV: 5",
		},

		{
			y:    6,
			x:    37,
			text: "SH: 4",
		},

		{
			y:    4,
			x:    55,
			text: "Str: 16",
		},

		{
			y:    5,
			x:    55,
			text: "Int: 8",
		},

		{
			y:    6,
			x:    55,
			text: "Dex: 12",
		},

		{
			y:    7,
			x:    37,
			text: "XL:  1 Next:  0%",
		},

		{
			y:    7,
			x:    55,
			text: "Place: D:1",
		},

		{
			y:    8,
			x:    37,
			text: "Noise: --",
		},

		{
			y:    9,
			x:    37,
			text: "a) +0 rapier",
		},

		{
			y:    10,
			x:    37,
			text: "Quiver: --",
		},
	} {
		if !strings.HasPrefix(rows[tc.y][tc.x:], tc.text) {
			t.Fatalf("row %d column %d = %q, want prefix %q", tc.y, tc.x, rows[tc.y][tc.x:], tc.text)
		}
	}

	if rows[8][16] != '@' ||
		rows[8][19] != 'r' || rows[9][19] == ' ' {
		t.Fatalf("map not centered on player: %q / %q", rows[8], rows[9])
	}

	if !strings.Contains(rows[13][37:], "rat") {
		t.Fatalf("nearby list has no rat: %q", rows[13])
	}

	if !strings.Contains(strings.Join(rows[17:], "\n"), "Unavailable: quaffing") {
		t.Fatal("UI notice missing from message area")
	}
}

func TestDrawPlayShowsEarnedRatExperienceProgress(t *testing.T) {
	view := playView(t)

	view.ExperienceLevel = 1
	view.NextLevelPercent = 11

	canvas := NewCanvas(79, 24)
	layout, _ := ComputeLayout(79, 24)
	DrawPlay(canvas, layout, view, "")

	if got := canvas.PlainRows()[7][37:]; !strings.HasPrefix(got, "XL:  1 Next: 11%") {
		t.Fatalf("experience HUD = %q", got)
	}
}

func TestDrawPlayShowsMightLightOnlyWhileActive(t *testing.T) {
	view := playView(t)
	canvas := NewCanvas(79, 24)
	layout, _ := ComputeLayout(79, 24)

	view.MightAut = 340
	DrawPlay(canvas, layout, view, "")

	if !strings.Contains(canvas.PlainRows()[11][37:], "Might") {
		t.Fatal("active Might status light missing")
	}

	view.MightAut = 0
	canvas = NewCanvas(79, 24)
	DrawPlay(canvas, layout, view, "")

	if strings.Contains(canvas.PlainRows()[11][37:], "Might") {
		t.Fatal("expired Might status light remains")
	}
}

func TestDrawPlayShowsPoisonOnlyWhileActive(t *testing.T) {
	view := playView(t)
	canvas := NewCanvas(79, 24)
	layout, _ := ComputeLayout(79, 24)

	view.PoisonAmountScaled = 8000

	DrawPlay(canvas, layout, view, "")

	if !strings.Contains(canvas.PlainRows()[11][37:], "Poisoned") {
		t.Fatal("active poison status is missing from the HUD")
	}

	view.PoisonAmountScaled = 0
	canvas = NewCanvas(79, 24)
	DrawPlay(canvas, layout, view, "")

	if strings.Contains(canvas.PlainRows()[11][37:], "Poisoned") {
		t.Fatal("cured poison status remains on the HUD")
	}
}

func TestDrawPlayShowsFastOnlyWhileHasted(t *testing.T) {
	view := playView(t)
	canvas := NewCanvas(79, 24)
	layout, _ := ComputeLayout(79, 24)

	view.HasteAut = 100

	DrawPlay(canvas, layout, view, "")

	if !strings.Contains(canvas.PlainRows()[11][37:], "Fast") {
		t.Fatal("active haste status is missing from the HUD")
	}

	view.HasteAut = 0
	canvas = NewCanvas(79, 24)
	DrawPlay(canvas, layout, view, "")

	if strings.Contains(canvas.PlainRows()[11][37:], "Fast") {
		t.Fatal("expired haste status remains on the HUD")
	}
}

func TestDrawPlayExpandedViewportUsesFullTerminal(t *testing.T) {
	view := playView(t)
	canvas := NewCanvas(120, 40)
	layout, ok := ComputeLayout(120, 40)

	if !ok {
		t.Fatal("large size rejected")
	}

	DrawPlay(canvas, layout, view, "")
	rows := canvas.PlainRows()

	if rows[16][37] != '@' ||
		!strings.HasPrefix(rows[0][78:], "Alice the Shield-Bearer") {
		t.Fatalf("expanded map/HUD positions: %q / %q", rows[16], rows[0])
	}

	if len(rows) != 40 ||
		len(rows[0]) != 120 || len(rows[39]) != 120 {
		t.Fatalf("terminal dimensions: %d rows, %d/%d columns", len(rows), len(rows[0]), len(rows[39]))
	}
}

func TestDrawPlayUnarmedUsesSourceWeaponSlot(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	g, err := game.NewScenario(7, catalog, "WPN_UNARMED", "Alice")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	canvas := NewCanvas(79, 24)
	layout, _ := ComputeLayout(79, 24)
	DrawPlay(canvas, layout, g.View(), "")

	if got := canvas.PlainRows()[9][37:]; !strings.HasPrefix(got, "-) Unarmed") {
		t.Fatalf("unarmed weapon row: %q", got)
	}
}

func TestDrawPlayFogAndRememberedTerrain(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	run, err := game.NewScenario(7, catalog, "WPN_RAPIER", "Alice")

	if err != nil {
		t.Fatal(err)
	}

	snapshot := run.Snapshot()
	run.Close()

	for i := range snapshot.Entities {
		if snapshot.Entities[i].Actor != nil &&
			snapshot.Entities[i].Actor.KindID == "MONS_RAT" {
			snapshot.Entities[i].Position.X = 3
			snapshot.Entities[i].Position.Y = 3
		}
	}

	known := []byte(snapshot.Levels[0].Known[3])

	known[3] = '.'
	snapshot.Levels[0].Known[3] = string(known)
	restored, err := game.Restore(snapshot, catalog)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	view := restored.View()

	if view.Cells[3*view.Width+3].State != game.Explored {
		t.Fatal("fixture floor is not remembered")
	}

	for _, size := range [][2]int{{79, 24}, {120, 40}} {
		canvas := NewCanvas(size[0], size[1])
		layout, ok := ComputeLayout(size[0], size[1])

		if !ok {
			t.Fatal("layout rejected")
		}

		DrawPlay(canvas, layout, view, "")
		at := func(x, y int) cell {
			sx := layout.Dungeon.X + layout.Dungeon.W/2 + x - view.PlayerX
			sy := layout.Dungeon.Y + layout.Dungeon.H/2 + y - view.PlayerY

			return canvas.cells[sy*canvas.width+sx]
		}

		if got := at(3, 3); got.text != "." || got.fg != DarkGrey {
			t.Fatalf("%dx%d remembered floor = %+v", size[0], size[1], got)
		}

		if got := at(15, 7); got.text != " " {
			t.Fatalf("%dx%d unknown terrain leaked: %+v", size[0], size[1], got)
		}

		if got := at(1, 2); got.text != "." || got.fg != LightGrey {
			t.Fatalf("%dx%d visible floor = %+v", size[0], size[1], got)
		}

		for y := layout.Monsters.Y; y < layout.Monsters.Y+layout.Monsters.H; y++ {
			if strings.Contains(canvas.PlainRows()[y][layout.Monsters.X:], "rat") {
				t.Fatal("hidden rat leaked into nearby-monster pane")
			}
		}
	}
}
