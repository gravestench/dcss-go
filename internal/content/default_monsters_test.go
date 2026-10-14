package content

import (
	"encoding/json"
	"sort"
	"strings"
	"testing"
)

func TestLoadDefaultMonstersAndSourceFields(t *testing.T) {
	c, err := LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	counts := map[MonsterStatus]int{}
	for _, id := range c.MonsterIDs() {
		status, err := c.MonsterStatus(id)
		if err != nil {
			t.Fatal(err)
		}
		counts[status]++
	}
	if len(c.MonsterIDs()) != 700 || counts[MonsterDefined] != 562 || counts[MonsterRemoved] != 120 || counts[MonsterEnumOnly] != 18 {
		t.Fatalf("monster partition: %d %+v", len(c.MonsterIDs()), counts)
	}
	rat, err := c.Monster("MONS_RAT")
	if err != nil {
		t.Fatal(err)
	}
	if rat.Glyph != 'r' || rat.Speed != 10 || rat.AverageHP10x != 25 || rat.Attacks[0] != (MonsterAttack{
		TypeID:    "AT_BITE",
		FlavourID: "AF_PLAIN",
		Damage:    3,
	}) {
		t.Fatalf("rat source fields: %+v", rat)
	}
	rat.Flags[0] = "changed"
	again, _ := c.Monster("MONS_RAT")
	if again.Flags[0] != "M_WARM_BLOOD" {
		t.Fatal("monster flags escaped catalog ownership")
	}
	for _, id := range []string{"MONS_BUMBLEBEE", "MONS_BEAR"} {
		if _, err := c.Monster(id); err == nil {
			t.Fatalf("placeholder %s became live", id)
		}
	}
}

func TestLoadDefaultRejectsBadMonsterArtifact(t *testing.T) {
	var original MonsterArtifact
	if err := json.Unmarshal(defaultMonsterJSON, &original); err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		name string
		edit func(*MonsterArtifact)
	}{
		{"schema", func(a *MonsterArtifact) { a.SchemaVersion = 2 }},
		{"revision", func(a *MonsterArtifact) { a.SourceRevision = "other" }},
		{"tag", func(a *MonsterArtifact) { a.TagMajorVersion = 35 }},
		{"provenance", func(a *MonsterArtifact) {
			for i := range a.SourceFiles {
				if strings.HasSuffix(a.SourceFiles[i].Path, "/tag-version.h") {
					a.SourceFiles[i].SHA256 = strings.Repeat("0", 64)
					break
				}
			}
		}},
		{"order", func(a *MonsterArtifact) { a.Monsters[0], a.Monsters[1] = a.Monsters[1], a.Monsters[0] }},
		{"duplicate", func(a *MonsterArtifact) { a.Monsters[1] = a.Monsters[0] }},
		{"genus", func(a *MonsterArtifact) {
			for i := range a.Monsters {
				if a.Monsters[i].ID == "MONS_RAT" {
					a.Monsters[i].GenusID = "MONS_UNKNOWN"
					break
				}
			}
		}},
		{"species", func(a *MonsterArtifact) {
			for i := range a.Monsters {
				if a.Monsters[i].ID == "MONS_RAT" {
					a.Monsters[i].SpeciesID = "MONS_UNKNOWN"
					break
				}
			}
		}},
		{"unknown attack", func(a *MonsterArtifact) {
			for i := range a.Monsters {
				if a.Monsters[i].ID == "MONS_RAT" {
					a.Monsters[i].Attacks[1].TypeID = "AT_MADE_UP"
					break
				}
			}
		}},
		{"unknown spellbook", func(a *MonsterArtifact) {
			for i := range a.Monsters {
				if a.Monsters[i].ID == "MONS_RAT" {
					a.Monsters[i].SpellbookID = "MST_MADE_UP"
					break
				}
			}
		}},
		{"unknown flag", func(a *MonsterArtifact) {
			for i := range a.Monsters {
				if a.Monsters[i].ID == "MONS_RAT" {
					a.Monsters[i].Flags = append(a.Monsters[i].Flags, "M_MADE_UP")
					break
				}
			}
		}},
		{"same-count identity swap", func(a *MonsterArtifact) {
			for i := range a.Monsters {
				if a.Monsters[i].ID == "MONS_BUMBLEBEE" {
					a.Monsters[i].ID = "MONS_ZZZ_MADE_UP"
					break
				}
			}
			sort.Slice(a.Monsters, func(i, j int) bool { return a.Monsters[i].ID < a.Monsters[j].ID })
		}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			data := append([]byte(nil), defaultMonsterJSON...)
			var a MonsterArtifact
			if err := json.Unmarshal(data, &a); err != nil {
				t.Fatal(err)
			}
			tc.edit(&a)
			bad, _ := json.Marshal(a)
			if _, err := loadDefault(defaultSpeciesJSON, defaultJobsJSON, defaultItemsJSON, defaultItemIdentitiesJSON, defaultStartingGearJSON, defaultPresentationJSON, bad); err == nil {
				t.Fatal("bad monster artifact accepted")
			}
		})
	}
}
