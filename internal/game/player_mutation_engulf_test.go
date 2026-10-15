package game

import (
	"reflect"
	"testing"
)

func TestEngulfFromMeleePersistsAndReleasesOnSeparation(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	addPlayerMutation(t, g, "MUT_ENGULF")

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)
	originalMax := health.Max

	health.Max = 300
	health.Current = 300

	holds := g.scripts.Components()["combat.water_hold"]

	for attempt := 0; attempt < 40 && !holds.Has(rat); attempt++ {
		playerHealth, _ := g.stores.Health.Get(g.player)

		playerHealth.Current = playerHealth.Max

		_, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})

		if err != nil {
			t.Fatal(err)
		}
	}

	if !holds.Has(rat) {
		t.Fatal("a damaging melee hit never engulfed the rat")
	}

	// The fixed scenario's save validator expects the source rat HP range.
	health.Max = originalMax
	health.Current = originalMax

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["combat.water_hold"].Has(rat) ||
		!reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Engulf water hold changed across save and restore")
	}

	moveRatToOtherFloor(t, restored)

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if restored.scripts.Components()["combat.water_hold"].Has(rat) {
		t.Fatal("Engulf water hold survived separation")
	}
}
