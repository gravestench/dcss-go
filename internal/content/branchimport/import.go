package branchimport

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

var sourceNames = []string{"tag-version.h", "branch-type.h", "branch-data.h"}

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
	ids, err := parseEnum("branch-type.h", sources["branch-type.h"])

	if err != nil {
		return nil, err
	}

	rows, err := parseTable("branch-data.h", sources["branch-data.h"])

	if err != nil {
		return nil, err
	}

	if err := reconcile(ids, rows); err != nil {
		return nil, err
	}

	for i := range rows {
		rows[i].NumericID, rows[i].EnumLine = ids[i].NumericID, ids[i].EnumLine
	}

	artifact := content.BranchArtifact{
		SchemaVersion:   1,
		SourceRevision:  pinnedRevision,
		TagMajorVersion: 34,
		SourceFiles:     files,
		Branches:        rows,
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
		return fmt.Errorf("branch output path is required")
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
			return fmt.Errorf("branch artifact %s differs from pinned source", outPath)
		}

		return nil
	}

	file, err := os.CreateTemp(filepath.Dir(outPath), ".branches-*.json")

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
