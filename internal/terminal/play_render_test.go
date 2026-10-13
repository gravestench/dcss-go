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
	t.Cleanup(func() { g.Close() })
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
		y, x int
		text string
	}{
		{0, 37, "Alice the Shield-Bearer"}, {1, 37, "Human"},
		{2, 37, "Health: 18/18"}, {3, 37, "Magic:  1/1"},
		{4, 37, "AC: --"}, {5, 37, "EV: --"}, {6, 37, "SH: --"},
		{4, 55, "Str: 16"}, {5, 55, "Int: 8"}, {6, 55, "Dex: 12"},
		{7, 37, "XL: --"}, {7, 55, "Place: D:1"}, {8, 37, "Noise: --"},
		{9, 37, "a) +0 rapier"}, {10, 37, "Quiver: --"},
	} {
		if !strings.HasPrefix(rows[tc.y][tc.x:], tc.text) {
			t.Fatalf("row %d column %d = %q, want prefix %q", tc.y, tc.x, rows[tc.y][tc.x:], tc.text)
		}
	}
	if rows[8][16] != '@' || rows[8][19] != 'r' || rows[9][19] == ' ' {
		t.Fatalf("map not centered on player: %q / %q", rows[8], rows[9])
	}
	if !strings.Contains(rows[13][37:], "rat") {
		t.Fatalf("nearby list has no rat: %q", rows[13])
	}
	if !strings.Contains(strings.Join(rows[17:], "\n"), "Unavailable: quaffing") {
		t.Fatal("UI notice missing from message area")
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
	if rows[16][37] != '@' || !strings.HasPrefix(rows[0][78:], "Alice the Shield-Bearer") {
		t.Fatalf("expanded map/HUD positions: %q / %q", rows[16], rows[0])
	}
	if len(rows) != 40 || len(rows[0]) != 120 || len(rows[39]) != 120 {
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
