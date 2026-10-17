// Package vaultimport splits pinned DCSS vault collections into committed
// one-vault DES files. It runs only for an intentional upstream refresh.
package vaultimport

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"slices"
)

const SourceRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

// Generate reads the pinned source and returns effective mod-relative paths.
func Generate(sourceDir, portsDir string) (map[string][]byte, error) {
	return GenerateFamily(ArrivalFamily, sourceDir, portsDir)
}

// GenerateFamily reads one pinned family for a deliberate content refresh.
func GenerateFamily(
	family Family,
	sourceDir, portsDir string,
) (map[string][]byte, error) {
	if sourceDir == "" || portsDir == "" {
		return nil, fmt.Errorf("source and port recipe directories are required")
	}

	ports, err := loadPorts(portsDir)

	if err != nil {
		return nil, err
	}

	names := make([]string, 0, len(family.sourceFiles))

	for name := range family.sourceFiles {
		names = append(names, name)
	}

	slices.Sort(names)
	output := make(map[string][]byte)
	usedPorts := make(map[string]bool)

	for _, name := range names {
		path := filepath.Join(sourceDir, name)
		body, err := os.ReadFile(path)

		if err != nil {
			return nil, fmt.Errorf("read %s: %w", path, err)
		}

		sum := sha256.Sum256(body)

		if hex.EncodeToString(sum[:]) != family.sourceFiles[name] {
			return nil, fmt.Errorf("%s differs from pinned source %s", path, SourceRevision)
		}

		files, err := splitSourceFamily(family, name, body, ports)

		if err != nil {
			return nil, err
		}

		for filePath, data := range files {
			if _, duplicate := output[filePath]; duplicate {
				return nil, fmt.Errorf("duplicate vault output %s", filePath)
			}

			output[filePath] = data
			usedPorts[filePath] = true
		}
	}

	for id := range ports {
		if !usedPorts[filepath.Join(family.outputPath, id+".des")] {
			return nil, fmt.Errorf("port recipe %s has no source vault", id)
		}
	}

	if len(output) != family.wantNames {
		return nil, fmt.Errorf("%s source has %d vaults, want %d",
			family.name, len(output), family.wantNames)
	}

	return output, nil
}

// Write writes a deliberate refresh or checks the committed effective files.
func Write(sourceDir, portsDir, outDir string, check bool) error {
	return WriteFamily(ArrivalFamily, sourceDir, portsDir, outDir, check)
}

// WriteFamily refreshes or checks one committed vault family.
func WriteFamily(
	family Family,
	sourceDir, portsDir, outDir string,
	check bool,
) error {
	files, err := GenerateFamily(family, sourceDir, portsDir)

	if err != nil {
		return err
	}

	return writeGeneratedFamily(family, outDir, files, check)
}
