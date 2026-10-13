package content

import "fmt"

// MenuGroup preserves the source console's category and letter order.
type MenuGroup struct {
	Label string   `json:"label"`
	IDs   []string `json:"ids"`
}

type StartupMode struct {
	ID          string `json:"id"`
	Label       string `json:"label"`
	Description string `json:"description"`
}

// PresentationArtifact contains source menu prose and order, independent of the C++ checkout.
type PresentationArtifact struct {
	SchemaVersion       int               `json:"schema_version"`
	SourceRevision      string            `json:"source_revision"`
	SourceVersion       string            `json:"source_version"`
	TagMajorVersion     int               `json:"tag_major_version"`
	SourceFiles         []JobSourceFile   `json:"source_files"`
	StartupModes        []StartupMode     `json:"startup_modes"`
	SpeciesGroups       []MenuGroup       `json:"species_groups"`
	JobGroups           []MenuGroup       `json:"job_groups"`
	SpeciesDescriptions map[string]string `json:"species_descriptions"`
	JobDescriptions     map[string]string `json:"job_descriptions"`
}

func (a PresentationArtifact) clone() PresentationArtifact {
	a.SourceFiles = append([]JobSourceFile(nil), a.SourceFiles...)
	a.StartupModes = append([]StartupMode(nil), a.StartupModes...)
	a.SpeciesGroups = cloneGroups(a.SpeciesGroups)
	a.JobGroups = cloneGroups(a.JobGroups)
	a.SpeciesDescriptions = cloneDescriptions(a.SpeciesDescriptions)
	a.JobDescriptions = cloneDescriptions(a.JobDescriptions)
	return a
}

func cloneGroups(groups []MenuGroup) []MenuGroup {
	copy := append([]MenuGroup(nil), groups...)
	for i := range copy {
		copy[i].IDs = append([]string(nil), groups[i].IDs...)
	}
	return copy
}

func cloneDescriptions(descriptions map[string]string) map[string]string {
	copy := make(map[string]string, len(descriptions))
	for id, description := range descriptions {
		copy[id] = description
	}
	return copy
}

func (c Catalog) Presentation() PresentationArtifact { return c.presentation.clone() }

func (a PresentationArtifact) validate(c Catalog) error {
	if a.SchemaVersion != 1 || a.SourceRevision != sourceRevision || a.SourceVersion == "" || a.TagMajorVersion != 34 {
		return fmt.Errorf("unsupported presentation artifact schema/revision/tag")
	}
	if len(a.SpeciesGroups) != 3 || len(a.JobGroups) != 5 || len(a.SourceFiles) != 6 || len(a.StartupModes) != 8 {
		return fmt.Errorf("presentation has incomplete groups or provenance")
	}
	seenModes := map[string]bool{}
	for _, mode := range a.StartupModes {
		if mode.ID == "" || mode.Label == "" || mode.Description == "" || seenModes[mode.ID] {
			return fmt.Errorf("invalid or duplicate startup mode %s", mode.ID)
		}
		seenModes[mode.ID] = true
	}
	if _, err := validSourceFiles(a.SourceFiles, "presentation"); err != nil {
		return err
	}
	if err := validateMenuGroups(a.SpeciesGroups, a.SpeciesDescriptions, c.species, 27, "species"); err != nil {
		return err
	}
	if err := validateMenuGroups(a.JobGroups, a.JobDescriptions, c.jobs, 25, "job"); err != nil {
		return err
	}
	return nil
}

func validateMenuGroups[T interface{ SpeciesDef | JobDef }](groups []MenuGroup, descriptions map[string]string, definitions map[string]T, expected int, kind string) error {
	seen := make(map[string]bool, expected)
	for _, group := range groups {
		if group.Label == "" || len(group.IDs) == 0 {
			return fmt.Errorf("empty %s menu group", kind)
		}
		for _, id := range group.IDs {
			if seen[id] {
				return fmt.Errorf("duplicate %s menu ID %s", kind, id)
			}
			definition, found := definitions[id]
			if !found {
				return fmt.Errorf("unknown %s menu ID %s", kind, id)
			}
			switch entry := any(definition).(type) {
			case SpeciesDef:
				if !entry.Selectable {
					return fmt.Errorf("nonselectable species menu ID %s", id)
				}
			case JobDef:
				if !entry.Selectable {
					return fmt.Errorf("nonselectable job menu ID %s", id)
				}
			}
			if descriptions[id] == "" {
				return fmt.Errorf("missing %s description for %s", kind, id)
			}
			seen[id] = true
		}
	}
	if len(seen) != expected || len(descriptions) != expected {
		return fmt.Errorf("%s presentation has %d menu IDs and %d descriptions, want %d", kind, len(seen), len(descriptions), expected)
	}
	for id := range descriptions {
		if !seen[id] {
			return fmt.Errorf("unknown %s description ID %s", kind, id)
		}
	}
	return nil
}
