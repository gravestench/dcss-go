package terrain

import "testing"

// Exploration asks whether a feature fills space, not whether a player
// without the right movement ability can walk through it.
func TestSolidDistinguishesWallsFromOpenHazards(t *testing.T) {
	for _, feature := range []ID{DeepWater, Lava} {
		if Solid(feature) {
			t.Errorf("%s should be open terrain", feature)
		}
	}

	for _, feature := range []ID{
		RockWall,
		ClearRockWall,
		ClosedDoor,
		OpenSea,
		LavaSea,
		EndlessSalt,
	} {
		if !Solid(feature) {
			t.Errorf("%s should be solid terrain", feature)
		}
	}
}
