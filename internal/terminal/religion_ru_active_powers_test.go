package terminal

import (
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/game"
)

// The terminal menu discovers Ru's powers from the Lua registry at the
// saved rank, without a patron-specific Go menu or hard-coded key binding.
func TestRuAbilityMenuShowsThreePowers(t *testing.T) {
	m := pregameModel(t)
	g, err := game.NewDungeonGame(1, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	snapshot := g.Snapshot()

	for i := range snapshot.Entities {
		if snapshot.Entities[i].Player == nil {
			continue
		}

		for j := range snapshot.Entities[i].Dynamic {
			worship := &snapshot.Entities[i].Dynamic[j]

			if worship.Schema == "religion.worship" {
				worship.Values["god_id"] =
					json.RawMessage(`"GOD_RU"`)
				worship.Values["piety"] = json.RawMessage(`160`)
			}
		}
	}

	restored, err := game.Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	m.game = restored
	m.screen = ScreenPlay
	m.handleKey("a")
	view := plainApp(m)

	for _, name := range []string{
		"Draw Out Power",
		"Power Leap",
		"Apocalypse",
	} {
		if !strings.Contains(view, name) {
			t.Fatalf("Ru menu lacks %q:\n%s", name, view)
		}
	}

	before := restored.View().CurrentAut

	// A ranged power enters the shared aim screen, and cancelling it must
	// return to play without spending a turn or resolving the ability.
	m.applyInputDecision(map[string]any{
		"action":     "aim",
		"kind":       int64(game.CommandAbility),
		"ability_id": "ABIL_RU_POWER_LEAP",
	})

	if m.screen != ScreenAim ||
		m.aimKind != game.CommandAbility ||
		m.aimAbilityID != "ABIL_RU_POWER_LEAP" {
		t.Fatal("Power Leap did not enter the shared aim screen")
	}

	m.handleKey("esc")

	if m.screen != ScreenPlay ||
		restored.View().CurrentAut != before {
		t.Fatal("cancelled Power Leap spent game time")
	}
}
