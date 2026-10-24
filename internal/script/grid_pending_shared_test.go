package script

import (
	"slices"
	"testing"

	"github.com/gravestench/akara"
)

// An action may grow a plant beneath the player and then remove it before
// commit. Staged reads must retain the player throughout that sequence.
func TestStagedSharedActorCell(t *testing.T) {
	const player akara.Entity = 1
	const plant akara.Entity = 2

	cell := gridCell{
		levelID: 1,
		x:       3,
		y:       4,
	}

	runtime := &Runtime{
		pendingActors: map[gridCell][]akara.Entity{
			cell: {player},
		},
		pendingPositions: map[akara.Entity]*gridCell{
			player: &cell,
		},
		pendingViews: map[componentTarget]*pendingComponent{},
	}

	runtime.stageActorPositionShared(plant, nil, &cell, false)

	if got := runtime.stagedActorsAt(cell); !slices.Equal(got, []akara.Entity{player, plant}) {
		t.Fatalf("staged shared actors = %v", got)
	}

	runtime.stageActorPosition(plant, &cell, nil)

	if got := runtime.stagedActorsAt(cell); !slices.Equal(got, []akara.Entity{player}) {
		t.Fatalf("staged actors after plant removal = %v", got)
	}
}
