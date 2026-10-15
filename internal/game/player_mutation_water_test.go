package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/terrain"
)

func TestNimbleSwimmerChangesWaterMovementAndEvasion(t *testing.T) {
	g := newStepGame(t)
	baselineEV := g.View().PlayerEV

	if err := g.levels[1].SetCell(1, 1, terrain.ShallowWater); err != nil {
		t.Fatal(err)
	}

	wading, err := g.scripts.Policy("command.timing", map[string]any{
		"attack_target": false,
		"intent_kind":   int(ecs.IntentMove),
		"item_id":       uint64(0),
	})

	if err != nil {
		t.Fatal(err)
	}

	if cost := wading["cost"].(int64); cost != 16 {
		t.Fatalf("non-swimmer wading cost = %d, want 16", cost)
	}

	record, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["character.mutation"].Set(
		record,
		map[string]any{
			"owner":       g.player,
			"mutation_id": "MUT_NIMBLE_SWIMMER",
			"acquired":    int64(2),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	swimming, err := g.scripts.Policy("command.timing", map[string]any{
		"attack_target": false,
		"intent_kind":   int(ecs.IntentMove),
		"item_id":       uint64(0),
	})

	if err != nil {
		t.Fatal(err)
	}

	if cost := swimming["cost"].(int64); cost != 6 {
		t.Fatalf("Nimble Swimmer water move cost = %d, want 6", cost)
	}

	if got := g.View().PlayerEV; got <= baselineEV {
		t.Fatalf("Nimble Swimmer EV = %d, floor EV %d", got, baselineEV)
	}

	if err := g.levels[1].SetCell(1, 1, terrain.Floor); err != nil {
		t.Fatal(err)
	}

	floor, err := g.scripts.Policy("command.timing", map[string]any{
		"attack_target": false,
		"intent_kind":   int(ecs.IntentMove),
		"item_id":       uint64(0),
	})

	if err != nil {
		t.Fatal(err)
	}

	if cost := floor["cost"].(int64); cost != 10 {
		t.Fatalf("Nimble Swimmer floor move cost = %d, want 10", cost)
	}
}
