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
	Jobs            []JobStartingGear `json:"jobs"`
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

func (a StartingGearArtifact) Validate(catalog Catalog) error {
	if a.SchemaVersion != 2 || a.SourceRevision == "" || a.TagMajorVersion != 34 {
		return fmt.Errorf("unsupported starting gear artifact metadata")
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
			kind, err := catalog.Item(grant.KindID)
			if err != nil {
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
