package script

import (
	"encoding/json"
	"fmt"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

// ChoiceKey identifies one direction of the character creation menu.
type ChoiceKey struct {
	SpeciesID    string
	JobID        string
	SpeciesFirst bool
}

// MenuGroup preserves the Lua console menu's category and letter order.
type MenuGroup struct {
	Label string   `json:"label"`
	IDs   []string `json:"ids"`
}

type StartupMode struct {
	ID          string `json:"id"`
	Label       string `json:"label"`
	Description string `json:"description"`
}

// MenuPresentation is the finite screen data Go needs to draw pregame UI.
// Definitions and rules stay in Lua; this value is never a gameplay catalog.
type MenuPresentation struct {
	StartupModes        []StartupMode     `json:"startup_modes"`
	SkillColumns        [][]string        `json:"skill_columns"`
	SpeciesGroups       []MenuGroup       `json:"species_groups"`
	JobGroups           []MenuGroup       `json:"job_groups"`
	SpeciesDescriptions map[string]string `json:"species_descriptions"`
	JobDescriptions     map[string]string `json:"job_descriptions"`
}

func (m MenuPresentation) SpeciesIDs() []string {
	return menuIDs(m.SpeciesGroups)
}

func (m MenuPresentation) JobIDs() []string {
	return menuIDs(m.JobGroups)
}

func menuIDs(groups []MenuGroup) []string {
	ids := make([]string, 0)

	for _, group := range groups {
		ids = append(ids, group.IDs...)
	}

	return ids
}

// ProjectCharacterMenu loads the effective Lua menu and choice policy for
// the client before a game session exists.
func ProjectCharacterMenu(
	rules modfs.Ruleset,
) (MenuPresentation, map[ChoiceKey]Choice, error) {
	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		return MenuPresentation{}, nil, err
	}

	defer runtime.Close()

	raw, err := runtime.Policy("character.menu", nil)

	if err != nil {
		return MenuPresentation{}, nil, err
	}

	encoded, err := json.Marshal(raw)

	if err != nil {
		return MenuPresentation{}, nil, err
	}

	var menu MenuPresentation

	if err := json.Unmarshal(encoded, &menu); err != nil {
		return MenuPresentation{}, nil, err
	}

	choices := make(map[ChoiceKey]Choice)

	for _, speciesID := range runtime.DefinitionIDs("species") {
		for _, jobID := range runtime.DefinitionIDs("jobs") {
			for _, speciesFirst := range []bool{false, true} {
				choice, err := runtime.CharacterChoice(
					speciesID, jobID, speciesFirst,
				)

				if err != nil {
					return MenuPresentation{}, nil, err
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
				return MenuPresentation{}, nil, fmt.Errorf(
					"Lua choice has inconsistent start support for %s/%s",
					speciesID, jobID,
				)
			}
		}
	}

	return menu, choices, nil
}
