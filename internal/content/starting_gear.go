package content

import (
	"fmt"
	"strings"
)

// StartingGrant is one ordered item specification from a job's source data.
type StartingGrant struct {
	Raw       string `json:"raw"`
	KindID    string `json:"kind_id"`
	Quantity  int    `json:"quantity"`
	Plus      int    `json:"plus,omitempty"`
	Charges   int    `json:"charges,omitempty"`
	Ego       string `json:"ego,omitempty"`
	NoExclude bool   `json:"no_exclude,omitempty"`
}

type JobStartingGear struct {
	JobID  string          `json:"job_id"`
	Grants []StartingGrant `json:"grants"`
}

type StartingGearArtifact struct {
	SchemaVersion   int               `json:"schema_version"`
	SourceRevision  string            `json:"source_revision"`
	TagMajorVersion int               `json:"tag_major_version"`
	SourceFiles     []JobSourceFile   `json:"source_files"`
	Kinds           []ItemDef         `json:"kinds"`
	Jobs            []JobStartingGear `json:"jobs"`
}

func (d ItemDef) validate() error {
	if d.ID == "" || d.Name == "" || d.Glyph == 0 {
		return fmt.Errorf("item %s has empty ID, name, or glyph", d.ID)
	}
	prefix := map[string]string{
		"OBJ_WEAPONS": "WPN_", "OBJ_ARMOUR": "ARM_", "OBJ_MISSILES": "MI_",
		"OBJ_POTIONS": "POT_", "OBJ_SCROLLS": "SCR_", "OBJ_WANDS": "WAND_",
		"OBJ_MISCELLANY": "MISC_",
	}[d.Class]
	if prefix == "" || !strings.HasPrefix(d.ID, prefix) {
		return fmt.Errorf("item %s has invalid class %s", d.ID, d.Class)
	}
	switch d.Class {
	case "OBJ_WEAPONS":
		if d.Slot != "weapon" || !strings.HasPrefix(d.WeaponSkill, "SK_") || d.Stackable {
			return fmt.Errorf("item %s has invalid weapon slot or skill", d.ID)
		}
	case "OBJ_ARMOUR":
		if !strings.Contains(" body shield head cloak gloves boots ", " "+d.Slot+" ") || d.WeaponSkill != "" || d.Stackable {
			return fmt.Errorf("item %s has invalid armour slot or skill", d.ID)
		}
	default:
		if d.Slot != "" || d.WeaponSkill != "" {
			return fmt.Errorf("item %s has invalid slot or skill", d.ID)
		}
		if (d.Class == "OBJ_MISSILES" || d.Class == "OBJ_POTIONS" || d.Class == "OBJ_SCROLLS") && !d.Stackable {
			return fmt.Errorf("item %s must be stackable", d.ID)
		}
	}
	return nil
}

func (g StartingGrant) validate(kind ItemDef) error {
	if g.Raw == "" || g.KindID != kind.ID || g.Quantity <= 0 {
		return fmt.Errorf("grant %q has invalid raw spec, kind, or quantity", g.Raw)
	}
	if g.Raw != kind.Name && !strings.HasPrefix(g.Raw, kind.Name+" ") {
		return fmt.Errorf("grant %q does not name item kind %s (%s)", g.Raw, kind.ID, kind.Name)
	}
	if g.Charges < 0 || (g.Charges != 0 && kind.Class != "OBJ_WANDS") {
		return fmt.Errorf("grant %q has invalid charges", g.Raw)
	}
	if g.Plus != 0 && kind.Class != "OBJ_WEAPONS" && kind.Class != "OBJ_ARMOUR" {
		return fmt.Errorf("grant %q has invalid plus", g.Raw)
	}
	if g.Ego != "" && kind.Class != "OBJ_WEAPONS" && kind.Class != "OBJ_ARMOUR" && kind.Class != "OBJ_MISSILES" {
		return fmt.Errorf("grant %q has invalid ego", g.Raw)
	}
	return nil
}

func (a StartingGearArtifact) Validate() error {
	if a.SchemaVersion != 1 || a.SourceRevision == "" || a.TagMajorVersion != 34 {
		return fmt.Errorf("unsupported starting gear artifact metadata")
	}
	kinds := make(map[string]ItemDef, len(a.Kinds))
	names := make(map[string]string, len(a.Kinds))
	for _, kind := range a.Kinds {
		if err := kind.validate(); err != nil {
			return err
		}
		if _, found := kinds[kind.ID]; found {
			return fmt.Errorf("duplicate item kind %s", kind.ID)
		}
		if id, found := names[kind.Name]; found {
			return fmt.Errorf("duplicate item name %s for %s and %s", kind.Name, id, kind.ID)
		}
		kinds[kind.ID] = kind
		names[kind.Name] = kind.ID
	}
	jobs := make(map[string]bool, len(a.Jobs))
	for _, job := range a.Jobs {
		if !strings.HasPrefix(job.JobID, "JOB_") {
			return fmt.Errorf("invalid starting gear job ID %q", job.JobID)
		}
		if jobs[job.JobID] {
			return fmt.Errorf("duplicate starting gear job %s", job.JobID)
		}
		jobs[job.JobID] = true
		for _, grant := range job.Grants {
			kind, found := kinds[grant.KindID]
			if !found {
				return fmt.Errorf("job %s grant %q has unknown kind %s", job.JobID, grant.Raw, grant.KindID)
			}
			if err := grant.validate(kind); err != nil {
				return fmt.Errorf("job %s: %w", job.JobID, err)
			}
		}
	}
	return nil
}

// StartingGrants returns a copy so callers cannot change the catalog.
func (c Catalog) StartingGrants(jobID string) ([]StartingGrant, error) {
	grants, found := c.startingGear[jobID]
	if !found {
		return nil, fmt.Errorf("unknown starting gear job %q", jobID)
	}
	return append([]StartingGrant(nil), grants...), nil
}
