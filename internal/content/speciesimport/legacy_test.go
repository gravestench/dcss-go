package speciesimport

import (
	"os"
	"strings"
	"testing"
)

func legacyFixtures(t *testing.T) ([]byte, []byte) {
	t.Helper()
	species, err := os.ReadFile("testdata/legacy-species.txt")

	if err != nil {
		t.Fatal(err)
	}

	aptitudes, err := os.ReadFile("testdata/legacy-aptitudes.txt")

	if err != nil {
		t.Fatal(err)
	}

	return species, aptitudes
}

func TestParseLegacyThreeSpecies(t *testing.T) {
	source, aptitudes := legacyFixtures(t)
	records, err := parseLegacy(
		"crawl-ref/source/util/species-gen/species-data-deprecated-species.txt",
		source,
		"crawl-ref/source/util/species-gen/aptitudes-deprecated-species.txt",
		aptitudes,
	)

	if err != nil {
		t.Fatal(err)
	}

	if len(records) != 3 {
		t.Fatalf("want three legacy species, got %d", len(records))
	}

	byID := map[string]int{}

	for i, record := range records {
		byID[record.ID] = i

		if record.Selectable || record.SourcePath == "" {
			t.Fatalf("legacy record selectable or untraced: %+v", record)
		}
	}

	checks := []struct {
		id           string
		monster      string
		strength     int
		intelligence int
		dexterity    int
	}{
		{
			id:           "SP_HIGH_ELF",
			monster:      "MONS_ELF",
			strength:     7,
			intelligence: 11,
			dexterity:    10,
		},

		{
			id:           "SP_LAVA_ORC",
			monster:      "MONS_LAVA_ORC",
			strength:     10,
			intelligence: 8,
			dexterity:    6,
		},

		{
			id:           "SP_SLUDGE_ELF",
			monster:      "MONS_ELF",
			strength:     8,
			intelligence: 8,
			dexterity:    8,
		},
	}

	for _, check := range checks {
		i, found := byID[check.id]

		if !found {
			t.Fatalf("missing %s", check.id)
		}

		s := records[i]

		if s.MonsterID != check.monster ||
			s.Strength != check.strength ||
			s.Intelligence != check.intelligence || s.Dexterity != check.dexterity {
			t.Fatalf("wrong legacy fields for %s: %+v", check.id, s)
		}
	}

	if records[byID["SP_HIGH_ELF"]].Aptitudes["SK_SLINGS"].Allowed {
		t.Fatal("legacy UNUSABLE_SKILL was made usable")
	}

	got := records[byID["SP_LAVA_ORC"]].Aptitudes["SK_ICE_MAGIC"]

	if !got.Allowed ||
		got.Value != -4 {
		t.Fatalf("legacy numeric aptitude lost: %+v", got)
	}
}

func TestParseLegacyRejectsBadRows(t *testing.T) {
	source, aptitudes := legacyFixtures(t)
	cases := []struct {
		name      string
		source    []byte
		aptitudes []byte
		want      string
	}{
		{
			name:      "duplicate species",
			source:    []byte(strings.Replace(string(source), "SP_HIGH_ELF", "SP_SLUDGE_ELF", 1)),
			aptitudes: aptitudes,
			want:      "SP_SLUDGE_ELF",
		},

		{
			name:      "bad aptitude",
			source:    source,
			aptitudes: []byte(strings.Replace(string(aptitudes), "SK_FIGHTING,        0", "SK_FIGHTING,        bogus", 1)),
			want:      "SK_FIGHTING",
		},

		{
			name:      "unsupported conditional",
			source:    []byte(strings.Replace(string(source), "TAG_MAJOR_VERSION == 34", "FEATURE_X", 1)),
			aptitudes: aptitudes,
			want:      "FEATURE_X",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := parseLegacy("legacy-species.txt", tc.source, "legacy-aptitudes.txt", tc.aptitudes)

			if err == nil ||
				!strings.Contains(err.Error(), tc.want) {
				t.Fatalf("want error containing %q, got %v", tc.want, err)
			}
		})
	}

	var retained []string

	for _, line := range strings.Split(string(aptitudes), "\n") {
		if !strings.Contains(line, "SP_LAVA_ORC") {
			retained = append(retained, line)
		}
	}

	if _, err := parseLegacy(
		"legacy-species.txt",
		source,
		"legacy-aptitudes.txt",
		[]byte(strings.Join(
			retained,
			"\n",
		)),
	); err == nil ||
		!strings.Contains(
			err.Error(),
			"SP_LAVA_ORC",
		) {
		t.Fatalf("missing legacy aptitudes accepted: %v", err)
	}
}
