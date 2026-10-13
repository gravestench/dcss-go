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

// LoadDefault builds a fresh catalog from the checked-in, source-traced species artifact.
func LoadDefault() (Catalog, error) {
	return loadDefault(defaultSpeciesJSON)
}

func loadDefault(data []byte) (Catalog, error) {
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	var artifact SpeciesArtifact
	if err := decoder.Decode(&artifact); err != nil {
		return Catalog{}, fmt.Errorf("decode species artifact: %w", err)
	}
	var trailing any
	if err := decoder.Decode(&trailing); err != io.EOF {
		return Catalog{}, fmt.Errorf("decode species artifact: trailing data")
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
	hashedPaths := make(map[string]bool, len(artifact.SourceFiles))
	previous := ""
	for _, file := range artifact.SourceFiles {
		if file.Path <= previous || len(file.SHA256) != 64 {
			return Catalog{}, fmt.Errorf("invalid or unsorted species source file %q", file.Path)
		}
		if _, err := hex.DecodeString(file.SHA256); err != nil {
			return Catalog{}, fmt.Errorf("invalid species source hash for %s: %w", file.Path, err)
		}
		hashedPaths[file.Path] = true
		previous = file.Path
	}
	catalog := scenarioCatalog()
	catalog.species = make(map[string]SpeciesDef, len(artifact.Species))
	previous = ""
	for _, species := range artifact.Species {
		if species.ID <= previous || !hashedPaths[species.SourcePath] {
			return Catalog{}, fmt.Errorf("invalid order or source path for species %s", species.ID)
		}
		catalog.species[species.ID] = species
		previous = species.ID
	}
	if err := catalog.Validate(); err != nil {
		return Catalog{}, err
	}
	return catalog, nil
}
