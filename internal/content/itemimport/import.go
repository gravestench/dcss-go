package itemimport

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"dcrawl-go/internal/content"
)

const pinnedRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

var sourceNames = []string{
	"object-class-type.h",
	"item-prop-enum.h",
	"potion-type.h",
	"book-type.h",
	"orb-type.h",
	"item-prop.cc",
	"item-name.cc",
	"show.cc",
	"show.h",
	"dungeon-char-type.h",
	"viewchar.cc",
	"tag-version.h",
	"equipment-type.h",
	"skill-type.h",
	"size-type.h",
	"item-prop.h",
}

var identitySourceNames = map[string]bool{
	"object-class-type.h": true,
	"item-prop-enum.h":    true,
	"potion-type.h":       true,
	"book-type.h":         true,
	"orb-type.h":          true,
	"item-prop.cc":        true,
	"tag-version.h":       true,
	"equipment-type.h":    true,
	"skill-type.h":        true,
	"size-type.h":         true,
	"item-prop.h":         true,
}

func readSources(sourceDir string) (map[string][]byte, []content.JobSourceFile, error) {
	data := make(map[string][]byte, len(sourceNames))
	files := make([]content.JobSourceFile, 0, len(sourceNames))

	for _, name := range sourceNames {
		body, err := os.ReadFile(filepath.Join(sourceDir, name))

		if err != nil {
			return nil, nil, fmt.Errorf("read %s: %w", name, err)
		}

		data[name] = body
		hash := sha256.Sum256(body)
		files = append(files, content.JobSourceFile{
			Path:   "crawl-ref/source/" + name,
			SHA256: hex.EncodeToString(hash[:]),
		})
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].Path < files[j].Path
	})

	return data, files, nil
}

func generateFromSource(sourceDir, revision string) ([]byte, []byte, error) {
	if revision != pinnedRevision {
		return nil, nil, fmt.Errorf("source revision %s differs from pinned %s", revision, pinnedRevision)
	}

	data, files, err := readSources(sourceDir)

	if err != nil {
		return nil, nil, err
	}

	if !bytes.Contains(data["tag-version.h"], []byte("#define TAG_MAJOR_VERSION 34")) {
		return nil, nil, fmt.Errorf("tag-version.h: TAG_MAJOR_VERSION must be 34")
	}

	identities, aliases, err := parseIdentities(data)

	if err != nil {
		return nil, nil, err
	}

	removed, err := parseRemovedItems("crawl-ref/source/item-prop.cc", data["item-prop.cc"])

	if err != nil {
		return nil, nil, err
	}

	for i := range identities {
		key := itemKey{
			ClassID:   identities[i].ClassID,
			SubtypeID: identities[i].ID,
		}

		if removed[key] {
			identities[i].ExplicitlyRemoved = true
			delete(removed, key)
		}
	}

	if len(removed) != 0 {
		return nil, nil, fmt.Errorf("removed_items contains %d unknown identities", len(removed))
	}

	vocabulary, err := parseVocabulary(data)

	if err != nil {
		return nil, nil, err
	}

	rows, err := parsePropertyTables("crawl-ref/source/item-prop.cc", data["item-prop.cc"], vocabulary)

	if err != nil {
		return nil, nil, err
	}

	names, err := parseItemNames("crawl-ref/source/item-name.cc", data["item-name.cc"], identities)

	if err != nil {
		return nil, nil, err
	}

	glyphs, err := parseASCIIItemGlyphs(
		"crawl-ref/source/show.cc",
		data["show.cc"],
		data["show.h"],
		data["dungeon-char-type.h"],
		"crawl-ref/source/viewchar.cc",
		data["viewchar.cc"],
		identities,
	)

	if err != nil {
		return nil, nil, err
	}

	items, err := joinItemViews(identities, rows, names, glyphs)

	if err != nil {
		return nil, nil, err
	}

	itemBytes, err := json.Marshal(items)

	if err != nil {
		return nil, nil, err
	}

	digest := sha256.Sum256(itemBytes)
	manifestFiles := make([]content.JobSourceFile, 0, len(identitySourceNames))

	for _, file := range files {
		if identitySourceNames[strings.TrimPrefix(file.Path, "crawl-ref/source/")] {
			manifestFiles = append(manifestFiles, file)
		}
	}

	manifest := content.ItemIdentityManifest{
		SchemaVersion:     1,
		SourceRevision:    revision,
		TagMajorVersion:   34,
		SourceFiles:       manifestFiles,
		Identities:        identities,
		Aliases:           aliases,
		Vocabulary:        vocabulary,
		DefinitionsSHA256: hex.EncodeToString(digest[:]),
	}

	artifact := content.ItemArtifact{
		SchemaVersion:   1,
		SourceRevision:  revision,
		TagMajorVersion: 34,
		SourceFiles:     files,
		Items:           items,
	}

	if err := artifact.Validate(manifest); err != nil {
		return nil, nil, err
	}

	itemOutput, err := json.MarshalIndent(artifact, "", "  ")

	if err != nil {
		return nil, nil, err
	}

	manifestOutput, err := json.MarshalIndent(manifest, "", "  ")

	if err != nil {
		return nil, nil, err
	}

	return append(itemOutput, '\n'), append(manifestOutput, '\n'), nil
}

