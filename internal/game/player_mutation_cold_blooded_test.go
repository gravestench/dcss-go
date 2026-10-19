package game

import (
	"testing"

	"crawl/internal/ecs"
)

func TestColdBloodedExposureAddsSavedSlowAndChangesTurnCost(t *testing.T) {
	seed := uint64(1)

	for ; seed < 100; seed++ {
		roll, err := NewRNGStreams(seed).Intn("cold", 2)

		if err != nil {
			t.Fatal(err)
		}

		if roll == 0 {
			break
		}
	}

	g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	addPlayerMutation(t, g, "MUT_COLD_BLOODED")

	_, err = g.scripts.Policy("combat.player_cold_exposure", map[string]any{
		"strength":   8,
		"resistance": 0,
	})

	if err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["character.slow"]

	if store == nil || !store.Has(g.player) {
		t.Fatal("cold exposure did not add shared player slow")
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["character.slow"].Has(restored.player) {
		t.Fatal("shared player slow did not survive save and restore")
	}

	result, err := restored.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 15 {
		t.Fatalf("cold-blooded slow cost %d aut, want 15", result.Spent)
	}
}

func TestEndoplasmFreezeTriggersColdBloodedSlow(t *testing.T) {
	g, monster := newEndoplasmGame(t, true)
	addPlayerMutation(t, g, "MUT_COLD_BLOODED")
	placePlayerBesideMonster(t, g, monster)

	for state := uint64(0); state < 100; state++ {
		probe := RestoreRNGStreams(g.seed, map[string]uint64{
			"cold": state,
		})

		roll, err := probe.Intn("cold", 2)

		if err != nil {
			t.Fatal(err)
		}

		if roll == 0 {
			g.rng.states["cold"] = state
			break
		}
	}

	if _, err := g.runAction(monster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell ||
		!g.scripts.Components()["character.slow"].Has(g.player) {
		t.Fatal("endoplasm Freeze did not apply Cold-Blooded slow")
	}
}
