// Package character holds pure character creation rules over imported content.
package character

import (
	"dcrawl-go/internal/content"
)

type Restriction uint8

const (
	Banned Restriction = iota
	Restricted
	Recommended
)

func hasMutation(species content.SpeciesDef, id string) bool {
	for _, mutation := range species.Mutations {
		if mutation.ID == id && mutation.Amount > 0 {
			return true
		}
	}
	return false
}

func bannedPair(species content.SpeciesDef, jobID string) bool {
	if hasMutation(species, "MUT_NO_GRASPING") {
		switch jobID {
		case "JOB_GLADIATOR", "JOB_BRIGAND", "JOB_HUNTER", "JOB_ARCANE_MARKSMAN":
			return true
		}
	}
	if hasMutation(species, "MUT_FORLORN") {
		switch jobID {
		case "JOB_BERSERKER", "JOB_CHAOS_KNIGHT", "JOB_ABYSSAL_KNIGHT", "JOB_CINDER_ACOLYTE", "JOB_MONK":
			return true
		}
	}
	return jobID == "JOB_TRANSMUTER" && species.UndeadType == "US_UNDEAD"
}

func contains(ids []string, id string) bool {
	for _, candidate := range ids {
		if candidate == id {
			return true
		}
	}
	return false
}

func choice(c content.Catalog, speciesID, jobID string, speciesFirst bool) (Restriction, error) {
	species, err := c.Species(speciesID)
	if err != nil {
		return Banned, err
	}
	job, err := c.Job(jobID)
	if err != nil {
		return Banned, err
	}
	if !species.Selectable || !job.Selectable || bannedPair(species, jobID) {
		return Banned, nil
	}
	recommendedBySpecies := contains(species.RecommendedJobs, jobID)
	recommendedByJob := contains(job.RecommendedSpecies, speciesID)
	if speciesFirst && recommendedBySpecies ||
		!speciesFirst && recommendedByJob {
		return Recommended, nil
	}
	return Restricted, nil
}

// JobForSpecies returns the species-first menu restriction for a normal Dungeon start.
func JobForSpecies(c content.Catalog, speciesID, jobID string) (Restriction, error) {
	return choice(c, speciesID, jobID, true)
}

// SpeciesForJob returns the job-first menu restriction for a normal Dungeon start.
func SpeciesForJob(c content.Catalog, speciesID, jobID string) (Restriction, error) {
	return choice(c, speciesID, jobID, false)
}
