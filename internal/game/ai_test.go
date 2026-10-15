package game

import (
	"testing"
)

func TestFixedAnimalRouteAvoidsOccupantsAndUnreachableTarget(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]

	if err := level.MoveActor(g.player, 5, 1); err != nil {
		t.Fatal(err)
	}

	dx, dy, ok := level.RouteStep(4, 1, 6, 1, 0)

	if !ok ||
		(dx == 1 && dy == 0) {
		t.Fatalf("route stepped into occupied tile: %d,%d found %v", dx, dy, ok)
	}

	second := g.levels[2]
	second.terrain[4][8] = fixtureFeature('#')

	if _, _, ok := second.RouteStep(9, 1, 7, 1, 0); ok {
		t.Fatal("route crossed a sealed central wall")
	}
}
