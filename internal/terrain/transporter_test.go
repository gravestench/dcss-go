package terrain

import "testing"

// Transporters are walkable same-floor features. Their landing site has the
// source console glyph but is not a second outbound stair or transporter.
func TestTransporterFeaturesAreWalkableAndDistinct(t *testing.T) {
	for _, id := range []ID{
		Transporter,
		TransporterLanding,
	} {
		if !Valid(id) ||
			!Walkable(id) ||
			Glyph(id) != '©' {
			t.Fatalf("transporter feature %q lacks its walkable console glyph", id)
		}

		if IsLinkedStair(id) {
			t.Fatalf("transporter feature %q became a level stair", id)
		}
	}

	if Transporter == TransporterLanding {
		t.Fatal("landing must remain distinct from outbound transporter")
	}
}

// Xom's source stair action can move directional portals and exits, but
// a shop and same-floor transporter have different interaction commands.
func TestMovableTravelFeaturesExcludeShopsAndTransporters(t *testing.T) {
	for _, feature := range []ID{
		StairsDown,
		EnterOssuary,
		ExitOssuary,
		EnterPandemonium,
		EnterHell,
	} {
		if !IsMovableTravelFeature(feature) {
			t.Fatalf("Xom cannot move travel feature %q", feature)
		}
	}

	for _, feature := range []ID{
		ShopEntrance,
		Transporter,
		TransporterLanding,
		ExpiredPortal,
	} {
		if IsMovableTravelFeature(feature) {
			t.Fatalf("Xom can move nontravel feature %q", feature)
		}
	}
}