// Generate imports from the pinned source revision, requiring clean tracked inputs.
func Generate(sourceDir string) ([]byte, []byte, error) {
	if sourceDir == "" {
		return nil, nil, fmt.Errorf("source directory is required")
	}

	revision, err := exec.Command("git", "-C", sourceDir, "rev-parse", "HEAD").Output()

	if err != nil {
		return nil, nil, fmt.Errorf("source revision: %w", err)
	}

	if strings.TrimSpace(string(revision)) != pinnedRevision {
		return nil, nil, fmt.Errorf(
			"source revision %s differs from pinned %s",
			strings.TrimSpace(string(revision)),
			pinnedRevision,
		)
	}

	args := append([]string{
		"-C",
		sourceDir,
		"status",
		"--porcelain",
		"--untracked-files=no",
		"--",
	}, sourceNames...)

	status, err := exec.Command("git", args...).Output()

	if err != nil {
		return nil, nil, fmt.Errorf("source status: %w", err)
	}

	if len(bytes.TrimSpace(status)) != 0 {
		return nil, nil, fmt.Errorf("tracked item sources have local changes: %s", strings.TrimSpace(string(status)))
	}

	return generateFromSource(sourceDir, pinnedRevision)
}

func validatePair(itemsJSON, identitiesJSON []byte) error {
	var artifact content.ItemArtifact
	var manifest content.ItemIdentityManifest

	if err := json.Unmarshal(itemsJSON, &artifact); err != nil {
		return fmt.Errorf("decode items: %w", err)
	}

	if err := json.Unmarshal(identitiesJSON, &manifest); err != nil {
		return fmt.Errorf("decode identities: %w", err)
	}

	return artifact.Validate(manifest)
}

func writeTemp(path string, data []byte) (string, error) {
	file, err := os.CreateTemp(filepath.Dir(path), ".item-import-*.tmp")

	if err != nil {
		return "", err
	}

	defer file.Close()
	defer func() {
		if err != nil {
			os.Remove(file.Name())
		}
	}()

	if _, err = file.Write(data); err != nil {
		return "", err
	}

	if err = file.Sync(); err != nil {
		return "", err
	}

	if err = file.Close(); err != nil {
		return "", err
	}

	return file.Name(), nil
}

func writePair(outPath string, check bool, generate func() ([]byte, []byte, error)) error {
	if outPath == "" {
		return fmt.Errorf("output path is required")
	}

	items, identities, err := generate()

	if err != nil {
		return err
	}

	if err := validatePair(items, identities); err != nil {
		return fmt.Errorf("generated item pair: %w", err)
	}

	manifestPath := filepath.Join(filepath.Dir(outPath), "item-identities.json")

	if check {
		for _, entry := range []struct {
			path string
			data []byte
		}{
			{
				path: outPath,
				data: items,
			},
			{
				path: manifestPath,
				data: identities,
			},
		} {
			current, err := os.ReadFile(entry.path)

			if err != nil {
				return err
			}

			if !bytes.Equal(current, entry.data) {
				return fmt.Errorf("artifact %s is stale", entry.path)
			}
		}

		return nil
	}

	itemTemp, err := writeTemp(outPath, items)

	if err != nil {
		return err
	}

	defer os.Remove(itemTemp)
	manifestTemp, err := writeTemp(manifestPath, identities)

	if err != nil {
		return err
	}

	defer os.Remove(manifestTemp)

	if err := os.Rename(itemTemp, outPath); err != nil {
		return err
	}

	if err := os.Rename(manifestTemp, manifestPath); err != nil {
		return err
	}

	return nil
}

// Write checks or replaces the committed item artifact pair.
func Write(sourceDir, outPath string, check bool) error {
	return writePair(outPath, check, func() ([]byte, []byte, error) {
		return Generate(sourceDir)
	})
}
