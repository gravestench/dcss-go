package game

import (
	"reflect"
	"testing"

	"crawl/internal/terrain"
)

// An Abyssal Knight begins in the pocket chapter, with a guaranteed
// usable exit and Lugonu altar. Its first exit lands on the prepared D:1
// cell without inventing a banishment origin.
func TestAbyssalKnightPocketStartAndReturn(t *testing.T) {
	g, err := newScenario(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_ABYSSAL_KNIGHT",
		},
		"WPN_HAND_AXE",
		"Tester",
		ordinaryMonsterScenarioID,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[abyssStorageID]

	if position.LevelID != abyssStorageID ||
		g.abyssState == nil ||
		!g.abyssState.PocketStart ||
		g.abyssState.ReturnSite == nil ||
		level.Cells()[position.Y][position.X] != terrain.ExitAbyss {
		t.Fatal("Abyssal Knight did not start on the pocket exit")
	}

	altars := 0

	for y := position.Y - 8; y <= position.Y+8; y++ {
		for x := position.X - 8; x <= position.X+8; x++ {
			if level.Cells()[y][x] == terrain.LugonuAltar {
				altars++
			}
		}
	}

	if altars != 1 {
		t.Fatalf("pocket start has %d nearby Lugonu altars, want one", altars)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("pocket Abyss changed across save and restore")
	}

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ = g.stores.Positions.Get(g.player)

	if position.LevelID != 1 || g.abyssState.PocketStart {
		t.Fatal("pocket exit did not finish the start chapter on D:1")
	}
}
