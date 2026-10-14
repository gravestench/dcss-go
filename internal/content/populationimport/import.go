package populationimport

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"dcrawl-go/internal/content"
)

const pinnedRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

var sourceNames = []string{"mon-pick-data.h", "random-pick.h", "tag-version.h"}

var pinnedSourceSHA256 = map[string]string{
	"mon-pick-data.h": "055cc0f1a9837044a99acb04560231403d8c4d5f58c64d9d006f131016d168ea",
	"random-pick.h":   "0820634c324892fe114d0731aa85627aeb6399f35b24ab322d2053ea26ecafbc",
	"tag-version.h":   "2f8ed7610ca03ba6014044f78ca9f9b9392208a37d3539119ef04bd853ab1dfa",
}

func Generate(sourceDir string) ([]byte, error) {
	if sourceDir == "" {
		return nil, fmt.Errorf("pinned C++ source directory is required")
	}
	sources := make(map[string][]byte, len(sourceNames))
	files := make([]content.JobSourceFile, 0, len(sourceNames))
	for _, name := range sourceNames {
		body, err := os.ReadFile(filepath.Join(sourceDir, name))
		if err != nil {
			return nil, fmt.Errorf("read %s: %w", name, err)
		}
		sources[name] = body
		hash := sha256.Sum256(body)
		actual := hex.EncodeToString(hash[:])
		if actual != pinnedSourceSHA256[name] {
			return nil, fmt.Errorf("%s differs from pinned revision %s", name, pinnedRevision)
		}
		files = append(files, content.JobSourceFile{Path: "crawl-ref/source/" + name, SHA256: actual})
	}
	if !strings.Contains(string(sources["tag-version.h"]), "#define TAG_MAJOR_VERSION 34") {
		return nil, fmt.Errorf("source does not define tag major version 34")
	}
	rows, err := parseDungeonRows(sources["mon-pick-data.h"])
	if err != nil {
		return nil, err
	}
	if len(rows) != 125 {
		return nil, fmt.Errorf("pinned Dungeon population has %d rows, want 125", len(rows))
	}
	artifact := content.DungeonPopulationArtifact{SchemaVersion: 1, SourceRevision: pinnedRevision, TagMajorVersion: 34, SourceFiles: files, Rows: rows}
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
		return fmt.Errorf("Dungeon population output path is required")
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
			return fmt.Errorf("Dungeon population artifact %s differs from pinned source", outPath)
		}
		return nil
	}
	file, err := os.CreateTemp(filepath.Dir(outPath), ".dungeon-population-*.json")
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
