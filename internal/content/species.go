package content

import (
	"fmt"
	"sort"
	"strings"
)

// SpeciesAptitude keeps an unusable skill distinct from a zero aptitude.
type SpeciesAptitude struct {
	Allowed bool `json:"allowed"`
	Value   int  `json:"value"`
}

type SpeciesMutation struct {
	Level  int    `json:"level"`
	ID     string `json:"id"`
	Amount int    `json:"amount"`
}

type SpeciesFakeMutation struct {
	Long  string `json:"long,omitempty"`
	Short string `json:"short,omitempty"`
}

type SpeciesDef struct {
	ID                   string                     `json:"id"`
	MonsterID            string                     `json:"monster_id"`
	SourcePath           string                     `json:"source_path"`
	Name                 string                     `json:"name"`
	ShortName            string                     `json:"short_name"`
	Adjective            string                     `json:"adjective,omitempty"`
	Genus                string                     `json:"genus,omitempty"`
	Selectable           bool                       `json:"selectable"`
	Difficulty           string                     `json:"difficulty,omitempty"`
	DifficultyPriority   int                        `json:"difficulty_priority,omitempty"`
	XP                   int                        `json:"xp"`
	HP                   int                        `json:"hp"`
	MPMod                int                        `json:"mp_mod"`
	MR                   int                        `json:"mr"`
	Strength             int                        `json:"strength"`
	Intelligence         int                        `json:"intelligence"`
	Dexterity            int                        `json:"dexterity"`
	LevelUpStatFrequency int                        `json:"levelup_stat_frequency"`
	LevelUpStats         []string                   `json:"levelup_stats"`
	Aptitudes            map[string]SpeciesAptitude `json:"aptitudes"`
	Mutations            []SpeciesMutation          `json:"mutations,omitempty"`
	FakeMutations        []SpeciesFakeMutation      `json:"fake_mutations,omitempty"`
	Flags                []string                   `json:"flags,omitempty"`
	Habitat              string                     `json:"habitat"`
	Size                 string                     `json:"size"`
	UndeadType           string                     `json:"undead_type"`
	RecommendedJobs      []string                   `json:"recommended_jobs,omitempty"`
	RecommendedWeapons   []string                   `json:"recommended_weapons,omitempty"`
	WalkingVerb          string                     `json:"walking_verb,omitempty"`
	AltarAction          string                     `json:"altar_action,omitempty"`
}

type SpeciesSourceFile struct {
	Path   string `json:"path"`
	SHA256 string `json:"sha256"`
}

type SpeciesArtifact struct {
	SchemaVersion   int                 `json:"schema_version"`
	SourceRevision  string              `json:"source_revision"`
	TagMajorVersion int                 `json:"tag_major_version"`
	SourceFiles     []SpeciesSourceFile `json:"source_files"`
	Species         []SpeciesDef        `json:"species"`
}

func (a SpeciesArtifact) Validate() error {
	if a.SchemaVersion != 1 || a.SourceRevision == "" || a.TagMajorVersion != 34 {
		return fmt.Errorf("unsupported species artifact metadata")
	}
	seen := make(map[string]bool, len(a.Species))
	for _, species := range a.Species {
		if err := species.validate(); err != nil {
			return err
		}
		if seen[species.ID] {
			return fmt.Errorf("duplicate species ID %s", species.ID)
		}
		seen[species.ID] = true
	}
	return nil
}

func (s SpeciesDef) validate() error {
	if !strings.HasPrefix(s.ID, "SP_") || !strings.HasPrefix(s.MonsterID, "MONS_") || s.SourcePath == "" || s.Name == "" || s.ShortName == "" {
		return fmt.Errorf("invalid species definition %q", s.ID)
	}
	if s.Strength < 1 || s.Intelligence < 1 || s.Dexterity < 1 || s.LevelUpStatFrequency < 0 || s.LevelUpStatFrequency > 28 {
		return fmt.Errorf("invalid species stats %q", s.ID)
	}
	if s.Habitat == "" || s.Size == "" || s.UndeadType == "" {
		return fmt.Errorf("invalid species environment %q", s.ID)
	}
	for skill, aptitude := range s.Aptitudes {
		if !strings.HasPrefix(skill, "SK_") || (!aptitude.Allowed && aptitude.Value != 0) {
			return fmt.Errorf("invalid species aptitude %s for %s", skill, s.ID)
		}
	}
	for _, mutation := range s.Mutations {
		if mutation.Level < 1 || mutation.Level > 27 || !strings.HasPrefix(mutation.ID, "MUT_") || mutation.Amount < -3 || mutation.Amount > 3 {
			return fmt.Errorf("invalid species mutation %s for %s", mutation.ID, s.ID)
		}
	}
	return nil
}

func (s SpeciesDef) clone() SpeciesDef {
	s.LevelUpStats = append([]string(nil), s.LevelUpStats...)
	s.Mutations = append([]SpeciesMutation(nil), s.Mutations...)
	s.FakeMutations = append([]SpeciesFakeMutation(nil), s.FakeMutations...)
	s.Flags = append([]string(nil), s.Flags...)
	s.RecommendedJobs = append([]string(nil), s.RecommendedJobs...)
	s.RecommendedWeapons = append([]string(nil), s.RecommendedWeapons...)
	if s.Aptitudes != nil {
		copy := make(map[string]SpeciesAptitude, len(s.Aptitudes))
		for id, aptitude := range s.Aptitudes {
			copy[id] = aptitude
		}
		s.Aptitudes = copy
	}
	return s
}

func (c Catalog) Species(id string) (SpeciesDef, error) {
	definition, found := c.species[id]
	if !found {
		return SpeciesDef{}, fmt.Errorf("unknown species ID %q", id)
	}
	return definition.clone(), nil
}

func (c Catalog) SpeciesIDs() []string {
	ids := make([]string, 0, len(c.species))
	for id := range c.species {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	return ids
}
