package game

import (
	"reflect"
	"testing"
)

// An inactive floor keeps its monster energy until the player returns.
func TestInactiveFloorMonsterEnergyStaysFrozen(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)
	energy, _ := g.stores.MonsterEnergy.Get(quokka)

	for turn := 0; turn < 4; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if energy.Points != 70 {
		t.Fatalf("inactive quokka energy = %d, want 70", energy.Points)
	}

	if g.currentAut != 40 {
		t.Fatalf("player clock = %d, want 40", g.currentAut)
	}
}

func TestFirstEntryDoesNotReplayInactiveMonsterTurns(t *testing.T) {
	g := newStepGame(t)
	rat, _ := g.stores.MonsterEnergy.Get(ratID(t, g))

	rat.Points = 0

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

	// Only the entry action grants energy on this floor.
	if combatEvents != 1 || result.View.CurrentAut != 50 {
		t.Fatalf("first entry gave %d attacks at aut %d, want one at aut 50", combatEvents, result.View.CurrentAut)
	}
}

func TestReturnUsesFrozenMonsterEnergyAndSaveContinues(t *testing.T) {
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

	ratEnergy, _ := g.stores.MonsterEnergy.Get(rat)

	if ratEnergy.Points != 70 {
		t.Fatalf("away rat energy = %d, want frozen at 70", ratEnergy.Points)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("frozen off-floor energy should survive save: %v", err)
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

		energy, _ := run.stores.MonsterEnergy.Get(rat)

		if energy.Points != 70 {
			t.Fatalf("returned rat energy = %d, want 70", energy.Points)
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

func TestRestoreRejectsReadyMonsterEnergy(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]

		if record.AI != nil && record.Position.LevelID == 1 {
			record.MonsterEnergy.Points = 80

			break
		}
	}

	if restored, err := Restore(snapshot); err == nil {
		restored.Close()
		t.Fatal("ready monster energy restored")
	}
}
