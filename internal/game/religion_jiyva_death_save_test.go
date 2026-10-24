package game

import (
	"reflect"
	"strings"
	"testing"
)

// Royal Jelly death is a permanent player fact. Saving and restoring it
// must not depend on whether Slime:5 has already been generated.
func TestRoyalJellyDeathFlagSurvivesRestore(t *testing.T) {
	g, err := NewScenario(1, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	store := g.scripts.Components()["religion.worship"]
	current, exists := store.Get(g.player)

	if !exists {
		t.Fatal("player has no worship component")
	}

	if err := current.Set("royal_jelly_dead", true); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("Royal Jelly death changed across restore")
	}
}

// Version 36 lacks the Jiyva death field. Refuse it before a missing
// value could make a dead god available again after restore.
func TestRoyalJellyDeathRequiresNewSaveVersion(t *testing.T) {
	g, err := NewScenario(1, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	snapshot := g.Snapshot()
	snapshot.Version = 36
	loaded, err := Restore(snapshot)

	if loaded != nil {
		_ = loaded.Close()
	}

	if err == nil || !strings.Contains(err.Error(),
		"unsupported save version 36") {
		t.Fatalf("old Jiyva save version accepted: %v", err)
	}
}
