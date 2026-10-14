package speciesimport

import (
	"strings"
	"testing"
)

const humanYAML = `enum: SP_HUMAN
monster: MONS_HUMAN
name: Human
difficulty: Intermediate
aptitudes:
  xp: 1
  hp: 0
  mp_mod: 0
  mr: 3
  spellcasting: 3
str: 8
int: 8
dex: 8
levelup_stat_frequency: 4
recommended_jobs:
  - JOB_FIGHTER
`

func TestParseYAMLHumanDefaults(t *testing.T) {
	s, tag, err := parseYAML("crawl-ref/source/dat/species/human.yaml", []byte(humanYAML))

	if err != nil {
		t.Fatal(err)
	}

	if tag != 0 ||
		s.ID != "SP_HUMAN" ||
		s.ShortName != "Hu" ||
		!s.Selectable ||
		s.XP != 1 ||
		s.MR != 3 {
		t.Fatalf("wrong Human identity/defaults: %+v, tag %d", s, tag)
	}

	if a := s.Aptitudes["SK_FIGHTING"]; !a.Allowed || a.Value != 0 {
		t.Fatalf("omitted fighting aptitude is not allowed zero: %+v", a)
	}

	if a := s.Aptitudes["SK_SPELLCASTING"]; !a.Allowed || a.Value != 3 {
		t.Fatalf("explicit spellcasting aptitude lost: %+v", a)
	}

	if s.Habitat != "HT_LAND" ||
		s.UndeadType != "US_ALIVE" ||
		s.Size != "SIZE_MEDIUM" ||
		len(s.LevelUpStats) != 3 {
		t.Fatalf("wrong environment/stat defaults: %+v", s)
	}
}

func TestParseYAMLDeepElfSpellcasting(t *testing.T) {
	input := strings.ReplaceAll(humanYAML, "SP_HUMAN", "SP_DEEP_ELF")
	input = strings.ReplaceAll(input, "MONS_HUMAN", "MONS_ELF")
	input = strings.ReplaceAll(input, "name: Human", "name: Deep Elf")

	input += "short_name: DE\n"
	s, _, err := parseYAML("crawl-ref/source/dat/species/deep-elf.yaml", []byte(input))

	if err != nil {
		t.Fatal(err)
	}

	if s.ID != "SP_DEEP_ELF" || s.ShortName != "DE" || s.Aptitudes["SK_SPELLCASTING"].Value != 3 {
		t.Fatalf("Deep Elf identity or spellcasting lost: %+v", s)
	}
}

func TestParseYAMLFelidUnusableAndMutations(t *testing.T) {
	input := strings.ReplaceAll(humanYAML, "SP_HUMAN", "SP_FELID")
	input = strings.ReplaceAll(input, "MONS_HUMAN", "MONS_FELID")
	input = strings.ReplaceAll(input, "name: Human", "name: Felid")

	input = strings.Replace(input, "  spellcasting: 3\n", "  spellcasting: 3\n  short_blades: False\n", 1)
	input += "mutations:\n  1:\n    MUT_CLAWS: 1\n  6:\n    MUT_CLAWS: 1\n"

	s, _, err := parseYAML("crawl-ref/source/dat/species/felid.yaml", []byte(input))

	if err != nil {
		t.Fatal(err)
	}

	if a := s.Aptitudes["SK_SHORT_BLADES"]; a.Allowed || a.Value != 0 {
		t.Fatalf("False aptitude became usable: %+v", a)
	}

	if len(s.Mutations) != 2 || s.Mutations[0].Level != 1 || s.Mutations[1].Level != 6 {
		t.Fatalf("nested mutation levels lost: %+v", s.Mutations)
	}
}

