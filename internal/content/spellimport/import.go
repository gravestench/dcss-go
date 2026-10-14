package spellimport

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"dcrawl-go/internal/content"
)

const pinnedRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

var sourceNames = []string{
	"tag-version.h",
	"spell-type.h",
	"spl-data.h",
	"spl-util.cc",
	"spl-util.h",
	"spl-cast.h",
}

func Generate(sourceDir string) ([]byte, error) {
	if sourceDir == "" {
		return nil, fmt.Errorf("pinned C++ source directory is required")
	}

	sources := make(map[string][]byte, len(sourceNames))
	files := make([]content.JobSourceFile, 0, len(sourceNames))

	for _, name := range sourceNames {
		path := filepath.Join(sourceDir, name)
		body, err := os.ReadFile(path)

		if err != nil {
			return nil, fmt.Errorf("read %s: %w", path, err)
		}

		sources[name] = body
		hash := sha256.Sum256(body)
		files = append(files, content.JobSourceFile{
			Path:   "crawl-ref/source/" + name,
			SHA256: hex.EncodeToString(hash[:]),
		})
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].Path < files[j].Path
	})
	ids, err := parseEnum("spell-type.h", sources["spell-type.h"])

	if err != nil {
		return nil, err
	}

	spells, err := parseSpells("spl-data.h", sources["spl-data.h"])

	if err != nil {
		return nil, err
	}

	removed, err := parseRemoved("spl-util.cc", sources["spl-util.cc"])

	if err != nil {
		return nil, err
	}

	if err := reconcile(ids, spells, removed); err != nil {
		return nil, err
	}

	schools, err := parseVocabulary("spl-util.h", sources["spl-util.h"], "spschool")

	if err != nil {
		return nil, err
	}

	flags, err := parseVocabulary("spl-cast.h", sources["spl-cast.h"], "spflag")

	if err != nil {
		return nil, err
	}

	artifact := content.SpellArtifact{
		SchemaVersion:   1,
		SourceRevision:  pinnedRevision,
		TagMajorVersion: 34,
		SourceFiles:     files,
	}

	for _, id := range ids {
		spell := spells[id.ID]

		for _, school := range spell.Schools {
			if !schools[school] {
				return nil, fmt.Errorf("spell %s uses unknown school %s", spell.ID, school)
			}
		}

		for _, flag := range spell.Flags {
			if !flags[flag] {
				return nil, fmt.Errorf("spell %s uses unknown flag %s", spell.ID, flag)
			}
		}

		spell.NumericID = id.NumericID
		spell.EnumLine = id.EnumLine
		artifact.Spells = append(artifact.Spells, spell)
	}

	if err := artifact.Validate(); err != nil {
		return nil, err
	}

	encoded, err := json.MarshalIndent(artifact, "", "  ")

	if err != nil {
		return nil, err
	}

	return append(encoded, '\n'), nil
}

func Write(sourceDir, outPath string, check bool) error {
	if outPath == "" {
		return fmt.Errorf("spell output path is required")
	}

	generated, err := Generate(sourceDir)

	if err != nil {
		return err
	}

	if check {
		committed, err := os.ReadFile(outPath)

		if err != nil {
			return err
		}

		if !bytes.Equal(committed, generated) {
			return fmt.Errorf("spell artifact %s differs from pinned source", outPath)
		}

		return nil
	}

	file, err := os.CreateTemp(filepath.Dir(outPath), ".spells-*.json")

	if err != nil {
		return err
	}

	temp := file.Name()
	defer os.Remove(temp)

	if _, err := file.Write(generated); err != nil {
		file.Close()

		return err
	}

	if err := file.Close(); err != nil {
		return err
	}

	return os.Rename(temp, outPath)
}
