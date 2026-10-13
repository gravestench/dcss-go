package game

import (
	"fmt"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

func newStepGame(t *testing.T) *Game {
	t.Helper()
	g, err := NewScenario(1, testCatalog(t), "WPN_RAPIER", "Tester")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { g.Close() })
	return g
}

func TestMoveConsumesTenAut(t *testing.T) {
	g := newStepGame(t)
	result, err := g.Step(Command{Kind: CommandMove, DX: 1})
	if err != nil {
		t.Fatal(err)
	}
	position, _ := g.stores.Positions.Get(g.player)
	if result.Spent != 10 || *position != (ecs.Position{LevelID: 1, X: 2, Y: 1}) {
		t.Fatalf("move = %d aut, position %+v", result.Spent, position)
	}
	if id, ok := g.levels[1].ActorAt(2, 1); !ok || id != g.player {
		t.Fatal("occupancy did not follow player")
	}
}

func TestBlockedMoveIsFree(t *testing.T) {
	g := newStepGame(t)
	for _, command := range []Command{{Kind: CommandMove, DX: -1}, {Kind: CommandMove, DX: -2}} {
		result, err := g.Step(command)
		if err != nil {
			t.Fatal(err)
		}
		if result.Spent != 0 {
			t.Fatalf("blocked move spent %d aut", result.Spent)
		}
		position, _ := g.stores.Positions.Get(g.player)
		if *position != (ecs.Position{LevelID: 1, X: 1, Y: 1}) {
			t.Fatalf("blocked move changed position: %+v", position)
		}
		if id, ok := g.levels[1].ActorAt(1, 1); !ok || id != g.player {
			t.Fatal("blocked move changed occupancy")
		}
	}
}

func TestWrongStairIsFree(t *testing.T) {
	g := newStepGame(t)
	for _, kind := range []CommandKind{CommandDownstairs, CommandUpstairs} {
		result, err := g.Step(Command{Kind: kind})
		if err != nil || result.Spent != 0 {
			t.Fatalf("wrong stair = %+v, %v", result, err)
		}
	}
	position, _ := g.stores.Positions.Get(g.player)
	if position.LevelID != 1 {
		t.Fatalf("wrong stair changed level to %d", position.LevelID)
	}
}

func TestStairsChangeFloor(t *testing.T) {
	g := newStepGame(t)
	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}
	result, err := g.Step(Command{Kind: CommandDownstairs})
	if err != nil {
		t.Fatal(err)
	}
	position, _ := g.stores.Positions.Get(g.player)
	if result.Spent != 10 || *position != (ecs.Position{LevelID: 2, X: 1, Y: 1}) {
		t.Fatalf("stair = %d aut, position %+v", result.Spent, position)
	}
	if _, occupied := g.levels[1].ActorAt(7, 3); occupied {
		t.Fatal("player remains indexed on old floor")
	}
}

func TestStepErrorNamesPhaseAndActor(t *testing.T) {
	g := newStepGame(t)
	g.world.Close()
	_, err := g.Step(Command{Kind: CommandMove, DX: 1})
	if err == nil || !strings.Contains(err.Error(), "movement") || !strings.Contains(err.Error(), fmt.Sprint(g.player)) {
		t.Fatalf("error = %v, want movement phase and actor ID", err)
	}
}
