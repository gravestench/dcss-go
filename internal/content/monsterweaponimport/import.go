package monsterweaponimport

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
	"mon-gear.cc",
	"tag-version.h",
}

var pinnedSourceHashes = map[string]string{
	"mon-gear.cc":   "f46190735b99a7c0f1a2aaa07ac378fc6a900766399f541ceb5f4ef33e46a4e1",
	"tag-version.h": "2f8ed7610ca03ba6014044f78ca9f9b9392208a37d3539119ef04bd853ab1dfa",
}

// Generate reads pinned C++ content only for an intentional developer refresh.
func Generate(sourceDir string) ([]byte, error) {
	if sourceDir == "" {
		return nil, fmt.Errorf("pinned source directory is required")
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
		encodedHash := hex.EncodeToString(hash[:])

		if encodedHash != pinnedSourceHashes[name] {
			return nil, fmt.Errorf("%s differs from pinned source", name)
		}

		files = append(files, content.JobSourceFile{
			Path:   "crawl-ref/source/" + name,
			SHA256: encodedHash,
		})
	}

	sort.Slice(files, func(left, right int) bool {
		return files[left].Path < files[right].Path
	})

	primary, secondary, err := parseSource("mon-gear.cc", sources["mon-gear.cc"])

	if err != nil {
		return nil, err
	}

	artifact := content.MonsterWeaponArtifact{
		SchemaVersion:  1,
		SourceRevision: pinnedRevision,
		SourceFiles:    files,
		Primary:        primary,
		Secondary:      secondary,
	}

	if err := artifact.Validate(); err != nil {
		return nil, err
	}

	catalog, err := content.LoadDefinitionsForImport()

	if err != nil {
		return nil, fmt.Errorf("load committed definitions: %w", err)
	}

	if err := content.ValidateMonsterWeaponReferences(catalog, artifact); err != nil {
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
		return fmt.Errorf("monster weapon output path is required")
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
			return fmt.Errorf("monster weapon artifact %s differs from pinned source", outPath)
		}

		return nil
	}

	file, err := os.CreateTemp(filepath.Dir(outPath), ".monster-weapons-*.json")

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
