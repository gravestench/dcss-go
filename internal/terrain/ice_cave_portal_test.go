package terrain

import "testing"

// Live arches, return exits, and expired portals have separate saved IDs.
// All are walkable and keep the source terminal arch glyph.
func TestTimedPortalFeatures(t *testing.T) {
	for _, id := range []ID{
		EnterIceCave,
		ExitIceCave,
		EnterVolcano,
		ExitVolcano,
		ExpiredPortal,
	} {
		feature, found := Lookup(id)

		if !found ||
			!feature.Walkable ||
			feature.Glyph != '∩' {
			t.Errorf("timed portal %s = %+v, found %t", id, feature, found)
		}
	}
}
