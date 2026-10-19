package game

import (
	"reflect"
	"testing"

	"crawl/internal/terrain"
)

func TestJellyGrowthDetectsHiddenFloorItemUntilActuallySeen(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]
	item := potionID(t, g)
	position, found := g.stores.Positions.Get(item)

	if !found {
		t.Fatal("curing potion has no floor position")
	}

	position.X = 10
	position.Y = 1

	if err := level.MoveActor(g.player, 6, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	index := 1*level.width + 10

	if g.visible[index] || level.KnownCells()[1][10] != terrain.Unseen {
		t.Fatal("fixture item must be hidden behind the central wall")
	}

	addPlayerMutation(t, g, "MUT_JELLY_GROWTH")

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if !level.DetectedItems()[1][10] {
		t.Fatal("Jelly Growth did not detect the hidden item")
	}

	view := g.View()

	if view.Cells[index].Glyph != '{' ||
		!view.Cells[index].DetectedItem {
		t.Fatalf("detected item not visible in map view: %+v", view.Cells[index])
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("detected item marker changed across save and restore")
	}

	if err := level.MoveActor(g.player, 9, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if level.DetectedItems()[1][10] {
		t.Fatal("actual sight did not clear the sensed item marker")
	}
}
