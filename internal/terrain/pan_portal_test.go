package terrain

import "testing"

// Pan gates share the source arch glyph while retaining distinct IDs for
// Lua travel policy. Each is a traversable cell in the level grid.
func TestPanPortalFeatures(t *testing.T) {
	for _, id := range []ID{
		EnterPandemonium,
		TransitPandemonium,
		ExitPandemonium,
		ExitThroughAbyss,
	} {
		feature, found := Lookup(id)

		if !found ||
			!feature.Walkable ||
			feature.Glyph != '∩' {
			t.Fatalf("Pan portal %s = %+v, found %t", id, feature, found)
		}
	}
}
