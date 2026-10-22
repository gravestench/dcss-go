package terrain

import "testing"

// The source Bazaar uses an entry arch and a separate exit arch. Their
// identities must reach Lua travel policy through the live terrain grid.
func TestBazaarPortalFeatures(t *testing.T) {
	for _, id := range []ID{EnterBazaar, ExitBazaar} {
		feature, found := Lookup(id)

		if !found ||
			!feature.Walkable ||
			feature.Glyph != '∩' {
			t.Errorf("Bazaar portal %s = %+v, found %t", id, feature, found)
		}
	}
}
