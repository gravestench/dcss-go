package terminal

import (
	"strings"
	"testing"

	"crawl/internal/game"
)

// A long wait uses the same Game.Step path as a typed wait. A subsequent
// key consumes no time and invalidates a timer that was already queued.
func TestAutomationTickAndKeyInterruption(t *testing.T) {
	m := playingModel(t)
	before := m.game.View().CurrentAut

	if cmd := pressApp(m, "5"); cmd == nil || m.automationState == nil {
		t.Fatalf("long wait did not schedule a tick: %q", m.notice)
	}

	firstID := m.automationTickID
	_, next := m.Update(automationTick{id: firstID})

	if next == nil || m.game.View().CurrentAut <= before {
		t.Fatalf("automatic wait did not spend one turn: %q", m.notice)
	}

	after := m.game.View().CurrentAut
	pressApp(m, "x")

	if m.automationState != nil || m.game.View().CurrentAut != after {
		t.Fatal("interrupting a long wait spent time")
	}

	m.Update(automationTick{id: firstID})

	if m.game.View().CurrentAut != after {
		t.Fatal("stale automatic tick spent time")
	}

	// Run state includes Lua's three recorded feature checks. Sending it
	// through the policy again exercises the real Lua/Go collection bridge.
	if cmd := pressApp(m, "L"); cmd == nil || m.automationState == nil {
		t.Fatalf("shift-run did not schedule a tick: %q", m.notice)
	}

	m.Update(automationTick{id: m.automationTickID})

	if strings.Contains(m.notice, "Automatic movement failed") {
		t.Fatal(m.notice)
	}
}

// Only public, observed terrain reaches Lua. A remembered wall retains
// collision information while an unknown cell contains no map feature.
func TestAutomationViewHidesUnknownTerrain(t *testing.T) {
	view := game.View{
		Width:  2,
		Height: 1,
		Cells: []game.CellView{
			{
				State:     game.Explored,
				FeatureID: "DNGN_ROCK_WALL",
			},
			{
				State: game.Unknown,
			},
		},
	}

	observed := automationView(view)
	cells := observed["cells"].([]any)
	unknown := cells[1].(map[string]any)

	if unknown["feature"] != "" || unknown["walkable"] != false {
		t.Fatalf("unknown cell leaked terrain: %#v", unknown)
	}
}
