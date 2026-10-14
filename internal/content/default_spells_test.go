package content

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestCommittedSpellCatalogCoverageAndCopies(t *testing.T) {
	catalog, err := LoadDefault()
	if err != nil {
		t.Fatal(err)
	}

	ids := catalog.SpellIDs()
	if len(ids) != 403 || ids[0] != "SPELL_NO_SPELL" || ids[1] != "SPELL_TELEPORT_SELF" {
		t.Fatalf("spell IDs count/order %d, %v", len(ids), ids[:min(2, len(ids))])
	}

	ids[0] = "corrupted"
	if catalog.SpellIDs()[0] != "SPELL_NO_SPELL" {
		t.Fatal("spell IDs alias catalog")
	}

	magic, err := catalog.Spell("SPELL_MAGIC_DART")
	if err != nil || magic.NumericID != 3 || magic.Name != "Magic Dart" || magic.Level != 1 ||
		magic.PowerCap != 25 || magic.MinRangeExpr != "LOS_RADIUS" || magic.TileID != "TILEG_MAGIC_DART" {
		t.Fatalf("magic dart %+v, %v", magic, err)
	}

	magic.Schools[0] = "changed"
	again, _ := catalog.Spell("SPELL_MAGIC_DART")
	if again.Schools[0] != "conjuration" {
		t.Fatal("spell schools alias catalog")
	}

	for id, status := range map[string]SpellStatus{
		"SPELL_NO_SPELL":      SpellSentinel,
		"SPELL_TELEPORT_SELF": SpellRemoved,
		"SPELL_SONIC_WAVE":    SpellDefined,
	} {
		got, err := catalog.SpellStatus(id)
		if err != nil || got != status {
			t.Fatalf("%s status %s, %v", id, got, err)
		}
	}

	if _, err := catalog.Spell("SPELL_TELEPORT_SELF"); err == nil {
		t.Fatal("removed spell is castable")
	}

	if _, err := catalog.Spell("SPELL_NO_SPELL"); err == nil {
		t.Fatal("sentinel is castable")
	}

	if _, err := catalog.Spell("SPELL_NOT_REAL"); err == nil {
		t.Fatal("unknown spell accepted")
	}
}

func TestCommittedSpellArtifactRejectsMissingOrCorruptRows(t *testing.T) {
	var artifact SpellArtifact
	if err := json.Unmarshal(defaultSpellJSON, &artifact); err != nil {
		t.Fatal(err)
	}

	if err := artifact.Validate(); err != nil {
		t.Fatal(err)
	}

	artifact.Spells[3].Schools = []string{""}
	if err := artifact.Validate(); err == nil {
		t.Fatal("accepted empty school")
	}

	if _, err := attachDefaultSpells(scenarioCatalog(), []byte(`{"schema_version":1}`)); err == nil {
		t.Fatal("accepted incomplete spell catalog")
	}

	if _, err := attachDefaultSpells(
		scenarioCatalog(),
		[]byte(strings.Replace(
			string(defaultSpellJSON),
			`"numeric_id": 3`,
			`"numeric_id": 999`,
			1,
		)),
	); err == nil {
		t.Fatal("accepted corrupted artifact")
	}

	if _, err := attachDefaultSpells(
		scenarioCatalog(),
		[]byte(strings.Replace(
			string(defaultSpellJSON),
			"SPELL_MAGIC_DART",
			"SPELL_BOGUS",
			1,
		)),
	); err == nil {
		t.Fatal("accepted same-count identity substitution")
	}

	if _, err := attachDefaultSpells(
		scenarioCatalog(),
		[]byte(strings.Replace(
			string(defaultSpellJSON),
			"91be664ef01f81d4401e4fd4ef0aff709a96f464c7035558435fb1bc135da2e1",
			strings.Repeat(
				"0",
				64,
			),
			1,
		)),
	); err == nil {
		t.Fatal("accepted substituted source hash")
	}
}
