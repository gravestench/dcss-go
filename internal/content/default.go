package content

import (
	"bytes"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
)

//go:embed generated/species.json
var defaultSpeciesJSON []byte

//go:embed generated/jobs.json
var defaultJobsJSON []byte

// LoadDefault builds a fresh catalog from the checked-in source-traced artifacts.
func LoadDefault() (Catalog, error) {
	return loadDefault(defaultSpeciesJSON, defaultJobsJSON)
}

func decodeArtifact(data []byte, name string, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return fmt.Errorf("decode %s artifact: %w", name, err)
	}
	var trailing any
	if err := decoder.Decode(&trailing); err != io.EOF {
		return fmt.Errorf("decode %s artifact: trailing data", name)
	}
	return nil
}

func validSourceFiles(files []JobSourceFile, name string) (map[string]string, error) {
	paths := make(map[string]string, len(files))
	previous := ""
	for _, file := range files {
		if file.Path <= previous || len(file.SHA256) != 64 {
			return nil, fmt.Errorf("invalid or unsorted %s source file %q", name, file.Path)
		}
		if _, err := hex.DecodeString(file.SHA256); err != nil {
			return nil, fmt.Errorf("invalid %s source hash for %s: %w", name, file.Path, err)
		}
		paths[file.Path] = file.SHA256
		previous = file.Path
	}
	return paths, nil
}

func loadDefault(speciesData, jobData []byte) (Catalog, error) {
	var artifact SpeciesArtifact
	if err := decodeArtifact(speciesData, "species", &artifact); err != nil {
		return Catalog{}, err
	}
	if artifact.SchemaVersion != 1 || artifact.SourceRevision != sourceRevision || artifact.TagMajorVersion != 34 {
		return Catalog{}, fmt.Errorf("unsupported species artifact schema/revision/tag")
	}
	if len(artifact.Species) != 43 || len(artifact.SourceFiles) != 46 {
		return Catalog{}, fmt.Errorf("species artifact has incomplete records or provenance")
	}
	if err := artifact.Validate(); err != nil {
		return Catalog{}, err
	}
	speciesFiles := make([]JobSourceFile, 0, len(artifact.SourceFiles))
	for _, file := range artifact.SourceFiles {
		speciesFiles = append(speciesFiles, JobSourceFile{Path: file.Path, SHA256: file.SHA256})
	}
	hashedPaths, err := validSourceFiles(speciesFiles, "species")
	if err != nil {
		return Catalog{}, err
	}
	catalog := scenarioCatalog()
	catalog.species = make(map[string]SpeciesDef, len(artifact.Species))
	previous := ""
	for _, species := range artifact.Species {
		if _, found := hashedPaths[species.SourcePath]; species.ID <= previous || !found {
			return Catalog{}, fmt.Errorf("invalid order or source path for species %s", species.ID)
		}
		catalog.species[species.ID] = species
		previous = species.ID
	}
	var jobs JobArtifact
	if err := decodeArtifact(jobData, "job", &jobs); err != nil {
		return Catalog{}, err
	}
	if jobs.SchemaVersion != 1 || jobs.SourceRevision != artifact.SourceRevision || jobs.TagMajorVersion != artifact.TagMajorVersion {
		return Catalog{}, fmt.Errorf("unsupported or mismatched job artifact schema/revision/tag")
	}
	if len(jobs.Jobs) != 31 || len(jobs.SourceFiles) != 6 {
		return Catalog{}, fmt.Errorf("job artifact has incomplete records or provenance")
	}
	if err := jobs.Validate(); err != nil {
		return Catalog{}, err
	}
	jobPaths, err := validSourceFiles(jobs.SourceFiles, "job")
	if err != nil {
		return Catalog{}, err
	}
	for path, hash := range jobPaths {
		if speciesHash, shared := hashedPaths[path]; shared && speciesHash != hash {
			return Catalog{}, fmt.Errorf("shared source hash differs for %s", path)
		}
	}
	catalog.jobs = make(map[string]JobDef, len(jobs.Jobs))
	previous = ""
	for _, job := range jobs.Jobs {
		if _, found := jobPaths[job.SourcePath]; job.ID <= previous || !found {
			return Catalog{}, fmt.Errorf("invalid order or source path for job %s", job.ID)
		}
		for _, speciesID := range job.RecommendedSpecies {
			if _, ok := catalog.species[speciesID]; !ok {
				return Catalog{}, fmt.Errorf("job %s recommends missing species %s", job.ID, speciesID)
			}
		}
		catalog.jobs[job.ID] = job
		previous = job.ID
	}
	for _, species := range catalog.species {
		for _, jobID := range species.RecommendedJobs {
			if _, ok := catalog.jobs[jobID]; !ok {
				return Catalog{}, fmt.Errorf("species %s recommends missing job %s", species.ID, jobID)
			}
		}
	}
	if err := catalog.Validate(); err != nil {
		return Catalog{}, err
	}
	return catalog, nil
}
