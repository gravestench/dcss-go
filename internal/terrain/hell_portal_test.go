package terrain

import "testing"

// All ten source Hell gates must remain walkable arch cells with distinct
// identities so Lua can route their destinations from the terrain grid.
func TestHellPortalFeatures(t *testing.T) {
	ids := []ID{
		EnterHell,
		ExitHell,
		EnterDis,
		ExitDis,
		EnterGehenna,
		ExitGehenna,
		EnterCocytus,
		ExitCocytus,
		EnterTartarus,
		ExitTartarus,
	}

	for _, id := range ids {
		feature, found := Lookup(id)

		if !found ||
			!feature.Walkable ||
			feature.Glyph != '∩' {
			t.Errorf("Hell portal %s = %+v, found %t", id, feature, found)
		}
	}
}
