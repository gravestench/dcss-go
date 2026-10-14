package content

import (
	"reflect"
	"strings"
	"testing"
)

func testSpecies(id string) SpeciesDef {
	aptitudes := make(map[string]SpeciesAptitude)

	for _, skill := range strings.Fields(ordinarySkillIDs) {
		aptitudes[skill] = SpeciesAptitude{Allowed: true}
	}

	return SpeciesDef{
		ID:         id,
		MonsterID:  "MONS_HUMAN",
		SourcePath: "crawl-ref/source/dat/species/human.yaml",

		Name:       "Human",
		ShortName:  "Hu",
		Selectable: true,
		Difficulty: "Intermediate",

		XP: 1,
		MR: 3,

		Strength:             8,
		Intelligence:         8,
		Dexterity:            8,
		LevelUpStatFrequency: 4,
		LevelUpStats: []string{
			"str",
			"int",
			"dex",
		},
		Aptitudes: aptitudes,
		Mutations: []SpeciesMutation{
			{
				Level:  1,
				ID:     "MUT_FAST",
				Amount: 1,
			},
		},

		FakeMutations: []SpeciesFakeMutation{
			{
				Long:  "long",
				Short: "short",
			},
		},
		Flags:              []string{"SPF_NO_HAIR"},
		Habitat:            "HT_LAND",
		Size:               "SIZE_MEDIUM",
		UndeadType:         "US_ALIVE",
		RecommendedJobs:    []string{"JOB_FIGHTER"},
		RecommendedWeapons: []string{"SK_AXES"},
	}
}

func TestSpeciesCatalogDefensiveCopies(t *testing.T) {
	original := testSpecies("SP_HUMAN")
	catalog := Catalog{species: map[string]SpeciesDef{original.ID: original}}
	first, err := catalog.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	first.Aptitudes["SK_FIGHTING"] = SpeciesAptitude{Allowed: false}
	first.Mutations[0].Amount = 3
	first.FakeMutations[0].Long = "changed"

	first.Flags[0] = "changed"
	first.LevelUpStats[0] = "changed"
	first.RecommendedJobs[0] = "changed"
	first.RecommendedWeapons[0] = "changed"

	second, err := catalog.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(second, original) {
		t.Fatalf("catalog changed through returned species: %+v", second)
	}
}

func TestSpeciesCatalogRejectsDuplicateOrInvalidRecord(t *testing.T) {
	valid := testSpecies("SP_HUMAN")
	duplicate := SpeciesArtifact{
		SchemaVersion:   1,
		SourceRevision:  sourceRevision,
		TagMajorVersion: 34,
		Species:         []SpeciesDef{valid, valid},
	}

	if err := duplicate.Validate(); err == nil {
		t.Fatal("duplicate species ID accepted")
	}

	invalid := valid
	invalid.Name = ""
	artifact := SpeciesArtifact{
		SchemaVersion:   1,
		SourceRevision:  sourceRevision,
		TagMajorVersion: 34,
		Species:         []SpeciesDef{invalid},
	}

	if err := artifact.Validate(); err == nil {
		t.Fatal("species without name accepted")
	}

	if err := (Catalog{
		species:        map[string]SpeciesDef{"SP_HUMAN": invalid},
		version:        1,
		sourceRevision: sourceRevision,
		player: PlayerDef{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
			Speed:     10,
		},
	}).Validate(); err == nil {
		t.Fatal("invalid catalog species accepted")
	}
}

func TestSpeciesIDsSorted(t *testing.T) {
	catalog := Catalog{
		species: map[string]SpeciesDef{
			"SP_Z": testSpecies("SP_Z"),
			"SP_A": testSpecies("SP_A"),
		},
	}

	ids := catalog.SpeciesIDs()

	if !reflect.DeepEqual(ids, []string{"SP_A", "SP_Z"}) {
		t.Fatalf("species IDs not sorted: %v", ids)
	}

	ids[0] = "changed"

	if _, err := catalog.Species("SP_NOT_REAL"); err == nil {
		t.Fatal("unknown species ID accepted")
	}

	if _, err := catalog.Species("SP_A"); err != nil {
		t.Fatal("mutating ID list changed catalog:", err)
	}
}
