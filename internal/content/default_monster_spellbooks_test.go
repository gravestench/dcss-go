package content

import (
	"encoding/json"
	"testing"
)

func TestCommittedEndoplasmSpellbook(t *testing.T) {
	catalog, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	slots, err := catalog.MonsterSpellbook("MST_ENDOPLASM")

	if err != nil ||
		len(slots) != 1 {
		t.Fatalf("endoplasm spellbook %+v, %v", slots, err)
	}

	if slots[0].SpellID != "SPELL_FREEZE" ||
		slots[0].Frequency != 70 ||
		len(slots[0].Flags) != 1 ||
		slots[0].Flags[0] != "MON_SPELL_NATURAL" {
		t.Fatalf("source endoplasm slot %+v", slots[0])
	}

	slots[0].SpellID = "SPELL_NOT_REAL"
	slots[0].Flags[0] = "MON_SPELL_NOT_REAL"

	again, _ := catalog.MonsterSpellbook("MST_ENDOPLASM")

	if again[0].SpellID != "SPELL_FREEZE" ||
		again[0].Flags[0] != "MON_SPELL_NATURAL" {
		t.Fatal("spellbook caller changed catalog state")
	}
}

func TestCommittedMonsterSpellbooksCoverPinnedTable(t *testing.T) {
	var artifact MonsterSpellbookArtifact

	if err := json.Unmarshal(defaultMonsterSpellbookJSON, &artifact); err != nil {
		t.Fatal(err)
	}

	if len(artifact.Books) != 285 {
		t.Fatalf("committed %d monster spellbooks, want 285", len(artifact.Books))
	}

	slotCount := 0

	for _, book := range artifact.Books {
		slotCount += len(book.Slots)
	}

	if slotCount != 697 {
		t.Fatalf("committed %d monster spell slots, want 697", slotCount)
	}

	catalog, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	checks := map[string]string{
		"MST_ENDOPLASM":          "SPELL_FREEZE",
		"MST_DART_SLUG":          "SPELL_SLUG_DART",
		"MST_ORC_WIZARD":         "SPELL_MAGIC_DART",
		"MST_FIRE_DRAGON_BREATH": "SPELL_FIRE_BREATH",
	}

	for bookID, spellID := range checks {
		slots, err := catalog.MonsterSpellbook(bookID)

		if err != nil ||
			len(slots) == 0 {
			t.Fatalf("book %s: %+v, %v", bookID, slots, err)
		}

		found := false

		for _, slot := range slots {
			found = found || slot.SpellID == spellID
		}

		if !found {
			t.Fatalf("book %s lacks %s: %+v", bookID, spellID, slots)
		}
	}

	breath, _ := catalog.MonsterSpellbook("MST_FIRE_DRAGON_BREATH")

	if breath[0].SourceLine != 811 ||
		breath[0].Frequency != 62 ||
		len(breath[0].Flags) != 3 ||
		breath[0].Flags[2] != "MON_SPELL_NOISY" {
		t.Fatalf("source dragon breath %+v", breath[0])
	}
}

func TestMonsterSpellbookRejectsUnknownSpell(t *testing.T) {
	catalog, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	var artifact MonsterSpellbookArtifact

	if err := json.Unmarshal(defaultMonsterSpellbookJSON, &artifact); err != nil {
		t.Fatal(err)
	}

	artifact.Books[0].Slots[0].SpellID = "SPELL_NOT_REAL"

	invalid, err := json.Marshal(artifact)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := attachDefaultMonsterSpellbooks(catalog, invalid); err == nil {
		t.Fatal("accepted unknown committed monster spell")
	}
}
