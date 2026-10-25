package game

import (
	"reflect"
	"testing"
)

// A monster's real melee hit reaches Ru's Lua after-HP reaction. Its
// resulting saved enchantment and next-turn decay must survive restore.
func TestRuRetaliationMonsterHitAndSaveContinuation(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	_, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_RU",
			"piety":  int64(160),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["religion.ru"].Set(
		g.player, map[string]any{}); err != nil {
		t.Fatal(err)
	}

	statuses := []struct {
		id    string
		field string
	}{
		{id: "magic.monster_enfeeble", field: "antimagic_aut"},
		{id: "zap.paralysis", field: "remaining_aut"},
		{id: "projectile.slow", field: "remaining_aut"},
		{id: "magic.monster_enchant", field: "blind_aut"},
		{id: "magic.hex_status", field: "corona_aut"},
	}
	var appliedID string
	var appliedField string

	// The scenario seed fixes the source rolls. Repeated real attack
	// actions let the piety chance fire without a test-only RNG path.
findRetaliation:
	for attempt := 0; attempt < 100; attempt++ {
		health, _ := g.stores.Health.Get(g.player)

		health.Current = health.Max

		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		for _, status := range statuses {
			if store := g.scripts.Components()[status.id]; store != nil && store.Has(rat) {
				appliedID = status.id
				appliedField = status.field

				break findRetaliation
			}
		}
	}

	if appliedID == "" {
		t.Fatal("100 monster attacks caused no Ru retaliation")
	}

	beforeStatus, _ := g.scripts.Components()[appliedID].Get(rat)
	beforeAut, err := beforeStatus.Get(appliedField)

	if err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Ru retaliation enchantment changed on restore")
	}

	restoredStatus, found := restored.scripts.Components()[appliedID].Get(rat)

	if !found {
		t.Fatalf("Ru %s status missing after restore", appliedID)
	}

	restoredAut, err := restoredStatus.Get(appliedField)

	if err != nil {
		t.Fatal(err)
	}

	if restoredAut != beforeAut {
		t.Fatalf("Ru %s timer changed on restore: %v -> %v",
			appliedID, beforeAut, restoredAut)
	}

	// Disable new retaliations while checking this one's timer decay.
	for _, run := range []*Game{g, restored} {
		worship, _ := run.scripts.Components()["religion.worship"].Get(run.player)

		if err := worship.Set("piety", int64(0)); err != nil {
			t.Fatal(err)
		}
	}

	for _, run := range []*Game{g, restored} {
		if _, err := run.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("Ru retaliation diverged after restored turn")
	}

	afterAut := int64(0)

	if afterStatus, found := g.scripts.Components()[appliedID].Get(rat); found {
		value, err := afterStatus.Get(appliedField)

		if err != nil {
			t.Fatal(err)
		}

		afterAut = value.(int64)
	}

	if afterAut >= beforeAut.(int64) {
		t.Fatalf("Ru %s timer did not age: %v -> %d",
			appliedID, beforeAut, afterAut)
	}
}
