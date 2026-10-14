package content

import (
	"encoding/json"
	"slices"
	"strings"
	"testing"
)

func TestStartingGearCatalogCopies(t *testing.T) {
	c := scenarioCatalog()
	c.startingGear = map[string][]StartingGrant{
		"JOB_FIGHTER": {{
			Raw:      "scale mail",
			KindID:   "ARM_SCALE_MAIL",
			Quantity: 1,
		}},
	}

	first, err := c.StartingGrants("JOB_FIGHTER")

	if err != nil {
		t.Fatal(err)
	}

	first[0].KindID = "POT_CURING"
	first = append(first, StartingGrant{
		KindID:   "WPN_FLAIL",
		Quantity: 1,
	})

	again, err := c.StartingGrants("JOB_FIGHTER")

	if err != nil {
		t.Fatal(err)
	}

	if len(again) != 1 || again[0].KindID != "ARM_SCALE_MAIL" {
		t.Fatalf("catalog grants changed through returned slice: %+v", again)
	}

	if _, err := c.StartingGrants("JOB_UNKNOWN"); err == nil {
		t.Fatal("unknown job gear was accepted")
	}
}

func TestLoadDefaultStartingGear(t *testing.T) {
	catalog, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	if len(catalog.startingGear) != 25 {
		t.Fatalf("starting gear job count = %d, want 25", len(catalog.startingGear))
	}

	grants, err := catalog.StartingGrants("JOB_FIGHTER")

	if err != nil {
		t.Fatal(err)
	}

	if len(grants) != 3 || !slices.Equal(
		[]string{
			grants[0].Raw,
			grants[1].Raw,
			grants[2].Raw,
		},
		[]string{
			"scale mail",
			"buckler",
			"potion of might",
		},
	) ||
		!slices.Equal(
			[]string{
				grants[0].KindID,
				grants[1].KindID,
				grants[2].KindID,
			},
			[]string{
				"ARM_SCALE_MAIL",
				"ARM_BUCKLER",
				"POT_MIGHT",
			},
		) {
		t.Fatalf("Fighter grants differ from source: %+v", grants)
	}

	for id, want := range map[string]struct {
		class string
		slot  string
		skill string
	}{
		"POT_CURING": {
			class: "OBJ_POTIONS",
			slot:  "",
			skill: "",
		},
		"ARM_SCALE_MAIL": {
			class: "OBJ_ARMOUR",
			slot:  "body",
			skill: "",
		},
		"WPN_FLAIL": {
			class: "OBJ_WEAPONS",
			slot:  "weapon",
			skill: "SK_MACES_FLAILS",
		},
	} {
		kind, err := catalog.Item(id)

		if err != nil ||
			kind.Class != want.class ||
			kind.Slot != want.slot ||
			kind.WeaponSkill != want.skill {
			t.Fatalf("source-backed kind %s: %+v, %v", id, kind, err)
		}
	}

	grants[0].KindID = "POT_CURING"
	again, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	againGrants, err := again.StartingGrants("JOB_FIGHTER")

	if err != nil || againGrants[0].KindID != "ARM_SCALE_MAIL" {
		t.Fatalf("a fresh catalog inherited changed gear: %+v, %v", againGrants, err)
	}
}

