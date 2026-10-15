package game

import (
	"reflect"
	"testing"
)

func TestBlackMarkMeleeDrainSurvivesSave(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)
	addPlayerMutation(t, g, "MUT_BLACK_MARK")

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)
	originalMax := health.Max

	health.Max = 1000
	health.Current = 1000

	drained := g.scripts.Components()["magic.monster_drained"]

	for attempt := 0; attempt < 100 && !drained.Has(rat); attempt++ {
		playerHealth, _ := g.stores.Health.Get(g.player)

		playerHealth.Current = playerHealth.Max

		if _, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		}); err != nil {
			t.Fatal(err)
		}
	}

	if !drained.Has(rat) {
		t.Fatal("Black Mark never drained a monster after melee hits")
	}

	health.Max = originalMax
	health.Current = originalMax

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["magic.monster_drained"].Has(rat) ||
		!reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Black Mark drain changed across save and restore")
	}
}
