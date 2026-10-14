package game

import (
	"testing"

	"github.com/gravestench/akara"
)

func spawnWormForTest(t *testing.T, g *Game, levelID int) akara.Entity {
	t.Helper()
	level := g.levels[levelID]
	cells := level.spawnCellsAwayFrom(point{}, 0)

	if len(cells) == 0 {
		t.Fatalf("D:%d has no free worm spawn cell", levelID)
	}

	cell := cells[0]
	worm, err := newOrdinaryMonsterFactory(g).Spawn(
		"MONS_WORM",
		levelID,
		cell.x,
		cell.y,
	)

	if err != nil {
		t.Fatal(err)
	}

	return worm
}
