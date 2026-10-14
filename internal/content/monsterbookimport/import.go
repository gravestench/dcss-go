package monsterbookimport

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
	"externs.h",
	"mon-mst.h",
	"mon-spell.h",
}

// Generate reads the pinned C++ tables only when a developer requests a
// content refresh. Runtime and ordinary builds use committed JSON instead.
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

	sort.Slice(files, func(left, right int) bool {
		return files[left].Path < files[right].Path
	})

	books, err := parseBooks("mon-spell.h", sources["mon-spell.h"])

	if err != nil {
		return nil, err
	}

	ids, err := parseBookEnum("mon-mst.h", sources["mon-mst.h"])

	if err != nil {
		return nil, err
	}

	flags, err := parseFlagVocabulary("externs.h", sources["externs.h"])

	if err != nil {
		return nil, err
	}

	if err := reconcile(books, ids, flags); err != nil {
		return nil, err
	}

	// Spell identities are already committed independently. Refresh that
	// catalog first when the pinned C++ source adds a new spell.
	catalog, err := content.LoadDefaultSpells()

	if err != nil {
		return nil, fmt.Errorf("load committed spell catalog: %w", err)
	}

	for _, book := range books {
		for _, slot := range book.Slots {
			if _, err := catalog.Spell(slot.SpellID); err != nil {
				return nil, fmt.Errorf("%s:%d: %w",
					"mon-spell.h", slot.SourceLine, err)
			}
		}
	}

	artifact := content.MonsterSpellbookArtifact{
		SchemaVersion:  2,
		SourceRevision: pinnedRevision,
		SourceFiles:    files,
		Books:          books,
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
		return fmt.Errorf("monster spellbook output path is required")
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
			return fmt.Errorf("monster spellbook artifact %s differs from pinned source", outPath)
		}

		return nil
	}

	file, err := os.CreateTemp(filepath.Dir(outPath), ".monster-spellbooks-*.json")

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
