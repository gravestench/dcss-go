package game

import (
	"strings"
	"testing"

	"crawl/internal/terrain"
)

// Sensing cannot outlive direct sight of a cell: the true actor view takes
// over even when Xom's old estimate was deliberately displaced.
func TestDetectedCreatureClearsOnSight(t *testing.T) {
	g, err := NewScenario(1, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	level := g.levels[1]

	if err := level.SetDetectedCreature(10, 1, "MONS_ORC"); err != nil {
		t.Fatal(err)
	}

	visible := make([]bool, level.width*len(level.terrain))
	index := level.width + 10

	visible[index] = true

	if _, err := level.Remember(visible); err != nil {
		t.Fatal(err)
	}

	if got := level.DetectedCreatures()[1][10]; got != "" {
		t.Fatalf("sensed creature remains after direct sight: %q", got)
	}

	if got := level.KnownCells()[1][10]; got == terrain.Unseen {
		t.Fatal("direct sight failed to remember the underlying cell")
	}
}

// Saved detection data must match the level dimensions; a malformed save
// cannot put a sensed monster outside the map owner's coordinate space.
func TestDetectedCreatureRejectsMalformedRows(t *testing.T) {
	g, err := NewScenario(1, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	level := g.levels[1]

	if err := level.LoadDetectedCreatures([][]string{{"MONS_ORC"}}); err == nil {
		t.Fatal("malformed creature marker rows were accepted")
	}
}

// The new save version requires its detection grid. Missing knowledge must
// fail validation rather than silently alter a version-36 snapshot.
func TestDetectedCreatureMissingGridRejected(t *testing.T) {
	g, err := NewScenario(1, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	snapshot := g.Snapshot()

	for index := range snapshot.Levels {
		snapshot.Levels[index].DetectedCreatures = nil
	}

	restored, err := Restore(snapshot)

	if restored != nil {
		_ = restored.Close()
	}

	if err == nil {
		t.Fatal("missing detection grid was accepted")
	}
}

// Version 35 also saved a retired Xom component schema. The entire version
// is rejected before comparing schemas so its state cannot be misread.
func TestXomSchemaChangeRejectsOldSaveVersion(t *testing.T) {
	g, err := NewScenario(1, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	snapshot := g.Snapshot()
	snapshot.Version = 35

	restored, err := Restore(snapshot)

	if restored != nil {
		_ = restored.Close()
	}

	if err == nil || !strings.Contains(err.Error(),
		"unsupported save version 35") {
		t.Fatalf("version-35 Xom schema was accepted: %v", err)
	}
}
