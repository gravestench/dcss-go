package content

import (
	"fmt"
	"slices"
)

// WithCharacterDefinitions replaces the character definitions as one unit.
// The caller supplies definitions from the effective Lua ruleset.
func (c Catalog) WithCharacterDefinitions(
	species []SpeciesDef,
	jobs []JobDef,
) (Catalog, error) {
	if len(species) == 0 || len(jobs) == 0 {
		return Catalog{}, fmt.Errorf("Lua character catalog is incomplete")
	}

	c.species = make(map[string]SpeciesDef, len(species))
	c.jobs = make(map[string]JobDef, len(jobs))

	for _, definition := range species {
		if err := definition.validate(); err != nil {
			return Catalog{}, err
		}

		if _, found := c.species[definition.ID]; found {
			return Catalog{}, fmt.Errorf("duplicate Lua species %s", definition.ID)
		}

		c.species[definition.ID] = definition.clone()
	}

	for _, definition := range jobs {
		if err := definition.validate(); err != nil {
			return Catalog{}, err
		}

		if _, found := c.jobs[definition.ID]; found {
			return Catalog{}, fmt.Errorf("duplicate Lua job %s", definition.ID)
		}

		c.jobs[definition.ID] = definition.clone()
	}

	for _, definition := range c.species {
		for _, jobID := range definition.RecommendedJobs {
			if _, found := c.jobs[jobID]; !found {
				return Catalog{}, fmt.Errorf(
					"Lua species %s recommends missing job %s",
					definition.ID, jobID,
				)
			}
		}
	}

	for _, definition := range c.jobs {
		for _, speciesID := range definition.RecommendedSpecies {
			if _, found := c.species[speciesID]; !found {
				return Catalog{}, fmt.Errorf(
					"Lua job %s recommends missing species %s",
					definition.ID, speciesID,
				)
			}
		}
	}

	if countSelectableSpecies(c.species) == 0 ||
		countSelectableJobs(c.jobs) == 0 {
		return Catalog{}, fmt.Errorf("Lua character catalog has no selectable species or jobs")
	}

	c.presentation = projectCharacterPresentation(
		c.presentation,
		c.species,
		c.jobs,
	)

	if err := c.Validate(); err != nil {
		return Catalog{}, err
	}

	return c, nil
}

func projectCharacterPresentation(
	base PresentationArtifact,
	species map[string]SpeciesDef,
	jobs map[string]JobDef,
) PresentationArtifact {
	presentation := base.clone()
	speciesSeen := make(map[string]bool)
	jobSeen := make(map[string]bool)

	for groupIndex := range presentation.SpeciesGroups {
		group := &presentation.SpeciesGroups[groupIndex]
		filtered := filterSelectable(group.IDs, species, speciesSeen)

		group.IDs = filtered
	}

	for groupIndex := range presentation.JobGroups {
		group := &presentation.JobGroups[groupIndex]
		filtered := filterSelectable(group.IDs, jobs, jobSeen)

		group.IDs = filtered
	}

	for id := range presentation.SpeciesDescriptions {
		if !speciesSeen[id] {
			delete(presentation.SpeciesDescriptions, id)
		}
	}

	for id := range presentation.JobDescriptions {
		if !jobSeen[id] {
			delete(presentation.JobDescriptions, id)
		}
	}

	speciesAdded := make([]string, 0)

	for id, definition := range species {
		if definition.Selectable && !speciesSeen[id] {
			speciesAdded = append(speciesAdded, id)
			presentation.SpeciesDescriptions[id] = definition.Name
		}
	}

	slices.Sort(speciesAdded)

	if len(speciesAdded) > 0 {
		presentation.SpeciesGroups = append(
			presentation.SpeciesGroups,
			MenuGroup{
				Label: "Modded species",
				IDs:   speciesAdded,
			},
		)
	}

	jobsAdded := make([]string, 0)

	for id, definition := range jobs {
		if definition.Selectable && !jobSeen[id] {
			jobsAdded = append(jobsAdded, id)
			presentation.JobDescriptions[id] = definition.Name
		}
	}

	slices.Sort(jobsAdded)

	if len(jobsAdded) > 0 {
		presentation.JobGroups = append(
			presentation.JobGroups,
			MenuGroup{
				Label: "Modded backgrounds",
				IDs:   jobsAdded,
			},
		)
	}

	return presentation
}

func filterSelectable[T interface{ SpeciesDef | JobDef }](
	ids []string,
	definitions map[string]T,
	seen map[string]bool,
) []string {
	filtered := make([]string, 0, len(ids))

	for _, id := range ids {
		definition, found := definitions[id]

		if !found {
			continue
		}

		selectable := false

		switch value := any(definition).(type) {
		case SpeciesDef:
			selectable = value.Selectable

		case JobDef:
			selectable = value.Selectable
		}

		if !selectable {
			continue
		}

		filtered = append(filtered, id)
		seen[id] = true
	}

	return filtered
}
