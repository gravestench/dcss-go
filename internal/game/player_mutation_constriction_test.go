package game

import (
	"reflect"
	"testing"
)

func TestConstrictingTailGripsDamagesAndSaves(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)
	originalMax := health.Max

	health.Max = 300
	health.Current = 300

	mutation, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["character.mutation"].Set(
		mutation,
		map[string]any{
			"owner":       g.player,
			"mutation_id": "MUT_CONSTRICTING_TAIL",
			"acquired":    int64(2),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	grips := g.scripts.Components()["combat.player_constriction"]

	for attempt := 0; attempt < 30 && !grips.Has(rat); attempt++ {
		_, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})

		if err != nil {
			t.Fatal(err)
		}
	}

	if !grips.Has(rat) {
		t.Fatal("Constricting Tail did not grab an adjacent rat")
	}

	before := health.Current

	for turn := 0; turn < 30 && health.Current == before; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if health.Current >= before {
		t.Fatalf("grip dealt no damage across 30 player turns: rat HP %d", before)
	}

	// The fixed scenario save validator requires the source rat HP range.
	health.Max = originalMax
	health.Current = originalMax

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !loaded.scripts.Components()["combat.player_constriction"].Has(rat) ||
		!reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("direct player grip changed across save and restore")
	}

	left, leftErr := g.Step(Command{Kind: CommandWait})
	right, rightErr := loaded.Step(Command{Kind: CommandWait})

	if leftErr != nil {
		t.Fatal(leftErr)
	}

	if rightErr != nil {
		t.Fatal(rightErr)
	}

	if !reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("saved grip continued differently")
	}
}
