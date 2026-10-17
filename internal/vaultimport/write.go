package vaultimport

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

func writeGenerated(outDir string, files map[string][]byte, check bool) error {
	return writeGeneratedFamily(ArrivalFamily, outDir, files, check)
}

func writeGeneratedFamily(
	family Family,
	outDir string,
	files map[string][]byte,
	check bool,
) error {
	if outDir == "" {
		return fmt.Errorf("vault output root is required")
	}

	paths := make([]string, 0, len(files))

	for path := range files {
		if !strings.HasPrefix(path, family.outputPath+"/") ||
			!strings.HasSuffix(path, ".des") {
			return fmt.Errorf("invalid generated vault path %q", path)
		}

		paths = append(paths, path)
	}

	slices.Sort(paths)

	for _, path := range paths {
		full := filepath.Join(outDir, filepath.FromSlash(path))

		if check {
			committed, err := os.ReadFile(full)

			if err != nil {
				return fmt.Errorf("read committed vault %s: %w", full, err)
			}

			if !bytes.Equal(committed, files[path]) {
				return fmt.Errorf("committed vault %s differs from pinned source", full)
			}

			continue
		}

		if err := os.MkdirAll(filepath.Dir(full), 0o755); err != nil {
			return err
		}

		file, err := os.CreateTemp(filepath.Dir(full), ".vault-*.des")

		if err != nil {
			return err
		}

		temp := file.Name()

		if _, err := file.Write(files[path]); err != nil {
			file.Close()
			os.Remove(temp)

			return err
		}

		if err := file.Close(); err != nil {
			os.Remove(temp)

			return err
		}

		if err := os.Rename(temp, full); err != nil {
			os.Remove(temp)

			return err
		}
	}

	familyDir := filepath.Join(outDir, filepath.FromSlash(family.outputPath))
	entries, err := os.ReadDir(familyDir)

	if err != nil {
		return fmt.Errorf("read generated vault directory: %w", err)
	}

	for _, entry := range entries {
		path := filepath.ToSlash(filepath.Join(family.outputPath, entry.Name()))

		if entry.IsDir() ||
			!strings.HasSuffix(entry.Name(), ".des") ||
			files[path] == nil {
			return fmt.Errorf("unexpected committed vault path %s", path)
		}
	}

	return nil
}
