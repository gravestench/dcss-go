package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
)

// A region is prepared without changing the live level. Applying its
// terrain and actor permutation, then undoing a later failed command,
// must restore the exact save-visible game state.
func TestRegionMutationApplyAndUndo(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	cells := g.levels[1].Cells()

	cells[1][1] = terrain.RockWall

	plan := regionTestPlan(cells)

	plan["actor_moves"] = []any{
		map[string]any{
			"actor":    g.player,
			"level_id": int64(1),
			"x":        int64(2),
			"y":        int64(1),
		},
	}

	grid := scriptGrid{levels: g.levels}
	change, err := grid.PrepareRegion(1, plan)

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("preparing a region changed the live game")
	}

	if err := change.Apply(); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found || *position != (ecs.Position{
		LevelID: 1,
		X:       2,
		Y:       1,
	}) || g.levels[1].Cells()[1][1] != terrain.RockWall {
		t.Fatalf("region did not move terrain and actor together: %+v", position)
	}

	if err := change.Undo(); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("undo did not restore terrain, actor, metadata, and RNG")
	}
}

// A malformed destination must fail before its first grid or entity
// mutation; this is the same path a rejected Lua vault plan will take.
func TestRegionMutationRejectsBlockedActor(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	cells := g.levels[1].Cells()

	cells[1][2] = terrain.RockWall

	plan := regionTestPlan(cells)

	plan["actor_moves"] = []any{
		map[string]any{
			"actor":    g.player,
			"level_id": int64(1),
			"x":        int64(2),
			"y":        int64(1),
		},
	}

	grid := scriptGrid{levels: g.levels}

	if _, err := grid.PrepareRegion(1, plan); err == nil {
		t.Fatal("blocked actor destination was accepted")
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("rejected region changed the game")
	}
}

// A moving Abyss window drops actors on erased edge cells. The generic
// region transaction removes their grid positions, while the caller may
// later destroy them or record a separate transit destination.
func TestRegionMutationRetiresActorAndUndoes(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	plan := regionTestPlan(g.levels[1].Cells())

	plan["actor_retire"] = []any{g.player}

	grid := scriptGrid{levels: g.levels}
	change, err := grid.PrepareRegion(1, plan)

	if err != nil {
		t.Fatal(err)
	}

	if err := change.Apply(); err != nil {
		t.Fatal(err)
	}

	if _, indexed := g.levels[1].ActorAt(1, 1); indexed {
		t.Fatal("retired actor remained on the region")
	}

	if _, positioned := g.stores.Positions.Get(g.player); positioned {
		t.Fatal("retired actor kept a grid position")
	}

	if err := change.Undo(); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("undo did not restore a retired actor")
	}
}

// Convert typed cells to the same generic list shape that a Lua table
// carries over the runtime bridge.
func regionTestPlan(cells [][]terrain.ID) map[string]any {
	rows := make([]any, len(cells))

	for y, row := range cells {
		values := make([]any, len(row))

		for x, feature := range row {
			values[x] = string(feature)
		}

		rows[y] = values
	}

	return map[string]any{
		"cells":         rows,
		"local_depth":   int64(1),
		"stairs":        []any{},
		"vault_records": []any{},
		"actor_moves":   []any{},
	}
}
