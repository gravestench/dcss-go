package terrain

import "testing"

// Live portal arches, return exits, and expired portals have separate saved
// IDs. All are walkable and keep the source terminal arch glyph.
func TestPortalFeatures(t *testing.T) {
	for _, id := range []ID{
		EnterIceCave,
		ExitIceCave,
		EnterVolcano,
		ExitVolcano,
		EnterTrove,
		ExitTrove,
		ExpiredPortal,
	} {
		feature, found := Lookup(id)

		if !found ||
			!feature.Walkable ||
			feature.Glyph != '∩' {
			t.Errorf("portal %s = %+v, found %t", id, feature, found)
		}
	}
}
