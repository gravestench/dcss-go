package content

import (
	"fmt"
	"sort"
	"strings"
)

type JobSkillGrant struct {
	ID    string `json:"id"`
	Level int    `json:"level"`
}

type JobSourceFile struct {
	Path   string `json:"path"`
	SHA256 string `json:"sha256"`
}

type JobDef struct {
	ID                 string          `json:"id"`
	SourcePath         string          `json:"source_path"`
	Abbreviation       string          `json:"abbreviation"`
	Name               string          `json:"name"`
	Strength           int             `json:"strength"`
	Intelligence       int             `json:"intelligence"`
	Dexterity          int             `json:"dexterity"`
	RecommendedSpecies []string        `json:"recommended_species"`
	Spells             []string        `json:"spells"`
	Equipment          []string        `json:"equipment"`
	WeaponChoice       string          `json:"weapon_choice"`
	Skills             []JobSkillGrant `json:"skills"`
	Selectable         bool            `json:"selectable"`
}

type JobArtifact struct {
	SchemaVersion   int             `json:"schema_version"`
	SourceRevision  string          `json:"source_revision"`
	TagMajorVersion int             `json:"tag_major_version"`
	SourceFiles     []JobSourceFile `json:"source_files"`
	Jobs            []JobDef        `json:"jobs"`
}

func (a JobArtifact) Validate() error {
	if a.SchemaVersion != 1 || a.SourceRevision == "" || a.TagMajorVersion != 34 {
		return fmt.Errorf("unsupported job artifact metadata")
	}

	ids := make(map[string]bool, len(a.Jobs))
	abbreviations := make(map[string]bool, len(a.Jobs))

	for _, job := range a.Jobs {
		if err := job.validate(); err != nil {
			return err
		}

		if ids[job.ID] || abbreviations[job.Abbreviation] {
			return fmt.Errorf("duplicate job ID or abbreviation %s/%s", job.ID, job.Abbreviation)
		}

		ids[job.ID] = true
		abbreviations[job.Abbreviation] = true
	}

	return nil
}

func (j JobDef) validate() error {
	if !strings.HasPrefix(j.ID, "JOB_") || j.SourcePath == "" || len(j.Abbreviation) != 2 || j.Name == "" {
		return fmt.Errorf("invalid job definition %q", j.ID)
	}

	if j.Selectable != (len(j.RecommendedSpecies) > 0) {
		return fmt.Errorf("job %s selectability disagrees with recommendations", j.ID)
	}

	switch j.WeaponChoice {
	case "WCHOICE_NONE", "WCHOICE_PLAIN", "WCHOICE_GOOD":

	default:
		return fmt.Errorf("job %s has invalid weapon choice %q", j.ID, j.WeaponChoice)
	}

	for _, species := range j.RecommendedSpecies {
		if !strings.HasPrefix(species, "SP_") {
			return fmt.Errorf("job %s has invalid species %q", j.ID, species)
		}
	}

	for _, spell := range j.Spells {
		if !strings.HasPrefix(spell, "SPELL_") {
			return fmt.Errorf("job %s has invalid spell %q", j.ID, spell)
		}
	}

	for _, skill := range j.Skills {
		if !strings.HasPrefix(skill.ID, "SK_") || skill.Level < 0 || skill.Level > 27 {
			return fmt.Errorf("job %s has invalid skill grant %s/%d", j.ID, skill.ID, skill.Level)
		}
	}

	return nil
}

func (j JobDef) clone() JobDef {
	j.RecommendedSpecies = append([]string(nil), j.RecommendedSpecies...)
	j.Spells = append([]string(nil), j.Spells...)
	j.Equipment = append([]string(nil), j.Equipment...)
	j.Skills = append([]JobSkillGrant(nil), j.Skills...)

	return j
}

func (c Catalog) Job(id string) (JobDef, error) {
	job, found := c.jobs[id]

	if !found {
		return JobDef{}, fmt.Errorf("unknown job ID %q", id)
	}

	return job.clone(), nil
}

func (c Catalog) JobIDs() []string {
	ids := make([]string, 0, len(c.jobs))

	for id := range c.jobs {
		ids = append(ids, id)
	}

	sort.Strings(ids)

	return ids
}
