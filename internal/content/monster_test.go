package content

import (
	"reflect"
	"strings"
	"testing"
)

func testMonster(id string) MonsterDef {
	return MonsterDef{
		ID: id, Status: MonsterDefined, SourcePath: "crawl-ref/source/mon-data.h", SourceLine: 1994,
		Name: "rat", Glyph: 'r', ColourID: "BROWN", Flags: []string{"M_WARM_BLOOD"},
		Resistances: []MonsterResistance{{ID: "MR_RES_FIRE", Level: 1}}, XPModifier: 1,
		GenusID: id, SpeciesID: id, Holiness: []string{"MH_NATURAL"},
		Attacks: [4]MonsterAttack{{TypeID: "AT_BITE", FlavourID: "AF_PLAIN", Damage: 3},
			{TypeID: "AT_NONE", FlavourID: "AF_PLAIN"}, {TypeID: "AT_NONE", FlavourID: "AF_PLAIN"}, {TypeID: "AT_NONE", FlavourID: "AF_PLAIN"}},
		HD: 1, AverageHP10x: 25, AC: 1, EV: 10, SpellbookID: "MST_NO_SPELLS",
		LeavesCorpse: true, ShoutID: "S_SILENT", IntelligenceID: "I_ANIMAL", HabitatID: "HT_LAND",
		Speed: 10, Energy: MonsterEnergy{Move: 10, Swim: 10, Attack: 10, Missile: 10, Spell: 10, Special: 10, Item: 10, PickupPercent: 100},
		ItemUseID: "MONUSE_NOTHING", SizeID: "SIZE_TINY", ShapeID: "MON_SHAPE_QUADRUPED",
		Tile: MonsterTile{ID: "TILEP_MONS_RAT", VariationID: "TVARY_NONE"}, CorpseTileID: "TILE_CORPSE_RAT",
	}
}

func TestMonsterArtifactValidation(t *testing.T) {
	rat := testMonster("MONS_RAT")
	base := MonsterArtifact{SchemaVersion: 1, SourceRevision: sourceRevision, TagMajorVersion: 34,
		SourceFiles: []JobSourceFile{{Path: "crawl-ref/source/mon-data.h", SHA256: strings.Repeat("a", 64)}},
		Monsters:    []MonsterDef{rat}}
	if err := base.Validate(); err != nil {
		t.Fatalf("valid monster artifact rejected: %v", err)
	}
	cases := []struct {
		name string
		edit func(*MonsterArtifact)
	}{
		{"duplicate", func(a *MonsterArtifact) { a.Monsters = append(a.Monsters, rat) }},
		{"unsorted", func(a *MonsterArtifact) { a.Monsters = append(a.Monsters, testMonster("MONS_AAA")) }},
		{"bad status", func(a *MonsterArtifact) { a.Monsters[0].Status = "bogus" }},
		{"missing attack", func(a *MonsterArtifact) { a.Monsters[0].Attacks[0].TypeID = "" }},
		{"removed live data", func(a *MonsterArtifact) { a.Monsters[0].Status = MonsterRemoved }},
		{"enum-only live data", func(a *MonsterArtifact) { a.Monsters[0].Status = MonsterEnumOnly }},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a := base
			a.Monsters = append([]MonsterDef(nil), base.Monsters...)
			tc.edit(&a)
			if err := a.Validate(); err == nil {
				t.Fatal("invalid monster artifact accepted")
			}
		})
	}
}

func TestMonsterCatalogCopiesAndStatuses(t *testing.T) {
	rat := testMonster("MONS_RAT")
	c := Catalog{monsters: map[string]MonsterDef{
		"MONS_RAT":       rat,
		"MONS_BUMBLEBEE": {ID: "MONS_BUMBLEBEE", Status: MonsterRemoved, SourcePath: "crawl-ref/source/mon-data.h", Name: "bumblebee"},
		"MONS_BEAR":      {ID: "MONS_BEAR", Status: MonsterEnumOnly, SourcePath: "crawl-ref/source/monster-type.h"},
	}}
	first, err := c.Monster("MONS_RAT")
	if err != nil {
		t.Fatal(err)
	}
	first.Flags[0] = "M_CANT_SPAWN"
	first.Holiness[0] = "MH_UNDEAD"
	first.Resistances[0].Level = 3
	ids := c.MonsterIDs()
	if !reflect.DeepEqual(ids, []string{"MONS_BEAR", "MONS_BUMBLEBEE", "MONS_RAT"}) {
		t.Fatalf("unsorted monster IDs: %v", ids)
	}
	ids[0] = "changed"
	again, err := c.Monster("MONS_RAT")
	if err != nil || !reflect.DeepEqual(again, rat) {
		t.Fatalf("catalog changed through returned monster: %+v, %v", again, err)
	}
	for _, id := range []string{"MONS_BUMBLEBEE", "MONS_BEAR"} {
		if _, err := c.Monster(id); err == nil {
			t.Fatalf("non-live monster %s returned as a definition", id)
		}
		if _, err := c.MonsterStatus(id); err != nil {
			t.Fatalf("status for %s unavailable: %v", id, err)
		}
	}
	if _, err := c.MonsterStatus("MONS_UNKNOWN"); err == nil {
		t.Fatal("unknown monster has a status")
	}
}
