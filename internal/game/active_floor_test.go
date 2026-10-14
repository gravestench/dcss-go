package game

import (
	"reflect"
	"testing"
)

// An inactive floor keeps its actors' deadlines until its return catch-up.
// Advancing them through no-op turns consumes work and hides an invalid clock.
func TestInactiveFloorMonsterDeadlineStaysFrozen(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)
	actor, _ := g.stores.Actors.Get(quokka)

	for turn := 0; turn < 4; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if actor.NextAut != 0 {
		t.Fatalf("inactive quokka deadline = %d, want frozen at 0", actor.NextAut)
	}

	if g.currentAut != 40 {
		t.Fatalf("player clock = %d, want 40", g.currentAut)
	}
}

func TestFirstEntryDoesNotReplayInactiveMonsterTurns(t *testing.T) {
	g := newStepGame(t)
	rat, _ := g.stores.Actors.Get(ratID(t, g))
	rat.NextAut = 1000
	quokka := quokkaID(t, g)

	if err := g.levels[2].MoveActor(quokka, 2, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)
	health.Current = 100
	health.Max = 100

	for turn := 0; turn < 4; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	combatEvents := 0

	for _, event := range result.Events {
		if event.Kind == "combat" {
			combatEvents++
		}
	}

	// A speed-12 quokka gets its ordinary turns at aut 40 and 49 before
	// the player's next deadline at 50. A replay from aut 0 adds more.
	if combatEvents != 2 || result.View.CurrentAut != 50 {
		t.Fatalf("first entry gave %d attacks at aut %d, want two at aut 50", combatEvents, result.View.CurrentAut)
	}
}

func TestReturnRebasesFrozenMonsterDeadlineAndSaveContinues(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	for turn := 0; turn < 4; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	ratActor, _ := g.stores.Actors.Get(rat)

	if ratActor.NextAut != 0 {
		t.Fatalf("away rat deadline = %d, want frozen at 0", ratActor.NextAut)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot, testCatalog(t))

	if err != nil {
		t.Fatalf("frozen off-floor deadline should survive save: %v", err)
	}

	defer restored.Close()

	for _, run := range []*Game{g, restored} {
		result, stepErr := run.Step(Command{Kind: CommandUpstairs})

		if stepErr != nil {
			t.Fatal(stepErr)
		}

		if result.View.CurrentAut != Aut(snapshot.CurrentAut+10) {
			t.Fatalf("return clock = %d, want %d", result.View.CurrentAut, snapshot.CurrentAut+10)
		}

		actor, _ := run.stores.Actors.Get(rat)

		if actor.NextAut != int64(run.currentAut) {
			t.Fatalf("returned rat deadline = %d, want %d", actor.NextAut, run.currentAut)
		}

		position, _ := run.stores.Positions.Get(rat)

		if position.X != 5 || position.Y != 2 {
			t.Fatalf("returned rat moved %+v; want one step to (5,2)", *position)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("return after save diverged")
	}
}

func TestRestoreRejectsPastDeadlineOnActiveFloor(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]

		if record.AI != nil && record.Position.LevelID == 1 {
			record.Actor.NextAut = snapshot.CurrentAut - 1

			break
		}
	}

	if restored, err := Restore(snapshot, testCatalog(t)); err == nil {
		restored.Close()
		t.Fatal("active monster with past deadline restored")
	}
}
