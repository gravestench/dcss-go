package terrain

import "testing"

// The two live Ossuary arches have separate IDs for Lua travel policy,
// while both remain walkable and draw the source portal glyph in the client.
func TestOssuaryPortalFeatures(t *testing.T) {
	for _, id := range []ID{EnterOssuary, ExitOssuary} {
		feature, found := Lookup(id)

		if !found ||
			!feature.Walkable ||
			feature.Glyph != '∩' {
			t.Errorf("Ossuary portal %s = %+v, found %t",
				id, feature, found)
		}
	}
}
