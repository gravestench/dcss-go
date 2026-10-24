package game

import (
	"testing"

	"crawl/internal/terrain"
)

// A pacified monster standing on the source Dungeon stair leaves with its
// inventory rather than entering the next floor or creating death rewards.
func TestPacifiedMonsterLeavesFromStairWithoutSecondXP(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	weapon := giveTestMonsterWeapon(t, g, rat)

	if err := g.levels[1].MoveActor(rat, 7, 3); err != nil {
		t.Fatal(err)
	}
	if _, err := g.scripts.Components()["religion.elyvilon_pacified"].Set(
		rat,
		map[string]any{
			"pacified": true,
		},
	); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 5 && g.world.EntityExists(rat); attempt++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}
	if g.world.EntityExists(rat) {
		t.Fatal("pacified rat remained on an exit")
	}
	if g.world.EntityExists(weapon) {
		t.Fatal("pacified rat left its carried weapon behind")
	}
	progress, found := g.stores.Progression.Get(g.player)
	if !found || progress.TotalXP != 0 {
		t.Fatalf("departure changed player XP: %+v", progress)
	}
}

// The existing AI target persists while a pacified monster follows an
// ordinary grid route. Reloading between steps must keep that destination.
func TestPacifiedMonsterRoutesToStairAcrossRestore(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(rat, 5, 3); err != nil {
		t.Fatal(err)
	}
	if _, err := g.scripts.Components()["religion.elyvilon_pacified"].Set(
		rat,
		map[string]any{
			"pacified": true,
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
	position, found := g.stores.Positions.Get(rat)
	if !found || position.X <= 5 {
		t.Fatalf("pacified rat did not approach the stair: %+v", position)
	}

	restored, err := Restore(g.Snapshot())
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()

	for attempt := 0; attempt < 10 &&
		restored.world.EntityExists(rat); attempt++ {
		if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}
	if restored.world.EntityExists(rat) {
		t.Fatal("restored pacified rat never reached the stair")
	}
}

// An exit behind a continuous wall is not a valid route. The monster
// remains a neutral actor and can be saved while the floor is blocked.
func TestPacifiedMonsterSurvivesUnreachableExit(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	for y := 1; y <= 7; y++ {
		if err := g.levels[1].SetCell(6, y, terrain.RockWall); err != nil {
			t.Fatal(err)
		}
	}
	if err := g.levels[1].MoveActor(rat, 5, 3); err != nil {
		t.Fatal(err)
	}
	if _, err := g.scripts.Components()["religion.elyvilon_pacified"].Set(
		rat,
		map[string]any{
			"pacified": true,
		},
	); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 5; attempt++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}
	if !g.world.EntityExists(rat) {
		t.Fatal("pacified rat departed through an unreachable exit")
	}
	if restored, err := Restore(g.Snapshot()); err != nil {
		t.Fatal(err)
	} else {
		restored.Close()
	}
}
