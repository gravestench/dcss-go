package game

import (
	"dcrawl-go/internal/ecs"
	"reflect"
	"testing"
)

func TestPoisonTicksAfterPlayerRegeneration(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)
	regeneration, _ := g.stores.Regeneration.Get(g.player)

	health.Current = 1
	regeneration.HPProgress = 99

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    1000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	_, err := g.runAction(
		g.player,
		ecs.Intent{Kind: ecs.IntentWait},
		10,
		"test wait",
	)

	if err != nil {
		t.Fatal(err)
	}

	if health.Current != 1 || g.stores.Poison.Has(g.player) {
		t.Fatalf("regen-before-poison left health %+v and active poison", *health)
	}
}

func TestCuringClearsPoisonAtFullHealth(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	health, _ := g.stores.Health.Get(g.player)

	health.Current = health.Max

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    8000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	})

	if err != nil ||
		result.Spent != 10 || g.stores.Poison.Has(g.player) {
		t.Fatalf("full-HP curing = %+v, %v", result, err)
	}
}

func TestPoisonWaitCanKillBeforeMonsterTurn(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)

	health.Current = 1

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    4000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil ||
		!result.View.PlayerDead ||
		health.Current != 0 ||
		!containsEvent(result.Events, "You die.") {
		t.Fatalf("poison death = HP %d, dead %v, error %v", health.Current, result.View.PlayerDead, err)
	}
}

func TestMonsterActionDoesNotAdvancePlayerPoison(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	g.turn.Actor = rat

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    8000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	updateLuaSystem(t, g, "status.poison", 10)

	status, _ := g.stores.Poison.Get(g.player)

	if status.AmountScaled != 8000 {
		t.Fatalf("monster action reduced poison to %d", status.AmountScaled)
	}
}

func TestPoisonContinuationMatchesRestoredRun(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    8000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	for _, run := range []*Game{g, restored} {
		if _, err := run.runAction(
			run.player,
			ecs.Intent{Kind: ecs.IntentWait},
			10,
			"test wait",
		); err != nil {
			t.Fatal(err)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("poison status or RNG diverged after restore")
	}
}
