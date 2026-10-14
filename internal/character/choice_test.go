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

	var speciesCount int
	var jobCount int
	var legal int
	var banned int

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

	if speciesCount != 27 ||
		jobCount != 25 ||
		legal != 664 ||
		banned != 11 {
		t.Fatalf("matrix: species=%d jobs=%d legal=%d banned=%d", speciesCount, jobCount, legal, banned)
	}
}

func TestDirectionalRecommendationsAndBans(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	cases := []struct {
		species string
		job     string
		forward Restriction
		reverse Restriction
	}{
		{
			species: "SP_HUMAN",
			job:     "JOB_FIGHTER",
			forward: Restricted,
			reverse: Restricted,
		},
		{
			species: "SP_BARACHI",
			job:     "JOB_ARCANE_MARKSMAN",
			forward: Recommended,
			reverse: Restricted,
		},
		{
			species: "SP_FELID",
			job:     "JOB_GLADIATOR",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_FELID",
			job:     "JOB_BRIGAND",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_FELID",
			job:     "JOB_HUNTER",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_FELID",
			job:     "JOB_ARCANE_MARKSMAN",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_DEMIGOD",
			job:     "JOB_BERSERKER",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_DEMIGOD",
			job:     "JOB_CHAOS_KNIGHT",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_DEMIGOD",
			job:     "JOB_ABYSSAL_KNIGHT",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_DEMIGOD",
			job:     "JOB_CINDER_ACOLYTE",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_DEMIGOD",
			job:     "JOB_MONK",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_GHOUL",
			job:     "JOB_TRANSMUTER",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_MUMMY",
			job:     "JOB_TRANSMUTER",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_HUMAN",
			job:     "JOB_HEALER",
			forward: Banned,
			reverse: Banned,
		},
		{
			species: "SP_HIGH_ELF",
			job:     "JOB_FIGHTER",
			forward: Banned,
			reverse: Banned,
		},
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
	species := content.SpeciesDef{
		Mutations: []content.SpeciesMutation{
			{
				Level:  9,
				ID:     "MUT_NO_GRASPING",
				Amount: 1,
			},
		},
	}

	if !bannedPair(species, "JOB_HUNTER") || bannedPair(species, "JOB_FIGHTER") {
		t.Fatal("future no-grasping mutation should ban Hunter only")
	}

	species.Mutations = []content.SpeciesMutation{
		{
			Level:  12,
			ID:     "MUT_FORLORN",
			Amount: 1,
		},
	}

	if !bannedPair(species, "JOB_MONK") || bannedPair(species, "JOB_FIGHTER") {
		t.Fatal("future forlorn mutation should ban Monk only")
	}
}
