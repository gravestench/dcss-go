package game

import (
	"encoding/json"
	"strings"
	"testing"
)

// Real timed ability commands must leave Hand on the saved player and a
// Brother as a god-sourced ECS actor after the normal Go restore path.
func TestTrogAbilitiesSurviveRestore(t *testing.T) {
	g, err := NewDungeonGame(1, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_TROG",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	hand, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_TROG_HAND",
	})

	if err != nil || hand.Spent != 10 {
		t.Fatalf("Trog's Hand spent %d: %v", hand.Spent, err)
	}

	if !g.scripts.Components()["religion.trog_hand"].Has(g.player) {
		t.Fatal("Trog's Hand has no saved player timer")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["religion.trog_hand"].Has(
		restored.player) {
		t.Fatal("restored Trog's Hand lost its timer")
	}

	call, err := restored.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_TROG_BROTHERS_IN_ARMS",
	})

	if err != nil || call.Spent != 10 {
		t.Fatalf("Brothers in Arms spent %d: %v", call.Spent, err)
	}

	summons := restored.scripts.Components()["magic.summon"]
	found := false

	for _, entity := range summons.Entities() {
		value, exists := summons.Get(entity)

		if !exists {
			continue
		}

		sourceID, sourceErr := value.Get("source_id")
		attitude, attitudeErr := value.Get("attitude")

		if sourceErr != nil || attitudeErr != nil ||
			sourceID != "GOD_TROG" || attitude != "friendly" {
			continue
		}

		found = true
		break
	}

	if !found {
		t.Fatal("Brothers in Arms created no friendly Trog summon")
	}

	again, err := Restore(restored.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer again.Close()

	if !again.scripts.Components()["religion.trog_hand"].Has(
		again.player) {
		t.Fatal("second restore lost Trog's Hand")
	}
}

// Restore checks the live worship owner and the Hand timer before any
// regeneration or willpower reader can use a malformed saved effect.
func TestRestoreRejectsInvalidTrogHand(t *testing.T) {
	for _, tc := range []struct {
		name      string
		remaining string
		god       string
	}{
		{name: "expired", remaining: "0", god: "GOD_TROG"},
		{name: "over cap", remaining: "1001", god: "GOD_TROG"},
		{name: "wrong patron", remaining: "70", god: "GOD_MAKHLEB"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g, err := NewDungeonGame(1, "SP_HUMAN", "JOB_FIGHTER",
				"WPN_RAPIER", "Tester")
			if err != nil {
				t.Fatal(err)
			}
			defer g.Close()

			if _, err := g.scripts.Components()["religion.worship"].Set(
				g.player, map[string]any{
					"god_id": "GOD_TROG",
					"piety":  int64(200),
				},
			); err != nil {
				t.Fatal(err)
			}
			if _, err := g.scripts.Components()["religion.trog_hand"].Set(
				g.player, map[string]any{"remaining_aut": int64(70)},
			); err != nil {
				t.Fatal(err)
			}

			snapshot := g.Snapshot()
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Player == nil {
					continue
				}
				for j := range snapshot.Entities[i].Dynamic {
					part := &snapshot.Entities[i].Dynamic[j]
					if part.Schema == "religion.trog_hand" {
						part.Values["remaining_aut"] = json.RawMessage(tc.remaining)
					}
					if part.Schema == "religion.worship" {
						part.Values["god_id"] = json.RawMessage(`"` + tc.god + `"`)
					}
				}
			}

			loaded, err := Restore(snapshot)
			if loaded != nil {
				loaded.Close()
			}
			if err == nil || !strings.Contains(err.Error(), "Trog's Hand") {
				t.Fatalf("invalid Hand restore: %v", err)
			}
		})
	}
}
