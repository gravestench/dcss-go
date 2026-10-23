package game

import (
	"reflect"
	"testing"

	"crawl/internal/save"
	"crawl/internal/terrain"
)

// Keep both tests on one state fixture so isolation and restore exercise
// the same borrowed terrain, queued sample, and transit provenance.
func testAbyssState() *save.AbyssStateRecord {
	return &save.AbyssStateRecord{
		BranchDepth:     1,
		MorphDepth:      100,
		BorrowedLevelID: 1,
		BorrowedLayout: [][]terrain.ID{
			{
				terrain.RockWall,
				terrain.RockWall,
				terrain.RockWall,
			},

			{
				terrain.RockWall,
				terrain.Floor,
				terrain.RockWall,
			},

			{
				terrain.RockWall,
				terrain.RockWall,
				terrain.RockWall,
			},
		},
		SampleQueue: []save.AbyssSampleRecord{
			{
				X:       1,
				Y:       1,
				Change:  101,
				Feature: terrain.Floor,
			},
		},
		ExitXP:         10,
		MinBranchDepth: 1,
	}
}

// Save callers must not be able to edit the active procedural clock or
// borrowed floor through the returned snapshot.
func TestAbyssStateSnapshotIsIsolated(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	g.abyssState = testAbyssState()
	g.abyssState.Transit = []save.AbyssTransitRecord{
		{
			EntityID: 12,
			X:        1,
			Y:        1,
		},
	}

	snapshot := g.Snapshot()

	if snapshot.AbyssState == nil {
		t.Fatal("Abyss state omitted from snapshot")
	}

	snapshot.AbyssState.BorrowedLayout[1][1] = terrain.Lava
	snapshot.AbyssState.SampleQueue[0].Change = 999
	snapshot.AbyssState.Transit[0].X = 2

	if g.abyssState.BorrowedLayout[1][1] != terrain.Floor ||
		g.abyssState.SampleQueue[0].Change != 101 ||
		g.abyssState.Transit[0].X != 1 {
		t.Fatal("snapshot aliases live Abyss state")
	}
}

// Restore must validate and retain the state beside the mutable grid.
// Rejecting a bad branch clock also checks that the restore path calls
// the validator instead of only round-tripping an opaque JSON field.
func TestRestoreAbyssState(t *testing.T) {
	g := newStepGame(t)

	g.abyssState = testAbyssState()

	original := g.Snapshot()
	restored, err := Restore(original)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(restored.Snapshot().AbyssState,
		original.AbyssState) {
		t.Fatal("restore lost Abyss state")
	}

	original.AbyssState.BranchDepth = 8

	if _, err := Restore(original); err == nil {
		t.Fatal("restore accepted invalid Abyss depth")
	}
}
