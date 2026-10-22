package terminal

import (
	"strings"
	"testing"

	"crawl/internal/game"
)

// The source ability belongs in the ordinary ability menu. Both prompts
// must be explicit, and cancelling either one leaves worship and time alone.
func TestRenounceReligionMenuAndTwoPrompts(t *testing.T) {
	m := pregameModel(t)
	g, err := game.NewDungeonGame(
		623,
		"SP_HUMAN",
		"JOB_BERSERKER",
		"WPN_HAND_AXE",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	m.game = g
	m.screen = ScreenPlay

	if rows := plainApp(m); !strings.Contains(rows, "Human of Trog *.....") {
		t.Fatalf("source worship title missing god or stars:\n%s", rows)
	}

	before := g.View().CurrentAut

	m.handleKey("a")

	if m.screen != ScreenAbilities ||
		!strings.Contains(plainApp(m), "Renounce Religion") {
		t.Fatal("renunciation is absent from the ability menu")
	}

	m.handleKey("a")

	if m.screen != ScreenActionConfirm ||
		!strings.Contains(plainApp(m), "Really renounce your faith") {
		t.Fatal("first renunciation prompt is missing")
	}

	m.handleKey("n")

	if m.screen != ScreenPlay ||
		g.View().CurrentAut != before ||
		g.View().GodName != "Trog" {
		t.Fatal("declining renunciation changed the run")
	}

	m.handleKey("a")
	m.handleKey("a")
	m.handleKey("y")

	if m.screen != ScreenActionConfirm ||
		!strings.Contains(plainApp(m), "Are you sure?") ||
		g.View().CurrentAut != before {
		t.Fatal("second renunciation prompt is missing or spent time")
	}

	m.handleKey("y")

	if m.screen != ScreenPlay ||
		g.View().CurrentAut <= before ||
		g.View().GodName != "" {
		t.Fatal("confirmed renunciation did not end worship on a turn")
	}
}

// A long source species/patron title keeps its full name on the dedicated
// second line and drops stars only when they would exceed the HUD width.
func TestLongGodTitleDoesNotOverwriteOtherHUDFields(t *testing.T) {
	view := playView(t)

	view.SpeciesName = "Mottled Draconian"
	view.GodName = "the Shining One"
	view.PietyStars = "*....."

	canvas := NewCanvas(79, 24)
	layout, ok := ComputeLayout(79, 24)

	if !ok {
		t.Fatal("minimum HUD layout unavailable")
	}

	DrawPlay(canvas, layout, view, "", testPresentationPolicy(t))

	line := canvas.PlainRows()[1]

	if !strings.Contains(line, "Mottled Draconian of the Shining One") {
		t.Fatalf("long god title was truncated: %q", line)
	}

	if strings.Contains(line, "*.....") {
		t.Fatalf("piety stars overflowed the HUD: %q", line)
	}
}
