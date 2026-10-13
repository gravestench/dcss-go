package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
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
	restored, err := Restore(g.Snapshot(), content.DefaultFixture())
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()
	commands := []Command{{Kind: CommandWait}, {Kind: CommandMove, DX: -1}, {Kind: CommandWait}}
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
	if _, err := Restore(snapshot, content.DefaultFixture()); err == nil || !strings.Contains(err.Error(), "MONS_NOT_IN_CATALOG") {
		t.Fatalf("unknown catalog ID error = %v", err)
	}
	snapshot = g.Snapshot()
	for i := range snapshot.Entities {
		if snapshot.Entities[i].Item != nil {
			snapshot.Entities[i].Item.KindID = "POT_NOT_IN_CATALOG"
		}
	}
	if _, err := Restore(snapshot, content.DefaultFixture()); err == nil || !strings.Contains(err.Error(), "POT_NOT_IN_CATALOG") {
		t.Fatalf("unknown item ID error = %v", err)
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
	if _, err := Restore(snapshot, content.DefaultFixture()); err == nil || !strings.Contains(err.Error(), "both") {
		t.Fatalf("double location error = %v", err)
	}
}

func TestRejectDuplicateOccupancy(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()
	for i := range snapshot.Entities {
		if snapshot.Entities[i].AI != nil {
			*snapshot.Entities[i].Position = ecs.Position{LevelID: 1, X: 1, Y: 1}
		}
	}
	if _, err := Restore(snapshot, content.DefaultFixture()); err == nil || !strings.Contains(err.Error(), "occupied") {
		t.Fatalf("duplicate occupancy error = %v", err)
	}
}

func TestFailedLoadLeavesLiveGame(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	invalid := g.Snapshot()
	invalid.Version = 2
	if _, err := Restore(invalid, content.DefaultFixture()); err == nil {
		t.Fatal("invalid save accepted")
	}
	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("failed restore changed live game")
	}
}
