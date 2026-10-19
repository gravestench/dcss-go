package game

import (
	"testing"

	"crawl/internal/terrain"
)

func TestSealedStairRetainsLinkAndBlocksTravel(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]

	if err := level.MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}

	if err := level.SetCell(7, 3, terrain.SealedStairsDown); err != nil {
		t.Fatal(err)
	}

	if _, linked := level.StairAt(7, 3); !linked {
		t.Fatal("sealing removed the outgoing stair link")
	}

	result, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 {
		t.Fatalf("sealed stair travel spent %d aut", result.Spent)
	}

	if err := level.SetCell(7, 3, terrain.StairsDown); err != nil {
		t.Fatal(err)
	}

	if _, linked := level.StairAt(7, 3); !linked {
		t.Fatal("restoring the stair lost its outgoing link")
	}
}
