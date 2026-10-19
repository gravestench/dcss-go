package game

import (
	"testing"

	"crawl/internal/ecs"
)

func addPlayerMutation(t *testing.T, g *Game, id string) {
	t.Helper()

	record, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.mutation"].Set(
		record,
		map[string]any{
			"owner":       g.player,
			"mutation_id": id,
			"acquired":    int64(1),
		},
	); err != nil {
		t.Fatal(err)
	}
}

func TestTenguFlightChangesMoveAndEvasion(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	before := g.View()

	if !before.DefenseKnown {
		t.Fatalf("baseline defense unavailable: %v", before.Messages)
	}

	baseline := before.PlayerEV
	addPlayerMutation(t, g, "MUT_TENGU_FLIGHT")

	decision, err := g.scripts.Policy("command.timing", map[string]any{
		"attack_target": false,
		"intent_kind":   int(ecs.IntentMove),
		"item_id":       uint64(0),
	})

	if err != nil {
		t.Fatal(err)
	}

	if got := decision["cost"].(int64); got != 9 {
		t.Fatalf("Tengu flight move cost = %d, want 9", got)
	}

	after := g.View()

	if !after.DefenseKnown {
		t.Fatalf("Tengu defense unavailable: %v", after.Messages)
	}

	if got := after.PlayerEV; got <= baseline {
		t.Fatalf("Tengu flight EV = %d, baseline %d", got, baseline)
	}
}

func TestBigWingsFlyWithoutTenguPerks(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	before := g.View()

	if !before.DefenseKnown {
		t.Fatalf("baseline defense unavailable: %v", before.Messages)
	}

	baseline := before.PlayerEV
	addPlayerMutation(t, g, "MUT_BIG_WINGS")

	decision, err := g.scripts.Policy("command.timing", map[string]any{
		"attack_target": false,
		"intent_kind":   int(ecs.IntentMove),
		"item_id":       uint64(0),
	})

	if err != nil {
		t.Fatal(err)
	}

	if got := decision["cost"].(int64); got != 10 {
		t.Fatalf("Big Wings move cost = %d, want 10", got)
	}

	after := g.View()

	if !after.DefenseKnown {
		t.Fatalf("Big Wings defense unavailable: %v", after.Messages)
	}

	if got := after.PlayerEV; got != baseline {
		t.Fatalf("Big Wings EV = %d, baseline %d", got, baseline)
	}
}
