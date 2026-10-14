package game

import (
	"testing"

	"github.com/gravestench/akara"
)

func ratID(t *testing.T, g *Game) akara.Entity {
	t.Helper()

	for _, id := range g.stores.AI.Entities() {
		return id
	}

	t.Fatal("rat missing")

	return 0
}

func TestBumpAttacksInsteadOfMoving(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	before, _ := g.stores.Health.Get(rat)
	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	playerPos, _ := g.stores.Positions.Get(g.player)
	ratPos, ratAlive := g.stores.Positions.Get(rat)

	if playerPos.X != 3 ||
		(ratAlive &&
			ratPos.X != 4) ||
		result.Spent < 11 ||
		result.Spent > 12 {
		t.Fatalf("bump moved entities: player %+v rat %+v spent %d", playerPos, ratPos, result.Spent)
	}

	foundCombat := false

	for _, event := range result.Events {
		foundCombat = foundCombat || event.Kind == "combat"
	}

	if !foundCombat {
		t.Fatalf("no combat event: %+v", result.Events)
	}

	if ratAlive {
		after, _ := g.stores.Health.Get(rat)

		if after.Current > before.Current {
			t.Fatalf("rat healed from %d to %d", before.Current, after.Current)
		}
	}
}

func TestRatActsBeforeNextPlayerTurn(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	energy, _ := g.stores.MonsterEnergy.Get(rat)

	if energy.Points != 70 {
		t.Fatalf("rat energy = %d, want 70 after its action; events %+v",
			energy.Points, result.Events)
	}
}

func TestDeathClearsOccupancy(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)
	health.Current = 0

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.world.EntityExists(rat) || g.stores.Positions.Has(rat) {
		t.Fatal("dead rat remains in world")
	}

	if _, ok := g.levels[1].ActorAt(4, 1); ok {
		t.Fatal("dead rat remains in occupancy index")
	}
}

func TestPlayerDeathEndsTurnLoop(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)
	health.Current = 0
	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 ||
		len(result.Events) == 0 ||
		result.Events[0].Kind != "death" {
		t.Fatalf("dead player step = %+v", result)
	}
}
