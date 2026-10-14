package game

import (
	"encoding/json"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/save"
)

func TestPlayerNameSurvivesGoSaveAndRestore(t *testing.T) {
	g, err := NewScenario(19, testCatalog(t), "WPN_RAPIER", "Alice")
	if err != nil {
		t.Fatal(err)
	}
	defer g.Close()
	if view := g.View(); view.PlayerName != "Alice" || view.PlayerX != 1 || view.PlayerY != 1 || view.PlayerDead {
		t.Fatalf("new player view: %+v", view)
	}
	path := filepath.Join(t.TempDir(), "save.json")
	if err := save.Write(path, g.Snapshot()); err != nil {
		t.Fatal(err)
	}
	snapshot, err := save.Read(path)
	if err != nil {
		t.Fatal(err)
	}
	if snapshot.Version != save.Version || savedPlayer(t, &snapshot).Player.Name != "Alice" {
		t.Fatalf("saved player: %+v", snapshot)
	}
	restored, err := Restore(snapshot, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()
	if restored.View().PlayerName != "Alice" {
		t.Fatalf("restored name: %q", restored.View().PlayerName)
	}
}

func TestOldVersionFourSaveWithoutNameDisplaysAdventurer(t *testing.T) {
	g, err := NewScenario(19, testCatalog(t), "WPN_RAPIER", "Alice")
	if err != nil {
		t.Fatal(err)
	}
	defer g.Close()
	snapshot := g.Snapshot()
	savedPlayer(t, &snapshot).Player.Name = ""
	encoded, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(encoded), `"Name"`) {
		t.Fatal("legacy snapshot unexpectedly contains a name")
	}
	var old save.Snapshot
	if err := json.Unmarshal(encoded, &old); err != nil {
		t.Fatal(err)
	}
	restored, err := Restore(old, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()
	if restored.View().PlayerName != "Adventurer" {
		t.Fatalf("legacy name: %q", restored.View().PlayerName)
	}
}

func TestRestoreRejectsInvalidSavedName(t *testing.T) {
	g, err := NewScenario(19, testCatalog(t), "WPN_RAPIER", "Alice")
	if err != nil {
		t.Fatal(err)
	}
	defer g.Close()
	snapshot := g.Snapshot()
	savedPlayer(t, &snapshot).Player.Name = "Bad!"
	if _, err := Restore(snapshot, testCatalog(t)); err == nil || !strings.Contains(err.Error(), "name") {
		t.Fatalf("bad saved name accepted: %v", err)
	}
}
