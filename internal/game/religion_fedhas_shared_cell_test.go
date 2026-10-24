package game

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
)

// Aimed self-growth and plant passage exercise the same runtime that a
// player command uses, including the spatial index and saved ECS records.
func TestFedhasPlantSharesPlayerCellAcrossRestore(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	g.world.DestroyEntity(rat)
	readyFedhasWorshipper(t, g)

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	level := g.levels[position.LevelID]
	created := false

	for attempt := 0; attempt < 20; attempt++ {
		refillFedhasMagic(t, g)

		result, err := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_FEDHAS_GROW_BALLISTOMYCETE",
		})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent != 10 {
			t.Fatalf("self-growth spent %d aut, want 10", result.Spent)
		}

		if len(level.ActorsAt(position.X, position.Y)) == 2 {
			created = true
			break
		}
	}

	if !created {
		t.Fatal("self-growth never placed a plant beneath the player")
	}

	if primary, _ := level.ActorAt(position.X, position.Y); primary != g.player {
		t.Fatalf("primary shared actor = %d, want player %d", primary, g.player)
	}

	refillFedhasMagic(t, g)
	again, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_FEDHAS_GROW_BALLISTOMYCETE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if again.Spent != 0 {
		t.Fatalf("second growth on visible shared plant spent %d aut", again.Spent)
	}

	if _, err := g.Step(Command{Kind: CommandMove, DX: 1}); err != nil {
		t.Fatal(err)
	}

	if len(level.ActorsAt(position.X, position.Y)) != 1 {
		t.Fatal("plant disappeared when player left its cell")
	}

	passage, err := g.Step(Command{Kind: CommandMove, DX: -1})

	if err != nil {
		t.Fatal(err)
	}

	if passage.Spent != 15 {
		t.Fatalf("Fedhas passage spent %d aut, want 15", passage.Spent)
	}

	if current, _ := g.stores.Positions.Get(g.player); *current != (ecs.Position{
		LevelID: position.LevelID,
		X:       position.X,
		Y:       position.Y,
	}) {
		t.Fatalf("player did not move onto plant: %+v", current)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if got := restored.levels[position.LevelID].ActorsAt(position.X, position.Y); len(got) != 2 ||
		got[0] != restored.player {
		t.Fatalf("restored shared cell = %v", got)
	}
}

// Restore rebuilds occupancy before Lua validates it. An arbitrary actor
// sharing the player's cell must never reach a playable game.
func TestRestoreRejectsUnrelatedSharedActorCell(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	snapshot := g.Snapshot()
	playerPosition, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	rat := ratID(t, g)
	changed := false

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID == uint64(rat) {
			position := *playerPosition
			snapshot.Entities[index].Position = &position
			changed = true
			break
		}
	}

	if !changed {
		t.Fatal("fixture rat has no saved record")
	}

	restored, err := Restore(snapshot)

	if restored != nil {
		defer restored.Close()
	}

	if err == nil || !strings.Contains(err.Error(),
		"saved actors share an invalid cell") {
		t.Fatalf("restore error = %v, want shared-cell rejection", err)
	}
}
