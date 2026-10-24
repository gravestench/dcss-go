package game

import (
	"reflect"
	"testing"
)

// A real player action invokes the Lua power, ages its saved exhaustion,
// and restores the remaining timer through the ordinary game save path.
func TestRuDrawOutPowerSavesSharedExhaustion(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	g.world.DestroyEntity(rat)

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

	before, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("player has no health")
	}

	before.Current = 1

	if _, err := g.stores.Health.Set(g.player, *before); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_RU_DRAW_OUT_POWER",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("Draw Out Power spent %d aut", result.Spent)
	}

	after, _ := g.stores.Health.Get(g.player)

	if after.Current <= 1 {
		t.Fatal("Draw Out Power did not heal")
	}

	status, found := g.scripts.Components()["character.exhaustion"].Get(
		g.player)

	if !found {
		t.Fatal("Draw Out Power did not save exhaustion")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	exhaustionStore := restored.scripts.Components()["character.exhaustion"]
	restoredStatus, found := exhaustionStore.Get(restored.player)

	if !found {
		t.Fatal("restored player lost exhaustion")
	}

	remaining, err := status.Get("remaining_aut")

	if err != nil {
		t.Fatal(err)
	}

	restoredRemaining, err := restoredStatus.Get("remaining_aut")

	if err != nil {
		t.Fatal(err)
	}

	if restoredRemaining != remaining {
		t.Fatalf("restored exhaustion = %v, want %v",
			restoredRemaining, remaining)
	}

	// Both games resume from the same saved turn. The player status owner
	// must age the timer by the same elapsed aut after the restore.
	for _, run := range []*Game{g, restored} {
		if _, err := run.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("Ru exhaustion diverged after a restored player turn")
	}
}

// Apocalypse reuses the saved monster paralysis owner. Restoring during
// its effect must resume the same monster action and timer decay.
func TestRuApocalypseParalysisSaveContinuation(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)
	paralysis := g.scripts.Components()["zap.paralysis"]

	if _, err := paralysis.Set(rat, map[string]any{
		"remaining_aut": int64(80),
	}); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["zap.paralysis"].Has(rat) {
		t.Fatal("restored monster lost Apocalypse paralysis")
	}

	for _, run := range []*Game{g, restored} {
		if _, err := run.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("monster paralysis diverged after restore")
	}
}
