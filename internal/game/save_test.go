package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

func TestSaveContinuationMatches(t *testing.T) {
	g := newStepGame(t)
	if err := g.levels[1].MoveActor(g.player, 4, 2); err != nil {
		t.Fatal(err)
	}
	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}
	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}
	restored, err := Restore(g.Snapshot(), testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()
	commands := []Command{{Kind: CommandWait}, {
		Kind: CommandMove,
		DX:   -1,
	}, {Kind: CommandWait}}
	for _, command := range commands {
		left, leftErr := g.Step(command)
		right, rightErr := restored.Step(command)
		if leftErr != nil || rightErr != nil || !reflect.DeepEqual(left, right) {
			t.Fatalf("continuation differs: %+v/%v vs %+v/%v", left, leftErr, right, rightErr)
		}
	}
	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("snapshots diverged after continuation")
	}
}

func TestRejectUnknownCatalogID(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()
	for i := range snapshot.Entities {
		if snapshot.Entities[i].AI != nil {
			snapshot.Entities[i].Actor.KindID = "MONS_NOT_IN_CATALOG"
		}
	}
	if _, err := Restore(snapshot, testCatalog(t)); err == nil || !strings.Contains(err.Error(), "MONS_NOT_IN_CATALOG") {
		t.Fatalf("unknown catalog ID error = %v", err)
	}
	snapshot = g.Snapshot()
	for i := range snapshot.Entities {
		if snapshot.Entities[i].Item != nil {
			snapshot.Entities[i].Item.KindID = "POT_NOT_IN_CATALOG"
		}
	}
	if _, err := Restore(snapshot, testCatalog(t)); err == nil || !strings.Contains(err.Error(), "POT_NOT_IN_CATALOG") {
		t.Fatalf("unknown item ID error = %v", err)
	}
}

func TestKnownIncompleteItemRestore(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	invalid := g.Snapshot()
	changed := false
	for i := range invalid.Entities {
		if invalid.Entities[i].Item != nil {
			invalid.Entities[i].Item.KindID = "POT_GAIN_STRENGTH"
			changed = true
			break
		}
	}
	if !changed {
		t.Fatal("scenario has no item to test")
	}
	if restored, err := Restore(invalid, testCatalog(t)); err == nil {
		restored.Close()
		t.Fatal("known but undefined legacy item restored")
	}
	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("failed restore changed live game")
	}
}

func TestRejectDoubleLocatedItem(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()
	for i := range snapshot.Entities {
		if snapshot.Entities[i].Item != nil {
			snapshot.Entities[i].CarriedBy = &ecs.CarriedBy{Holder: g.player}
		}
	}
	if _, err := Restore(snapshot, testCatalog(t)); err == nil || !strings.Contains(err.Error(), "both") {
		t.Fatalf("double location error = %v", err)
	}
}

func TestRejectDuplicateOccupancy(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()
	for i := range snapshot.Entities {
		if snapshot.Entities[i].AI != nil {
			*snapshot.Entities[i].Position = ecs.Position{
				LevelID: 1,
				X:       1,
				Y:       1,
			}
		}
	}
	if _, err := Restore(snapshot, testCatalog(t)); err == nil || !strings.Contains(err.Error(), "occupied") {
		t.Fatalf("duplicate occupancy error = %v", err)
	}
}

func TestFailedLoadLeavesLiveGame(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	invalid := g.Snapshot()
	invalid.Version = 2
	if _, err := Restore(invalid, testCatalog(t)); err == nil {
		t.Fatal("invalid save accepted")
	}
	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("failed restore changed live game")
	}
}

func TestScenarioAttributesAndView(t *testing.T) {
	g := newStepGame(t)
	attributes, found := g.stores.Attributes.Get(g.player)
	if !found || *attributes != (ecs.Attributes{
		Strength:     16,
		Intelligence: 8,
		Dexterity:    12,
	}) {
		t.Fatalf("player attributes = %+v, found %v", attributes, found)
	}
	view := g.View()
	if view.CharacterName != "Human Fighter" || view.Attributes != *attributes || view.PlayerHP != 18 {
		t.Fatalf("view = %+v", view)
	}
	if snapshot := g.Snapshot(); snapshot.Version != save.Version {
		t.Fatalf("save version = %d, want %d", snapshot.Version, save.Version)
	}
}

func TestRestoreRejectsCorruptAttributesWithoutChangingLiveGame(t *testing.T) {
	for _, tc := range []struct {
		name   string
		mutate func(*save.Snapshot)
	}{
		{"missing player attributes", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Player != nil {
					snapshot.Entities[i].Attributes = nil
				}
			}
		}},
		{"mismatched attributes", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Player != nil {
					snapshot.Entities[i].Attributes.Strength++
				}
			}
		}},
		{"nonpositive attributes", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Player != nil {
					snapshot.Entities[i].Attributes.Dexterity = 0
				}
			}
		}},
		{"monster attributes", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].AI != nil {
					snapshot.Entities[i].Attributes = &ecs.Attributes{
						Strength:     8,
						Intelligence: 8,
						Dexterity:    8,
					}
				}
			}
		}},
		{"item attributes", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Item != nil {
					snapshot.Entities[i].Attributes = &ecs.Attributes{
						Strength:     8,
						Intelligence: 8,
						Dexterity:    8,
					}
				}
			}
		}},
		{"version 1", func(snapshot *save.Snapshot) { snapshot.Version = 1 }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newStepGame(t)
			before := g.Snapshot()
			invalid := g.Snapshot()
			tc.mutate(&invalid)
			if restored, err := Restore(invalid, testCatalog(t)); err == nil {
				restored.Close()
				t.Fatal("corrupt attributes accepted")
			}
			if !reflect.DeepEqual(before, g.Snapshot()) {
				t.Fatal("failed restore modified live game")
			}
		})
	}
}

func TestRestoreRejectsCorruptComponents(t *testing.T) {
	for _, test := range []struct {
		name   string
		mutate func(*save.Snapshot)
	}{
		{"negative shield blocks", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Player != nil {
					snapshot.Entities[i].Combatant.ShieldBlocks = -1
				}
			}
		}},
		{"item health", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Item != nil {
					snapshot.Entities[i].Health = &ecs.Health{
						Current: 0,
						Max:     1,
					}
				}
			}
		}},
	} {
		t.Run(test.name, func(t *testing.T) {
			g := newStepGame(t)
			snapshot := g.Snapshot()
			test.mutate(&snapshot)
			if restored, err := Restore(snapshot, testCatalog(t)); err == nil {
				restored.Close()
				t.Fatal("corrupt components accepted")
			}
		})
	}
}

func TestRestoreRejectsClockMismatch(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()
	snapshot.CurrentAut = 100
	if restored, err := Restore(snapshot, testCatalog(t)); err == nil {
		restored.Close()
		t.Fatal("clock mismatch accepted")
	}
}

func TestRestoreAcceptsDeadPlayerClock(t *testing.T) {
	g := newStepGame(t)
	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}
	health, _ := g.stores.Health.Get(g.player)
	health.Current = 1
	for turn := 0; turn < 10 && !g.playerDead(); turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}
	if !g.playerDead() {
		t.Fatal("rat did not kill the low-health player")
	}
	restored, err := Restore(g.Snapshot(), testCatalog(t))
	if err != nil {
		t.Fatalf("valid dead-player snapshot rejected: %v", err)
	}
	defer restored.Close()
}
