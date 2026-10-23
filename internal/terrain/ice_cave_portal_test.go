package terrain

import "testing"

// The live arch, return exit, and melted portal have separate saved IDs.
// All are walkable and keep the source terminal arch glyph.
func TestIceCavePortalFeatures(t *testing.T) {
	for _, id := range []ID{
		EnterIceCave,
		ExitIceCave,
		ExpiredPortal,
	} {
		feature, found := Lookup(id)

		if !found ||
			!feature.Walkable ||
			feature.Glyph != '∩' {
			t.Errorf("Ice Cave portal %s = %+v, found %t", id, feature, found)
		}
	}
}
