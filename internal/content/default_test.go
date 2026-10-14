package content

import (
	"encoding/json"
	"os"
	"strings"
	"testing"
)

func TestLoadDefaultSpeciesAndFixture(t *testing.T) {
	catalog, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	if err := catalog.Validate(); err != nil {
		t.Fatal(err)
	}

	if got := len(catalog.SpeciesIDs()); got != 43 {
		t.Fatalf("species count = %d, want 43", got)
	}

	if catalog.Version() != 1 || catalog.SourceRevision() != sourceRevision {
		t.Fatalf("wrong catalog provenance: %d %s", catalog.Version(), catalog.SourceRevision())
	}

	human, err := catalog.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	if !human.Selectable ||
		human.Aptitudes["SK_FIGHTING"] != (SpeciesAptitude{Allowed: true}) {
		t.Fatalf("Human defaults lost: %+v", human)
	}

	deepElf, err := catalog.Species("SP_DEEP_ELF")

	if err != nil {
		t.Fatal(err)
	}

	if deepElf.Aptitudes["SK_SPELLCASTING"].Value != 3 {
		t.Fatalf("Deep Elf spellcasting lost: %+v", deepElf.Aptitudes["SK_SPELLCASTING"])
	}

	felid, err := catalog.Species("SP_FELID")

	if err != nil {
		t.Fatal(err)
	}

	if felid.Aptitudes["SK_SHORT_BLADES"].Allowed || len(felid.Mutations) == 0 {
		t.Fatalf("Felid unusable skill or mutations lost: %+v", felid)
	}

	highElf, err := catalog.Species("SP_HIGH_ELF")

	if err != nil {
		t.Fatal(err)
	}

	if highElf.Selectable ||
		highElf.SourcePath != "crawl-ref/source/util/species-gen/species-data-deprecated-species.txt" {
		t.Fatalf("tag-34 legacy species lost: %+v", highElf)
	}

	rat, err := catalog.Monster("MONS_RAT")

	if err != nil {
		t.Fatal(err)
	}

	if rat.Glyph != 'r' ||
		rat.Speed != 10 ||
		rat.Attacks[0].Damage != 3 ||
		rat.AverageHP10x != 25 {
		t.Fatalf("scenario rat changed: %+v", rat)
	}

	if player := catalog.Player(); player.SpeciesID != "SP_HUMAN" ||
		player.JobID != "JOB_FIGHTER" ||
		player.Speed != 10 {
		t.Fatalf("scenario player changed: %+v", player)
	}

	if _, err := catalog.Item("POT_CURING"); err != nil {
		t.Fatal(err)
	}
}

func TestLoadDefaultReturnsFreshCatalogs(t *testing.T) {
	first, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	human, err := first.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	human.Aptitudes["SK_FIGHTING"] = SpeciesAptitude{Allowed: false}
	second, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	again, err := second.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	if again.Aptitudes["SK_FIGHTING"] != (SpeciesAptitude{Allowed: true}) {
		t.Fatal("new catalog inherited mutation through returned record")
	}
}

func TestLoadDefaultRejectsBadArtifact(t *testing.T) {
	data, err := os.ReadFile("generated/species.json")

	if err != nil {
		t.Fatal(err)
	}

	var original SpeciesArtifact

	if err := json.Unmarshal(data, &original); err != nil {
		t.Fatal(err)
	}

	cases := []struct {
		name   string
		mutate func(*SpeciesArtifact)
	}{
		{
			name: "schema",
			mutate: func(a *SpeciesArtifact) {
				a.SchemaVersion = 2
			},
		},

		{
			name: "revision",
			mutate: func(a *SpeciesArtifact) {
				a.SourceRevision = "wrong"
			},
		},

		{
			name: "tag",
			mutate: func(a *SpeciesArtifact) {
				a.TagMajorVersion = 35
			},
		},

		{
			name: "duplicate",
			mutate: func(a *SpeciesArtifact) {
				a.Species = append(a.Species, a.Species[0])
			},
		},

		{
			name: "missing player species",
			mutate: func(a *SpeciesArtifact) {
				for i, s := range a.Species {
					if s.ID == "SP_HUMAN" {
						a.Species = append(a.Species[:i], a.Species[i+1:]...)
						break
					}
				}
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			artifact := original

			artifact.Species = append([]SpeciesDef(nil), original.Species...)
			tc.mutate(&artifact)
			encoded, err := json.Marshal(artifact)

			if err != nil {
				t.Fatal(err)
			}

			if _, err := loadDefault(
				encoded,
				defaultJobsJSON,
				defaultItemsJSON,
				defaultItemIdentitiesJSON,
				defaultStartingGearJSON,
				defaultPresentationJSON,
				defaultMonsterJSON,
			); err == nil {
				t.Fatal("bad embedded artifact accepted")
			}
		})
	}

	if _, err := loadDefault(
		[]byte(`{"species":`),
		defaultJobsJSON,
		defaultItemsJSON,
		defaultItemIdentitiesJSON,
		defaultStartingGearJSON,
		defaultPresentationJSON,
		defaultMonsterJSON,
	); err == nil ||
		!strings.Contains(
			err.Error(),
			"decode",
		) {
		t.Fatalf("malformed artifact error = %v", err)
	}
}

func TestLoadDefaultRejectsMissingAptitudes(t *testing.T) {
	data, err := os.ReadFile("generated/species.json")

	if err != nil {
		t.Fatal(err)
	}

	for _, missing := range []string{"all", "SK_FIGHTING"} {
		t.Run(missing, func(t *testing.T) {
			var artifact SpeciesArtifact

			if err := json.Unmarshal(data, &artifact); err != nil {
				t.Fatal(err)
			}

			for i := range artifact.Species {
				if artifact.Species[i].ID == "SP_HUMAN" {
					if missing == "all" {
						artifact.Species[i].Aptitudes = nil
					} else {
						delete(artifact.Species[i].Aptitudes, missing)
					}

					break
				}
			}

			encoded, err := json.Marshal(artifact)

			if err != nil {
				t.Fatal(err)
			}

			if _, err := loadDefault(
				encoded,
				defaultJobsJSON,
				defaultItemsJSON,
				defaultItemIdentitiesJSON,
				defaultStartingGearJSON,
				defaultPresentationJSON,
				defaultMonsterJSON,
			); err == nil ||
				!strings.Contains(
					err.Error(),
					"aptitude",
				) {
				t.Fatalf("missing %s aptitudes accepted: %v", missing, err)
			}
		})
	}
}
