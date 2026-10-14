package character

import (
	"fmt"

	"dcrawl-go/internal/content"
)

type Attributes struct {
	Strength     int
	Intelligence int
	Dexterity    int
}

// BaseStatSum adds table values for a legal fixed-stat normal Dungeon start.
// It does not apply later unfocusing or randomized Wanderer setup.
func BaseStatSum(c content.Catalog, speciesID, jobID string) (Attributes, error) {
	restriction, err := JobForSpecies(c, speciesID, jobID)

	if err != nil {
		return Attributes{}, err
	}

	if restriction == Banned {
		return Attributes{}, fmt.Errorf("banned character choice %s/%s", speciesID, jobID)
	}

	if jobID == "JOB_WANDERER" {
		return Attributes{}, fmt.Errorf("Wanderer needs randomized starting attributes")
	}

	species, _ := c.Species(speciesID)
	job, _ := c.Job(jobID)

	return Attributes{
		Strength:     species.Strength + job.Strength,
		Intelligence: species.Intelligence + job.Intelligence,
		Dexterity:    species.Dexterity + job.Dexterity,
	}, nil
}
