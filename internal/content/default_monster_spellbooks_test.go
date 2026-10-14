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
		slots[0].FlagID != "MON_SPELL_NATURAL" {
		t.Fatalf("source endoplasm slot %+v", slots[0])
	}

	slots[0].SpellID = "SPELL_NOT_REAL"

	again, _ := catalog.MonsterSpellbook("MST_ENDOPLASM")

	if again[0].SpellID != "SPELL_FREEZE" {
		t.Fatal("spellbook caller changed catalog state")
	}
}

func TestEndoplasmSpellbookRejectsUnknownSpell(t *testing.T) {
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
