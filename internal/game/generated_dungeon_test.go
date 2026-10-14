package game

import (
	"reflect"
	"strings"
	"testing"
)

func newGeneratedTestGame(t *testing.T, seed uint64) *Game {
	t.Helper()

	g, err := NewDungeonGame(seed, testCatalog(t), "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		_ = g.Close()
	})

	return g
}

func TestGeneratedDungeonTopologyPopulationAndBoundary(t *testing.T) {
	g := newGeneratedTestGame(t, 41)

	if len(g.levels) != 2 || len(g.stores.AI.Entities()) !=
		g.levels[1].initialMonsters+g.levels[2].initialMonsters {
		t.Fatal("generated levels or monster counts are incomplete")
	}

	for depth, level := range g.levels {
		if len(level.terrain) != 70 || level.width != 80 || len(level.StairLinks()) != 6 {
			t.Fatalf("Dungeon:%d topology is incomplete", depth)
		}

		for _, row := range level.terrain {
			if len(row) != 80 {
				t.Fatalf("Dungeon:%d has a short row", depth)
			}
		}
	}

	if count := g.levels[1].initialMonsters; count < 3 || count > 36 {
		t.Fatalf("Dungeon:1 monster count = %d", count)
	}

	if count := g.levels[2].initialMonsters; count < 3 || count > 30 {
		t.Fatalf("Dungeon:2 monster count = %d", count)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if g.levels[1].terrain[position.Y][position.X] != '<' {
		t.Fatal("player did not start on an up stair")
	}

	before := g.Snapshot()
	result, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil || result.Spent != 0 || len(result.Events) != 1 ||
		!strings.Contains(result.Events[0].Text, "unavailable") {
		t.Fatalf("unported Dungeon exit = %+v, %v", result, err)
	}

	if !reflect.DeepEqual(before.RNG, g.Snapshot().RNG) {
		t.Fatal("unavailable exit consumed randomness")
	}
}

func TestGeneratedDungeonSaveContinuation(t *testing.T) {
	g := newGeneratedTestGame(t, 73)
	sameSeed := newGeneratedTestGame(t, 73)

	if !reflect.DeepEqual(g.Snapshot(), sameSeed.Snapshot()) {
		t.Fatal("same seed produced a different Dungeon")
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("generated terrain, stair links, or population changed on load")
	}

	for _, run := range []*Game{g, restored} {
		if _, err := run.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("generated runs diverged after a turn")
	}
}

func TestGeneratedDungeonStairsTravelBetweenPairedCells(t *testing.T) {
	g := newGeneratedTestGame(t, 19)
	var stair StairLink

	for _, link := range g.levels[1].StairLinks() {
		if link.ToLevelID == 2 {
			stair = link

			break
		}
	}

	if stair.ToLevelID == 0 {
		t.Fatal("Dungeon:1 has no downward stair")
	}

	if err := g.levels[1].MoveActor(g.player, stair.X, stair.Y); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	down, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil || down.View.LevelID != 2 || down.View.PlayerX != stair.ToX || down.View.PlayerY != stair.ToY {
		t.Fatalf("downward travel = %+v, %v", down.View, err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil || up.View.LevelID != 1 || up.View.PlayerX != stair.X || up.View.PlayerY != stair.Y {
		t.Fatalf("upward travel = %+v, %v", up.View, err)
	}
}

func TestWalkingIntoClosedDoorOpensAndSavesIt(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]
	row := []byte(level.terrain[1])
	row[2], row[3] = '+', '+'
	level.terrain[1] = string(row)
	level.remembered[1*level.width+4] = 0

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	blocked := g.View().Cells[1*level.width+4]

	if blocked.State != Unknown {
		t.Fatalf("closed door leaked sight: %+v", blocked)
	}

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil || result.Spent != 10 || result.View.PlayerX != 1 ||
		level.terrain[1][2] != '\'' || level.terrain[1][3] != '\'' {
		t.Fatalf("opening by movement = %+v, %v", result, err)
	}

	if result.View.Cells[1*level.width+4].State != Visible {
		t.Fatal("sight did not pass through the open door")
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("open door or map knowledge changed on load")
	}
}

func TestGeneratedDungeonRejectsInvalidSavedBoundaryAndBudget(t *testing.T) {
	g := newGeneratedTestGame(t, 17)
	snapshot := g.Snapshot()
	snapshot.Levels[0].InitialMonsters = 0

	if _, err := Restore(snapshot, testCatalog(t)); err == nil {
		t.Fatal("accepted a generated level without its initial monster count")
	}

	snapshot = g.Snapshot()

	for index := range snapshot.Levels[0].Stairs {
		stair := &snapshot.Levels[0].Stairs[index]

		if stair.Unavailable != "" {
			stair.Unavailable = ""

			break
		}
	}

	if _, err := Restore(snapshot, testCatalog(t)); err == nil {
		t.Fatal("accepted an unlinked generated exit")
	}
}

func TestGeneratedDungeonBuildsAcrossSeeds(t *testing.T) {
	catalog := testCatalog(t)

	for seed := uint64(1); seed <= 16; seed++ {
		g, err := NewDungeonGame(seed, catalog, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatalf("seed %d: %v", seed, err)
		}

		if err := validateGeneratedDungeonLevels(g.levels); err != nil {
			t.Fatalf("seed %d: %v", seed, err)
		}

		_ = g.Close()
	}
}
