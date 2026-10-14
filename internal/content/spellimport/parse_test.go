package spellimport

import (
	"strings"
	"testing"
)

func TestParseSyntheticSpellSources(t *testing.T) {
	enum := []byte(`enum spell_type : int {
  SPELL_NO_SPELL,
  SPELL_FOO,
  SPELL_FIRST_SPELL = SPELL_FOO,
#if TAG_MAJOR_VERSION == 34
  SPELL_OLD,
#endif
  NUM_SPELLS
};`)
	data := []byte(`static const struct spell_desc spelldata[] = {
{
 SPELL_NO_SPELL, "nonexistent spell", spschool::none, spflag::testing,
 1, 0, -1, -1, 1, 0, TILEG_ERROR,
},
{
 SPELL_FOO, "Foo", spschool::fire | spschool::air,
 spflag::target | spflag::monster,
 3, 200, LOS_RADIUS, LOS_RADIUS, 2, 0, TILEG_FOO,
},
#if TAG_MAJOR_VERSION == 34
#define AXED_SPELL(tag, name) \
 { tag, name, spschool::none, spflag::none, 7, 0, -1, -1, 0, 0, TILEG_ERROR },
AXED_SPELL(SPELL_OLD, "Old")
#endif
};`)
	removed := []byte(`const set<spell_type> removed_spells = {
#if TAG_MAJOR_VERSION == 34
 SPELL_OLD,
#endif
};`)
	ids, err := parseEnum("spell-type.h", enum)
	if err != nil || len(ids) != 3 || ids[0].ID != "SPELL_NO_SPELL" || ids[1].NumericID != 1 || ids[2].ID != "SPELL_OLD" {
		t.Fatalf("enum %+v, %v", ids, err)
	}
	spells, err := parseSpells("spl-data.h", data)
	if err != nil || len(spells) != 3 {
		t.Fatalf("spells %+v, %v", spells, err)
	}
	if spells["SPELL_FOO"].Name != "Foo" || len(spells["SPELL_FOO"].Schools) != 2 ||
		spells["SPELL_FOO"].MinRangeExpr != "LOS_RADIUS" || len(spells["SPELL_FOO"].Flags) != 2 {
		t.Fatalf("Foo %+v", spells["SPELL_FOO"])
	}
	removedIDs, err := parseRemoved("spl-util.cc", removed)
	if err != nil || len(removedIDs) != 1 || !removedIDs["SPELL_OLD"] {
		t.Fatalf("removed %+v, %v", removedIDs, err)
	}
	if err := reconcile(ids, spells, removedIDs); err != nil {
		t.Fatal(err)
	}
	if _, err := parseSpells(
		"spl-data.h",
		[]byte(strings.Replace(
			string(data),
			"spflag::none, 7, 0",
			"spflag::none, 6, 0",
			1,
		)),
	); err == nil {
		t.Fatal("accepted changed AXED_SPELL expansion")
	}
	if _, err := parseSpells(
		"spl-data.h",
		[]byte(strings.Replace(
			string(data),
			"AXED_SPELL(SPELL_OLD, \"Old\")",
			"AXED_SPELL(SPELL_OLD, \"Old\")\nAXED_SPELL(SPELL_UNKNOWN, 42)",
			1,
		)),
	); err == nil {
		t.Fatal("silently skipped malformed extra AXED_SPELL row")
	}
	delete(spells, "SPELL_FOO")
	if err := reconcile(ids, spells, removedIDs); err == nil {
		t.Fatal("accepted missing descriptor")
	}
}
