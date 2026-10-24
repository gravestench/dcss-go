package game

import (
	"slices"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/script"
	"github.com/gravestench/akara"
)

// Shared occupancy keeps both ECS actors indexed while ordinary placement
// still rejects collisions. The caller chooses which actor is primary.
func TestLevelSharedActorCell(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()

	positions := ecs.Register(world).Positions
	level, err := NewLevel(1, fixtureCells([]string{
		"#####",
		"#...#",
		"#####",
	}), positions)

	if err != nil {
		t.Fatal(err)
	}

	plant, _ := world.CreateEntity()
	player, _ := world.CreateEntity()
	blocker, _ := world.CreateEntity()

	if err := level.PlaceActor(plant, 2, 1); err != nil {
		t.Fatal(err)
	}

	if err := level.PlaceActorShared(player, 2, 1, true); err != nil {
		t.Fatal(err)
	}

	if got := level.ActorsAt(2, 1); !slices.Equal(got, []akara.Entity{player, plant}) {
		t.Fatalf("shared cell = %v, want player then plant", got)
	}

	if primary, found := level.ActorAt(2, 1); !found || primary != player {
		t.Fatalf("primary actor = %d, found %v", primary, found)
	}

	if err := level.PlaceActor(blocker, 2, 1); err == nil {
		t.Fatal("ordinary placement accepted an occupied cell")
	}

	if err := level.RemoveActor(player); err != nil {
		t.Fatal(err)
	}

	if got := level.ActorsAt(2, 1); !slices.Equal(got, []akara.Entity{plant}) {
		t.Fatalf("remaining cell = %v, want plant", got)
	}

	if positions.Has(player) {
		t.Fatal("removed actor retained a position")
	}
}

// Passing through an occupied cell preserves the resident and restores the
// mover's former square to vacancy.
func TestLevelMoveActorShared(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()

	positions := ecs.Register(world).Positions
	level, err := NewLevel(1, fixtureCells([]string{
		"#####",
		"#...#",
		"#####",
	}), positions)

	if err != nil {
		t.Fatal(err)
	}

	player, _ := world.CreateEntity()
	plant, _ := world.CreateEntity()

	if err := level.PlaceActor(player, 1, 1); err != nil {
		t.Fatal(err)
	}

	if err := level.PlaceActor(plant, 2, 1); err != nil {
		t.Fatal(err)
	}

	if err := level.MoveActor(player, 2, 1); err == nil {
		t.Fatal("ordinary move accepted an occupied cell")
	}

	if err := level.MoveActorShared(player, 2, 1, true); err != nil {
		t.Fatal(err)
	}

	if got := level.ActorsAt(2, 1); !slices.Equal(got, []akara.Entity{player, plant}) {
		t.Fatalf("destination = %v", got)
	}

	if _, found := level.ActorAt(1, 1); found {
		t.Fatal("mover remained indexed at origin")
	}

	if err := level.MoveActor(player, 3, 1); err != nil {
		t.Fatal(err)
	}

	if got := level.ActorsAt(2, 1); !slices.Equal(got, []akara.Entity{plant}) {
		t.Fatalf("plant lost after player exited: %v", got)
	}
}

// Lua batches can split actors from a shared origin. Rollback must restore
// both actors to that origin in their original primary order.
func TestSharedOriginBatchCanBeReversed(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()

	positions := ecs.Register(world).Positions
	level, err := NewLevel(1, fixtureCells([]string{
		"#####",
		"#...#",
		"#####",
	}), positions)

	if err != nil {
		t.Fatal(err)
	}

	player, _ := world.CreateEntity()
	plant, _ := world.CreateEntity()

	if err := level.PlaceActor(player, 1, 1); err != nil {
		t.Fatal(err)
	}

	if err := level.PlaceActorShared(plant, 1, 1, false); err != nil {
		t.Fatal(err)
	}

	grid := scriptGrid{levels: map[int]*Level{1: level}}

	if err := grid.MoveActors([]script.ActorMove{
		{Actor: player, LevelID: 1, X: 2, Y: 1},
		{Actor: plant, LevelID: 1, X: 3, Y: 1},
	}); err != nil {
		t.Fatal(err)
	}

	if err := grid.MoveActors([]script.ActorMove{
		{Actor: player, LevelID: 1, X: 1, Y: 1, Shared: true, Primary: true},
		{Actor: plant, LevelID: 1, X: 1, Y: 1, Shared: true},
	}); err != nil {
		t.Fatal(err)
	}

	if got := level.ActorsAt(1, 1); !slices.Equal(got, []akara.Entity{player, plant}) {
		t.Fatalf("restored shared origin = %v", got)
	}
}

// Abyss shifts translate every actor in a protected cell. A player and
// plant must arrive together rather than failing a duplicate destination.
func TestRegionMovesSharedCellAsGroup(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()

	positions := ecs.Register(world).Positions
	cells := fixtureCells([]string{
		"#####",
		"#...#",
		"#####",
	})
	old, err := NewLevel(1, cells, positions)

	if err != nil {
		t.Fatal(err)
	}

	player, _ := world.CreateEntity()
	plant, _ := world.CreateEntity()

	if err := old.PlaceActor(player, 1, 1); err != nil {
		t.Fatal(err)
	}

	if err := old.PlaceActorShared(plant, 1, 1, false); err != nil {
		t.Fatal(err)
	}

	next, err := NewLevel(1, cells, positions)

	if err != nil {
		t.Fatal(err)
	}

	next.actors[point{x: 1, y: 1}] = old.ActorsAt(1, 1)
	grid := scriptGrid{levels: map[int]*Level{1: next}}
	requested := []any{
		map[string]any{
			"actor":    player,
			"level_id": int64(1),
			"x":        int64(2),
			"y":        int64(1),
		},
		map[string]any{
			"actor":    plant,
			"level_id": int64(1),
			"x":        int64(2),
			"y":        int64(1),
		},
	}

	moves, _, err := grid.prepareRegionActors(old, next, requested, nil)

	if err != nil {
		t.Fatal(err)
	}

	if err := grid.MoveActors(moves); err != nil {
		t.Fatal(err)
	}

	if got := next.ActorsAt(2, 1); !slices.Equal(got, []akara.Entity{player, plant}) {
		t.Fatalf("shifted shared cell = %v", got)
	}
}
