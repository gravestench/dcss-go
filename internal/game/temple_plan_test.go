package game

import (
	"reflect"
	"strings"
	"testing"
)

// A Temple plan is chosen on D:1 and survives a save before its branch
// entrance appears. Restore must keep both the map and ordered god groups.
func TestGeneratedTemplePlanSurvivesRestore(t *testing.T) {
	g := newGeneratedTestGame(t, 715)
	snapshot := g.Snapshot()

	if snapshot.TemplePlan == nil || snapshot.TemplePlan.MapID == "" {
		t.Fatal("generated run has no saved Temple plan")
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot.TemplePlan, restored.Snapshot().TemplePlan) {
		t.Fatal("Temple plan changed across restore")
	}
}

// Both Go's shape checks and Lua's effective catalog check a saved plan.
// Duplicate gods and a nonexistent map cannot be made valid by editing JSON.
func TestGeneratedTemplePlanRejectsTampering(t *testing.T) {
	g := newGeneratedTestGame(t, 716)
	missing := g.Snapshot()
	missing.TemplePlan = nil

	if restored, err := Restore(missing); err == nil ||
		!strings.Contains(err.Error(), "Temple plan") {
		if restored != nil {
			_ = restored.Close()
		}

		t.Fatalf("missing Temple plan error = %v", err)
	}

	forged := g.Snapshot()
	forged.TemplePlan.MapID = "missing_temple_map"

	if restored, err := Restore(forged); err == nil ||
		!strings.Contains(err.Error(), "Temple plan") {
		if restored != nil {
			_ = restored.Close()
		}

		t.Fatalf("forged Temple map error = %v", err)
	}

	duplicate := g.Snapshot()
	duplicate.TemplePlan.MainGodIDs[0] = duplicate.TemplePlan.MainGodIDs[1]

	if restored, err := Restore(duplicate); err == nil ||
		!strings.Contains(err.Error(), "Temple plan") {
		if restored != nil {
			_ = restored.Close()
		}

		t.Fatalf("duplicate Temple god error = %v", err)
	}
}
