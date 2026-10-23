package script

import (
	"testing"

	"github.com/gravestench/akara"
)

// A region may move a survivor into a retired actor's former cell. The
// pending occupancy must match the host's validated simultaneous move.
func TestStageRegionActorsRetiredCellBecomesOccupied(t *testing.T) {
	const survivor akara.Entity = 1
	const retired akara.Entity = 2

	oldSurvivor := gridCell{
		levelID: 1000,
		x:       10,
		y:       10,
	}

	oldRetired := gridCell{
		levelID: 1000,
		x:       11,
		y:       10,
	}

	runtime := &Runtime{
		pendingActors: map[gridCell]akara.Entity{},
		pendingPositions: map[akara.Entity]*gridCell{
			survivor: &oldSurvivor,
			retired:  &oldRetired,
		},
		pendingViews: map[componentTarget]*pendingComponent{},
	}

	stageRegionActors(runtime, 1000, []ActorMove{
		{
			Actor: survivor,
			X:     11,
			Y:     10,
		},
	}, []akara.Entity{retired})

	if got := runtime.pendingActors[oldRetired]; got != survivor {
		t.Fatalf("retired cell pending actor = %d, want %d", got, survivor)
	}

	if got := runtime.pendingActors[oldSurvivor]; got != 0 {
		t.Fatalf("survivor old cell remains occupied by %d", got)
	}
}
