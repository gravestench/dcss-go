package game

import (
	"reflect"
	"testing"

	"github.com/gravestench/akara"
)

func TestReturnedWormHealsAtFastRate(t *testing.T) {
	g, err := NewDungeonGame(1, testCatalog(t), "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	var worm akara.Entity

	for _, entity := range g.stores.AI.Entities() {
		actor, _ := g.stores.Actors.Get(entity)

		if actor.KindID == "MONS_WORM" {
			worm = entity
			break
		}
	}

	if worm == 0 {
		t.Fatal("seed 1 has no worm")
	}

	position, _ := g.stores.Positions.Get(worm)

	if position.LevelID != 2 {
		t.Fatalf("worm started on D:%d, want D:2", position.LevelID)
	}

	health, _ := g.stores.Health.Get(worm)
	health.Current = health.Max - 3
	away := Aut(0)
	g.levels[2].awaySinceAut = &away

	if err := g.activateLevel(g.levels[2], 20); err != nil {
		t.Fatal(err)
	}

	if health.Current != health.Max-1 {
		t.Fatalf("returned worm HP = %d, want %d", health.Current, health.Max-1)
	}
}

func TestReturnedMonsterHealsAndWalksTowardLastTarget(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)
	ai, _ := g.stores.AI.Get(rat)

	health.Current = 1
	ai.TargetX = 7
	ai.TargetY = 1

	away := Aut(0)
	g.levels[1].awaySinceAut = &away

	if err := g.activateLevel(g.levels[1], 100); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(rat)

	if health.Current != 2 || position.X != 7 || position.Y != 1 {
		t.Fatalf("returned rat has %d HP at %+v, want 2 HP at (7,1)", health.Current, *position)
	}

	if _, occupied := g.levels[1].ActorAt(4, 1); occupied {
		t.Fatal("old rat cell remains occupied")
	}

	if occupant, occupied := g.levels[1].ActorAt(7, 1); !occupied || occupant != rat {
		t.Fatal("new rat cell is not indexed")
	}
}

func TestReturnedMonsterStopsAtBlockedTerrain(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	ai, _ := g.stores.AI.Get(rat)

	ai.TargetX = 12
	ai.TargetY = 1

	away := Aut(0)
	g.levels[1].awaySinceAut = &away

	if err := g.activateLevel(g.levels[1], 100); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(rat)

	if position.X != 7 || position.Y != 1 {
		t.Fatalf("rat crossed solid wall: %+v", *position)
	}
}

func TestReturnedMonsterStopsAtAnotherActor(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)
	lizard := frilledLizardID(t, g)

	if err := g.levels[2].MoveActor(quokka, 2, 2); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].MoveActor(lizard, 3, 2); err != nil {
		t.Fatal(err)
	}

	ai, _ := g.stores.AI.Get(quokka)
	ai.TargetX = 6
	ai.TargetY = 2

	away := Aut(0)
	g.levels[2].awaySinceAut = &away

	if err := g.activateLevel(g.levels[2], 100); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(quokka)

	if position.X != 2 || position.Y != 2 {
		t.Fatalf("quokka crossed occupied cell: %+v", *position)
	}
}

func TestReturnedMonsterCannotEnterPlayerCell(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	ai, _ := g.stores.AI.Get(rat)

	ai.TargetX = 7
	ai.TargetY = 1

	if err := g.levels[1].MoveActor(g.player, 6, 1); err != nil {
		t.Fatal(err)
	}

	away := Aut(0)
	g.levels[1].awaySinceAut = &away

	if err := g.activateLevel(g.levels[1], 100); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(rat)

	if position.X != 5 || position.Y != 1 {
		t.Fatalf("rat crossed player cell: %+v", *position)
	}
}

func TestReturnedMonsterHealingStopsAtMaximum(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	health.Current = health.Max - 1
	away := Aut(0)
	g.levels[1].awaySinceAut = &away

	if err := g.activateLevel(g.levels[1], 1000); err != nil {
		t.Fatal(err)
	}

	if health.Current != health.Max {
		t.Fatalf("returned rat HP = %d, want maximum %d", health.Current, health.Max)
	}
}

func TestReturnedMonsterWithoutTargetStaysPut(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	position, _ := g.stores.Positions.Get(rat)
	before := *position

	away := Aut(0)
	g.levels[1].awaySinceAut = &away

	if err := g.activateLevel(g.levels[1], 100); err != nil {
		t.Fatal(err)
	}

	if *position != before {
		t.Fatalf("targetless rat moved from %+v to %+v", before, *position)
	}
}

func TestFirstEntryDoesNotCatchUpMonster(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)
	health, _ := g.stores.Health.Get(quokka)

	ai, _ := g.stores.AI.Get(quokka)
	position, _ := g.stores.Positions.Get(quokka)

	before := *position

	health.Current = 1
	ai.TargetX = 5
	ai.TargetY = 7

	if err := g.activateLevel(g.levels[2], 100); err != nil {
		t.Fatal(err)
	}

	if health.Current != 1 || *position != before {
		t.Fatalf("first entry changed quokka: %d HP at %+v", health.Current, *position)
	}
}

func TestSavedInactiveMonsterReturnsWithSameCatchup(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	health, _ := g.stores.Health.Get(rat)

	ai, _ := g.stores.AI.Get(rat)
	actor, _ := g.stores.Actors.Get(rat)

	health.Current = 1
	ai.TargetX = 7
	ai.TargetY = 1
	actor.NextAut = 1000

	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	for turn := 0; turn < 10; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	for _, run := range []*Game{g, restored} {
		if _, err := run.Step(Command{Kind: CommandUpstairs}); err != nil {
			t.Fatal(err)
		}

		// Departure plus ten waits leaves 110 aut away. Eleven whole turns
		// require one fractional recovery draw after the integral HP gain.
		if _, rolled := run.rng.States()["offlevel"]; !rolled {
			t.Fatal("return did not consume the fractional recovery stream")
		}

		returnedHealth, _ := run.stores.Health.Get(rat)
		position, _ := run.stores.Positions.Get(rat)

		if returnedHealth.Current <= 1 || position.X != 7 || position.Y != 1 {
			t.Fatalf("returned rat has %d HP at %+v", returnedHealth.Current, *position)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("monster return diverged after save")
	}
}