func TestLoadDefaultRejectsBadStartingGear(t *testing.T) {
	for _, tc := range []struct {
		name   string
		mutate func(*StartingGearArtifact)
	}{
		{
			name: "wrong revision",
			mutate: func(a *StartingGearArtifact) {
				a.SourceRevision = "wrong"
			},
		},
		{
			name: "wrong tag",
			mutate: func(a *StartingGearArtifact) {
				a.TagMajorVersion = 35
			},
		},
		{
			name: "shared source hash",
			mutate: func(a *StartingGearArtifact) {
				for i := range a.SourceFiles {
					if a.SourceFiles[i].Path == "crawl-ref/source/job-data.h" {
						a.SourceFiles[i].SHA256 = strings.Repeat("f", 64)

						return
					}
				}
			},
		},
		{
			name: "duplicate job",
			mutate: func(a *StartingGearArtifact) {
				a.Jobs = append(a.Jobs, a.Jobs[0])
			},
		},
		{
			name: "missing job",
			mutate: func(a *StartingGearArtifact) {
				a.Jobs = a.Jobs[1:]
			},
		},
		{
			name: "changed raw spec",
			mutate: func(a *StartingGearArtifact) {
				for i := range a.Jobs {
					if a.Jobs[i].JobID == "JOB_FIGHTER" {
						a.Jobs[i].Grants[0].Raw = "robe"

						return
					}
				}
			},
		},
		{
			name: "changed grant order",
			mutate: func(a *StartingGearArtifact) {
				for i := range a.Jobs {
					if a.Jobs[i].JobID == "JOB_FIGHTER" {
						a.Jobs[i].Grants[0], a.Jobs[i].Grants[1] = a.Jobs[i].Grants[1], a.Jobs[i].Grants[0]

						return
					}
				}
			},
		},
		{
			name: "unknown kind",
			mutate: func(a *StartingGearArtifact) {
				for i := range a.Jobs {
					if a.Jobs[i].JobID == "JOB_FIGHTER" {
						a.Jobs[i].Grants[0].KindID = "ARM_UNKNOWN"

						return
					}
				}
			},
		},
		{
			name: "wrong valid kind",
			mutate: func(a *StartingGearArtifact) {
				for i := range a.Jobs {
					if a.Jobs[i].JobID == "JOB_FIGHTER" {
						a.Jobs[i].Grants[0].KindID = "ARM_BUCKLER"

						return
					}
				}
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var artifact StartingGearArtifact

			if err := json.Unmarshal(defaultStartingGearJSON, &artifact); err != nil {
				t.Fatal(err)
			}

			tc.mutate(&artifact)
			data, err := json.Marshal(artifact)

			if err != nil {
				t.Fatal(err)
			}

			if _, err := loadDefault(
				defaultSpeciesJSON,
				defaultJobsJSON,
				defaultItemsJSON,
				defaultItemIdentitiesJSON,
				data,
				defaultPresentationJSON,
				defaultMonsterJSON,
			); err == nil {
				t.Fatal("invalid starting gear artifact accepted")
			}
		})
	}

	if _, err := loadDefault(
		defaultSpeciesJSON,
		defaultJobsJSON,
		defaultItemsJSON,
		defaultItemIdentitiesJSON,
		[]byte(`{"jobs":`),
		defaultPresentationJSON,
		defaultMonsterJSON,
	); err == nil || !strings.Contains(
		err.Error(),
		"decode",
	) {
		t.Fatalf("malformed starting gear artifact: %v", err)
	}
}

func validStartingGearArtifact() StartingGearArtifact {
	return StartingGearArtifact{
		SchemaVersion:   2,
		SourceRevision:  sourceRevision,
		TagMajorVersion: 34,
		Jobs: []JobStartingGear{
			{
				JobID: "JOB_FIGHTER",
				Grants: []StartingGrant{
					{
						Raw:      "potion of curing",
						KindID:   "POT_CURING",
						Quantity: 1,
					},
				},
			},
		},
	}
}

func TestStartingGearArtifactValidation(t *testing.T) {
	catalog, err := LoadItemsForImport()

	if err != nil {
		t.Fatal(err)
	}

	if err := validStartingGearArtifact().Validate(catalog); err != nil {
		t.Fatalf("valid artifact: %v", err)
	}

	for _, tc := range []struct {
		name   string
		want   string
		change func(*StartingGearArtifact)
	}{
		{
			name: "duplicate job",
			want: "duplicate",
			change: func(a *StartingGearArtifact) {
				a.Jobs = append(a.Jobs, a.Jobs[0])
			},
		},
		{
			name: "unknown kind",
			want: "unknown",
			change: func(a *StartingGearArtifact) {
				a.Jobs[0].Grants[0].KindID = "POT_UNKNOWN"
			},
		},
		{
			name: "undefined legacy kind",
			want: "unknown",
			change: func(a *StartingGearArtifact) {
				a.Jobs[0].Grants[0].KindID = "POT_GAIN_STRENGTH"
			},
		},
		{
			name: "zero quantity",
			want: "quantity",
			change: func(a *StartingGearArtifact) {
				a.Jobs[0].Grants[0].Quantity = 0
			},
		},
		{
			name: "potion charges",
			want: "charges",
			change: func(a *StartingGearArtifact) {
				a.Jobs[0].Grants[0].Charges = 3
			},
		},
		{
			name: "potion ego",
			want: "ego",
			change: func(a *StartingGearArtifact) {
				a.Jobs[0].Grants[0].Ego = "poisoned"
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			a := validStartingGearArtifact()
			tc.change(&a)

			if err := a.Validate(catalog); err == nil || !strings.Contains(strings.ToLower(err.Error()), tc.want) {
				t.Fatalf("want %q error, got %v", tc.want, err)
			}
		})
	}
}
