package script

import (
	"fmt"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

// ChoiceKey identifies one direction of the character creation menu.
type ChoiceKey struct {
	SpeciesID    string
	JobID        string
	SpeciesFirst bool
}

// ProjectCharacterCatalog loads effective Lua character definitions and menu
// policy for the pregame UI. Gameplay creates its own session VM later.
func ProjectCharacterCatalog(
	base content.Catalog,
	rules modfs.Ruleset,
) (content.Catalog, map[ChoiceKey]Choice, error) {
	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		return content.Catalog{}, nil, err
	}

	defer runtime.Close()

	catalog, err := base.WithCharacterDefinitions(
		runtime.SpeciesDefinitions(),
		runtime.JobDefinitions(),
	)

	if err != nil {
		return content.Catalog{}, nil, err
	}

	choices := make(map[ChoiceKey]Choice)

	for _, speciesID := range catalog.SpeciesIDs() {
		for _, jobID := range catalog.JobIDs() {
			for _, speciesFirst := range []bool{false, true} {
				choice, err := runtime.CharacterChoice(
					speciesID, jobID, speciesFirst,
				)

				if err != nil {
					return content.Catalog{}, nil, err
				}

				choices[ChoiceKey{
					SpeciesID:    speciesID,
					JobID:        jobID,
					SpeciesFirst: speciesFirst,
				}] = choice
			}

			forward := choices[ChoiceKey{
				SpeciesID:    speciesID,
				JobID:        jobID,
				SpeciesFirst: true,
			}]

			reverse := choices[ChoiceKey{
				SpeciesID:    speciesID,
				JobID:        jobID,
				SpeciesFirst: false,
			}]

			if forward.Playable != reverse.Playable {
				return content.Catalog{}, nil, fmt.Errorf(
					"Lua choice has inconsistent start support for %s/%s",
					speciesID, jobID,
				)
			}
		}
	}

	return catalog, choices, nil
}
