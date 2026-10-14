package monsterimport

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func fixtureSource(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	files := map[string]string{
		"tag-version.h": "#define TAG_MAJOR_VERSION 34\n",
		"monster-type.h": "enum monster_type {\n MONS_PROGRAM_BUG, MONS_0 = MONS_PROGRAM_BUG, " +
			"MONS_BUMBLEBEE, MONS_RAT, MONS_BEAR, NUM_MONSTERS, MONS_NO_MONSTER = 1000, " +
			"RANDOM_MONSTER = 2000,\n#if TAG_MAJOR_VERSION > 34\n MONS_FUTURE,\n#endif\n};\n",
		"mon-data.h": "static monsterentry mondata[] = {\nAXED_MON(MONS_BUMBLEBEE, \"bee\")\n" + row(
			"MONS_RAT",
			`"rat"`,
		) + "};\n",
		"mon-util.h": "enum mon_type_tile_variation { TVARY_NONE, TVARY_MOD, };\n",
		"mon-enum.h": "enum attack_type { AT_NONE, AT_BITE, };\nenum attack_flavour { AF_PLAIN, };\n" +
			"enum mon_intel_type { I_ANIMAL, };\nenum habitat_type { HT_LAND, };\nenum " +
			"mon_itemuse_type { MONUSE_NOTHING, };\nenum shout_type { S_SILENT, };\nenum " +
			"mon_resist_flags { MR_NO_FLAGS, MR_RES_FIRE, MR_RES_COLD, MR_RES_POISON, " +
			"MR_VUL_POISON, };\nenum mon_body_shape { MON_SHAPE_QUADRUPED, };\n",
		"mon-flags.h":     "enum monclass_flag_type : uint64_t { M_NO_FLAGS, M_WARM_BLOOD, M_NO_EXP_GAIN, M_NO_THREAT, };\n",
		"mon-holy-type.h": "enum mon_holy_type_flags { MH_NATURAL, };\n",
		"size-type.h":     "enum size_type { SIZE_TINY, };\n",
		"mon-mst.h":       "enum mon_spellbook_type { MST_NO_SPELLS, };\n",
		"defines.h":       "enum COLOURS { BROWN, };\nconst int WILL_INVULN = 5000;\n",
		"colour.h":        "enum element_type { ETC_TREE, };\n",
	}
	for name, data := range files {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(data), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return dir
}

func TestGenerateFixtureDeterministicPartition(t *testing.T) {
	dir := fixtureSource(t)
	first, err := generateFromSource(dir, pinnedRevision)
	if err != nil {
		t.Fatal(err)
	}
	second, err := generateFromSource(dir, pinnedRevision)
	if err != nil || !bytes.Equal(first, second) {
		t.Fatalf("nondeterministic generation: %v", err)
	}
	var artifact content.MonsterArtifact
	if err := json.Unmarshal(first, &artifact); err != nil {
		t.Fatal(err)
	}
	if len(artifact.Monsters) != 4 || artifact.Monsters[0].ID != "MONS_BEAR" ||
		artifact.Monsters[0].Status != content.MonsterEnumOnly ||
		artifact.Monsters[1].Status != content.MonsterRemoved || artifact.Monsters[3].ID != "MONS_RAT" {
		t.Fatalf("incorrect partition: %+v", artifact.Monsters)
	}
	if len(artifact.SourceFiles) != 11 || artifact.SourceFiles[0].SHA256 == "" || !bytes.HasSuffix(first, []byte("\n")) {
		t.Fatalf("bad provenance: %+v", artifact.SourceFiles)
	}
	var raw struct {
		Monsters []map[string]json.RawMessage `json:"monsters"`
	}
	if err := json.Unmarshal(first, &raw); err != nil {
		t.Fatal(err)
	}
	for _, entry := range raw.Monsters {
		var status string
		_ = json.Unmarshal(entry["status"], &status)
		if status != "defined" {
			for _, field := range []string{"attacks", "energy", "tile"} {
				if _, exists := entry[field]; exists {
					t.Fatalf("non-live record carries %s: %s", field, entry["id"])
				}
			}
		}
	}
}

func TestGenerateRejectsBadSource(t *testing.T) {
	dir := fixtureSource(t)
	if _, err := generateFromSource(dir, "wrong"); err == nil {
		t.Fatal("wrong revision accepted")
	}
	for _, tc := range []struct {
		name, file, old, next string
	}{
		{
			name: "tag",
			file: "tag-version.h",
			old:  "34",
			next: "35",
		},
		{
			name: "missing",
			file: "mon-data.h",
			old:  "MONS_RAT,",
			next: "MONS_MISSING,",
		},
		{
			name: "duplicate",
			file: "mon-data.h",
			old:  "};\n",
			next: row("MONS_RAT", `"rat"`) + "};\n",
		},
		{
			name: "unknown reference",
			file: "mon-data.h",
			old:  "MONS_RAT, MONS_RAT, MH_NATURAL",
			next: "MONS_RAT, MONS_UNKNOWN, MH_NATURAL",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			copyDir := fixtureSource(t)
			path := filepath.Join(copyDir, tc.file)
			data, _ := os.ReadFile(path)
			if err := os.WriteFile(path, []byte(strings.Replace(string(data), tc.old, tc.next, 1)), 0o644); err != nil {
				t.Fatal(err)
			}
			if _, err := generateFromSource(copyDir, pinnedRevision); err == nil {
				t.Fatal("bad source accepted")
			}
		})
	}
}

func TestWritePreservesArtifactOnFailure(t *testing.T) {
	dir := fixtureSource(t)
	out := filepath.Join(t.TempDir(), "monsters.json")
	if err := os.WriteFile(out, []byte("old"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := writeArtifact(dir, out, false, func(string) ([]byte, error) { return nil, os.ErrInvalid }); err == nil {
		t.Fatal("generation failure accepted")
	}
	data, _ := os.ReadFile(out)
	if string(data) != "old" {
		t.Fatalf("artifact overwritten: %q", data)
	}
	if err := writeArtifact(dir, out, true, func(string) ([]byte, error) { return []byte("new"), nil }); err == nil {
		t.Fatal("stale check accepted")
	}
	data, _ = os.ReadFile(out)
	if string(data) != "old" {
		t.Fatalf("check wrote artifact: %q", data)
	}
}
