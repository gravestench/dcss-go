package game

import (
	"testing"
	"time"

	"dcrawl-go/internal/ecs"
)

func TestMonsterDecisionSystemWritesOnlyActiveMonsterIntent(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	system := newMonsterDecisionSystem(g)
	g.turn.Actor = g.player

	if err := system.Update(nil, time.Duration(10)); err != nil || g.stores.Intents.Has(g.player) {
		t.Fatalf("player decision wrote monster intent: %v", err)
	}

	g.turn.Actor = rat

	if err := system.Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	intent, found := g.stores.Intents.Get(rat)

	if !found ||
		intent.Kind != ecs.IntentMove ||
		intent.DX != -1 ||
		intent.DY != 0 {
		t.Fatalf("rat decision = %+v, found %v", intent, found)
	}

	if g.rng.States()["ai"] == 0 {
		t.Fatal("monster decision did not use serializable AI stream")
	}
}
