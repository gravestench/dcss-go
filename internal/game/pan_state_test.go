package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/save"
)

// Earlier-region IDs must survive a save without sharing mutable backing
// storage with the live run. Their order is the order of successful visits.
func TestPanHistorySaveRoundTrip(t *testing.T) {
	g := newGeneratedTestGame(t, 71)
	g.panState = &save.PanStateRecord{
		RegionsSeen: 2,
		VaultIDs: []string{
			"rand_demon_1",
			"mnoleg",
		},
	}

	snapshot := g.Snapshot()

	if snapshot.PanState == nil {
		t.Fatal("Pan history missing from snapshot")
	}

	snapshot.PanState.VaultIDs[0] = "rand_demon_2"

	if g.panState.VaultIDs[0] != "rand_demon_1" {
		t.Fatal("snapshot aliases live Pan history")
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(restored.panState, snapshot.PanState) {
		t.Fatalf("restored Pan history = %+v", restored.panState)
	}
}

// A return pointer without a region is corrupted session data. Reject it
// before command policy can use its coordinates as a travel destination.
func TestRejectPanReturnWithoutActiveRegion(t *testing.T) {
	g := newGeneratedTestGame(t, 72)
	snapshot := g.Snapshot()
	snapshot.PanState = &save.PanStateRecord{
		RegionsSeen: 1,
		Return: &save.PanReturnRecord{
			LevelID: 1,
			X:       3,
			Y:       3,
		},
	}

	if restored, err := Restore(snapshot); err == nil {
		restored.Close()
		t.Fatal("inactive Pan history accepted a return pointer")
	} else if !strings.Contains(err.Error(), "inactive Pan history") {
		t.Fatalf("Pan history error = %v", err)
	}
}

// Retired Pan maps still affect future uniqueness, so a mod removal must
// fail on restore instead of silently making the saved lord eligible again.
func TestRejectMissingPanHistoryMap(t *testing.T) {
	g := newGeneratedTestGame(t, 73)
	snapshot := g.Snapshot()
	snapshot.PanState = &save.PanStateRecord{
		RegionsSeen: 1,
		VaultIDs: []string{
			"pan_map_that_does_not_exist",
		},
	}

	if restored, err := Restore(snapshot); err == nil {
		restored.Close()
		t.Fatal("missing Pan map accepted in history")
	} else if !strings.Contains(err.Error(), "pan_map_that_does_not_exist") {
		t.Fatalf("Pan history error = %v", err)
	}
}