func TestParseYAMLTag34AndOptionalFields(t *testing.T) {
	input := "TAG_MAJOR_VERSION: 34\n" + humanYAML + `short_name: Hm
adjective: Humanlike
genus: Human
species_flags:
  - SPF_NO_HAIR
can_swim: true
undead_type: US_SEMI_UNDEAD
size: small
levelup_stats:
  - int
fake_mutations:
  - long: A long description.
    short: short description
recommended_weapons:
  - SK_AXES
walking_verb: slither
altar_action: kneel at
`
	s, tag, err := parseYAML("crawl-ref/source/dat/species/tagged.yaml", []byte(input))

	if err != nil {
		t.Fatal(err)
	}

	if tag != 34 ||
		s.ShortName != "Hm" ||
		s.Habitat != "HT_WATER" ||
		s.UndeadType != "US_SEMI_UNDEAD" || s.Size != "SIZE_SMALL" {
		t.Fatalf("tag/optional fields lost: %+v tag %d", s, tag)
	}

	if len(s.Flags) != 1 ||
		s.Flags[0] != "SPF_NO_HAIR" ||
		len(s.LevelUpStats) != 1 ||
		s.LevelUpStats[0] != "int" || len(s.FakeMutations) != 1 ||
		s.FakeMutations[0].Short != "short description" || len(s.RecommendedWeapons) != 1 || s.AltarAction != "kneel at" {
		t.Fatalf("optional details lost: %+v", s)
	}
}

func TestParseYAMLRejectsMalformedSource(t *testing.T) {
	cases := []struct {
		name  string
		input string
		field string
	}{
		{
			name:  "unknown field",
			input: humanYAML + "unknown_field: yes\n",
			field: "unknown_field",
		},
		{
			name:  "duplicate key",
			input: humanYAML + "name: Duplicate\n",
			field: "name",
		},
		{
			name:  "bad aptitude",
			input: strings.Replace(humanYAML, "spellcasting: 3", "spellcasting: many", 1),
			field: "spellcasting",
		},
		{
			name:  "bad stat",
			input: strings.Replace(humanYAML, "str: 8", "str: 0", 1),
			field: "str",
		},
		{
			name:  "bad mutation level",
			input: humanYAML + "mutations:\n  28:\n    MUT_CLAWS: 1\n",
			field: "mutations",
		},
		{
			name:  "bad mutation amount",
			input: humanYAML + "mutations:\n  1:\n    MUT_CLAWS: 4\n",
			field: "MUT_CLAWS",
		},
		{
			name:  "bad difficulty",
			input: strings.Replace(humanYAML, "Intermediate", "Impossible", 1),
			field: "difficulty",
		},
		{
			name:  "bad flag",
			input: humanYAML + "species_flags:\n  - SPF_UNKNOWN\n",
			field: "SPF_UNKNOWN",
		},
		{
			name:  "bad skill",
			input: strings.Replace(humanYAML, "spellcasting: 3", "speling: 3", 1),
			field: "speling",
		},
		{
			name:  "missing jobs",
			input: strings.Replace(humanYAML, "recommended_jobs:\n  - JOB_FIGHTER\n", "", 1),
			field: "recommended_jobs",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, _, err := parseYAML("bad.yaml", []byte(tc.input))

			if err == nil || !strings.Contains(err.Error(), "bad.yaml") || !strings.Contains(err.Error(), tc.field) {
				t.Fatalf("want file/field error containing %q, got %v", tc.field, err)
			}
		})
	}
}

func TestParseYAMLRejectsCoercionAndTrailingDocument(t *testing.T) {
	cases := []struct {
		name  string
		input string
		field string
	}{
		{
			name:  "fractional strength",
			input: strings.Replace(humanYAML, "str: 8", "str: 8.9", 1),
			field: "str",
		},
		{
			name:  "numeric name",
			input: strings.Replace(humanYAML, "name: Human", "name: 123", 1),
			field: "name",
		},
		{
			name:  "null frequency",
			input: strings.Replace(humanYAML, "levelup_stat_frequency: 4", "levelup_stat_frequency: null", 1),
			field: "levelup_stat_frequency",
		},
		{
			name:  "second document",
			input: humanYAML + "---\nunknown_field: yes\n",
			field: "document",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, _, err := parseYAML("strict.yaml", []byte(tc.input))

			if err == nil || !strings.Contains(err.Error(), "strict.yaml") || !strings.Contains(err.Error(), tc.field) {
				t.Fatalf("want contextual rejection of %s, got %v", tc.field, err)
			}
		})
	}
}
