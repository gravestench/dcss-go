package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/terrain"
)

// A run chooses entrances once, and save/restore retains the exact choice.
// The scheduled parent need not be generated yet when the player saves D:1.
func TestGeneratedBranchScheduleSurvivesRestore(t *testing.T) {
	g := newGeneratedTestGame(t, 421)
	snapshot := g.Snapshot()

	if snapshot.BranchSchedule == nil || len(snapshot.BranchSchedule.Entries) == 0 {
		t.Fatal("generated run has no saved branch schedule")
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot.BranchSchedule, restored.Snapshot().BranchSchedule) {
		t.Fatal("branch schedule changed across restore")
	}
}

// Save validation consults the effective Lua branch catalog before trusting
// an entrance depth, even if that parent's grid has not been generated yet.
func TestGeneratedBranchScheduleRejectsTamperedDepth(t *testing.T) {
	g := newGeneratedTestGame(t, 422)
	snapshot := g.Snapshot()
	changed := false

	for index := range snapshot.BranchSchedule.Entries {
		entry := &snapshot.BranchSchedule.Entries[index]

		if entry.BranchID == "BRANCH_LAIR" {
			entry.ParentDepth = 1
			changed = true
			break
		}
	}

	if !changed {
		t.Fatal("Lair has no scheduled entrance")
	}

	if restored, err := Restore(snapshot); err == nil ||
		!strings.Contains(err.Error(), "BRANCH_LAIR") {
		if restored != nil {
			_ = restored.Close()
		}

		t.Fatalf("tampered Lair schedule error = %v", err)
	}
}

// A generated save cannot infer its future entrance graph from its seed:
// turn actions may already have consumed unrelated random streams.
func TestGeneratedBranchScheduleRejectsMissingOrInvalidPair(t *testing.T) {
	g := newGeneratedTestGame(t, 424)
	missing := g.Snapshot()
	missing.BranchSchedule = nil

	if restored, err := Restore(missing); err == nil ||
		!strings.Contains(err.Error(), "branch schedule") {
		if restored != nil {
			_ = restored.Close()
		}

		t.Fatalf("missing schedule error = %v", err)
	}

	invalid := g.Snapshot()
	invalid.BranchSchedule.WaterBranchID = "BRANCH_ZIGGURAT"

	if restored, err := Restore(invalid); err == nil ||
		!strings.Contains(err.Error(), "Lair branch pair") {
		if restored != nil {
			_ = restored.Close()
		}

		t.Fatalf("invalid water pair error = %v", err)
	}
}

// The chosen Dungeon floor shows a labelled source entrance even before
// branch travel becomes available. It stays at the same cell after restore.
func TestScheduledLairEntrancePersistsOnParentFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	depth := 0

	for _, entry := range g.Snapshot().BranchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			depth = entry.ParentDepth
		}
	}

	if depth == 0 {
		t.Fatal("Lair has no scheduled parent depth")
	}

	descendGeneratedTo(t, g, depth)
	var entrance StairLink

	for _, link := range g.levels[depth].StairLinks() {
		if link.TargetBranchID == "BRANCH_LAIR" {
			entrance = link
			break
		}
	}

	if entrance.SourceFeature != "DNGN_ENTER_LAIR" ||
		entrance.Unavailable == "" || entrance.ToLevelID != 0 {
		t.Fatalf("Lair entrance = %+v", entrance)
	}

	if g.levels[depth].Cells()[entrance.Y][entrance.X] != terrain.StairsDown {
		t.Fatal("Lair entrance does not occupy a linked stair cell")
	}

	for _, record := range g.levels[depth].VaultRecords() {
		if record.X == entrance.X && record.Y == entrance.Y {
			t.Fatal("extra vault overlapped protected Lair entrance")
		}
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	linked, found := restored.levels[depth].StairAt(entrance.X, entrance.Y)

	if !found || linked != entrance {
		t.Fatalf("restored Lair entrance = %+v, found %t", linked, found)
	}

	forged := g.Snapshot()

	for levelIndex := range forged.Levels {
		level := &forged.Levels[levelIndex]

		if level.ID != depth {
			continue
		}

		for stairIndex := range level.Stairs {
			stair := &level.Stairs[stairIndex]

			if stair.TargetBranchID == "BRANCH_LAIR" {
				stair.SourceFeature = "DNGN_ENTER_ORC"
			}
		}
	}

	if bad, err := Restore(forged); err == nil ||
		!strings.Contains(err.Error(), "invalid branch entrance") {
		if bad != nil {
			_ = bad.Close()
		}

		t.Fatalf("forged source feature error = %v", err)
	}
}
