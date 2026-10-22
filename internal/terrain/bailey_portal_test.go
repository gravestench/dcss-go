package terrain

import "testing"

// Bailey's live gate, return exit, and closed stone arch have separate
// identities, but all remain walkable and use the source arch glyph.
func TestBaileyPortalFeatures(t *testing.T) {
	for _, id := range []ID{
		EnterBailey,
		ExitBailey,
		StoneArch,
	} {
		feature, found := Lookup(id)

		if !found ||
			!feature.Walkable ||
			feature.Glyph != '∩' {
			t.Errorf("Bailey portal %s = %+v, found %t", id, feature, found)
		}
	}
}
