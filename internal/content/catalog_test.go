package content

import "testing"

func mustLoadDefault(t *testing.T) Catalog {
	t.Helper()
	catalog, err := LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	return catalog
}

func TestRatFixture(t *testing.T) {
	catalog := mustLoadDefault(t)
	if err := catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	if catalog.Version() != 1 || catalog.SourceRevision() != "e60ba3568b0c26447ad36ec5c7b963eb04b2778f" {
		t.Fatalf("wrong fixture provenance: version %d source %s", catalog.Version(), catalog.SourceRevision())
	}
	rat, err := catalog.Monster("MONS_RAT")
	if err != nil {
		t.Fatal(err)
	}
	if rat.Glyph != 'r' || rat.Speed != 10 || rat.BaseDamage != 3 || rat.ScenarioHP != 4 {
		t.Fatalf("unexpected rat fixture: %+v", rat)
	}
	player := catalog.Player()
	if player.SpeciesID != "SP_HUMAN" || player.JobID != "JOB_FIGHTER" || player.BaseDamage != 4 {
		t.Fatalf("unexpected player fixture: %+v", player)
	}
	if _, err := catalog.Item("POT_CURING"); err != nil {
		t.Fatal(err)
	}
}

func TestCatalogRejectsUnknownID(t *testing.T) {
	if _, err := mustLoadDefault(t).Item("POT_NOT_REAL"); err == nil {
		t.Fatal("unknown item ID was accepted")
	}
}
