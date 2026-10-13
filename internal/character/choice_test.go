package character

import (
	"testing"

	"dcrawl-go/internal/content"
)

func TestNormalDungeonChoiceMatrix(t *testing.T) {
	catalog, err := content.LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	var speciesCount, jobCount, legal, banned int
	for _, speciesID := range catalog.SpeciesIDs() {
		species, _ := catalog.Species(speciesID)
		if !species.Selectable {
			continue
		}
		speciesCount++
		for _, jobID := range catalog.JobIDs() {
			job, _ := catalog.Job(jobID)
			if !job.Selectable {
				continue
			}
			forward, err := JobForSpecies(catalog, speciesID, jobID)
			if err != nil {
				t.Fatal(err)
			}
			reverse, err := SpeciesForJob(catalog, speciesID, jobID)
			if err != nil {
				t.Fatal(err)
			}
			if (forward == Banned) != (reverse == Banned) {
				t.Fatalf("directions disagree on ban: %s/%s", speciesID, jobID)
			}
			if forward == Banned {
				banned++
			} else {
				legal++
			}
		}
	}
	for _, jobID := range catalog.JobIDs() {
		job, _ := catalog.Job(jobID)
		if job.Selectable {
			jobCount++
		}
	}
	if speciesCount != 27 || jobCount != 25 || legal != 664 || banned != 11 {
		t.Fatalf("matrix: species=%d jobs=%d legal=%d banned=%d", speciesCount, jobCount, legal, banned)
	}
}

func TestDirectionalRecommendationsAndBans(t *testing.T) {
	catalog, err := content.LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		species, job     string
		forward, reverse Restriction
	}{
		{"SP_HUMAN", "JOB_FIGHTER", Restricted, Restricted},
		{"SP_BARACHI", "JOB_ARCANE_MARKSMAN", Recommended, Restricted},
		{"SP_FELID", "JOB_GLADIATOR", Banned, Banned},
		{"SP_FELID", "JOB_BRIGAND", Banned, Banned},
		{"SP_FELID", "JOB_HUNTER", Banned, Banned},
		{"SP_FELID", "JOB_ARCANE_MARKSMAN", Banned, Banned},
		{"SP_DEMIGOD", "JOB_BERSERKER", Banned, Banned},
		{"SP_DEMIGOD", "JOB_CHAOS_KNIGHT", Banned, Banned},
		{"SP_DEMIGOD", "JOB_ABYSSAL_KNIGHT", Banned, Banned},
		{"SP_DEMIGOD", "JOB_CINDER_ACOLYTE", Banned, Banned},
		{"SP_DEMIGOD", "JOB_MONK", Banned, Banned},
		{"SP_GHOUL", "JOB_TRANSMUTER", Banned, Banned},
		{"SP_MUMMY", "JOB_TRANSMUTER", Banned, Banned},
		{"SP_HUMAN", "JOB_HEALER", Banned, Banned},
		{"SP_HIGH_ELF", "JOB_FIGHTER", Banned, Banned},
	}
	for _, tc := range cases {
		t.Run(tc.species+"/"+tc.job, func(t *testing.T) {
			forward, err := JobForSpecies(catalog, tc.species, tc.job)
			if err != nil || forward != tc.forward {
				t.Fatalf("species-first = %v, %v; want %v", forward, err, tc.forward)
			}
			reverse, err := SpeciesForJob(catalog, tc.species, tc.job)
			if err != nil || reverse != tc.reverse {
				t.Fatalf("job-first = %v, %v; want %v", reverse, err, tc.reverse)
			}
		})
	}
	if _, err := JobForSpecies(catalog, "SP_MISSING", "JOB_FIGHTER"); err == nil {
		t.Fatal("unknown species accepted")
	}
	if _, err := SpeciesForJob(catalog, "SP_HUMAN", "JOB_MISSING"); err == nil {
		t.Fatal("unknown job accepted")
	}
}

func TestBannedPairChecksFutureMutation(t *testing.T) {
	species := content.SpeciesDef{Mutations: []content.SpeciesMutation{{Level: 9, ID: "MUT_NO_GRASPING", Amount: 1}}}
	if !bannedPair(species, "JOB_HUNTER") || bannedPair(species, "JOB_FIGHTER") {
		t.Fatal("future no-grasping mutation should ban Hunter only")
	}
	species.Mutations = []content.SpeciesMutation{{Level: 12, ID: "MUT_FORLORN", Amount: 1}}
	if !bannedPair(species, "JOB_MONK") || bannedPair(species, "JOB_FIGHTER") {
		t.Fatal("future forlorn mutation should ban Monk only")
	}
}
