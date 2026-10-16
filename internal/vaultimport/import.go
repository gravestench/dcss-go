// Package vaultimport splits pinned DCSS arrival collections into committed
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

var sourceFiles = map[string]string{
	"large.des":   "5ae5d53469dc5713c70a3c1a35e82d8b0807e038585225f9b5e8d9ecab91880b",
	"simple.des":  "9c1dcfac919d6ac52725692ca1a7f200909ace1f7be2c626db314c03de02d1d5",
	"small.des":   "65a73745881c73d1f861d70efc3aa5f1f9643914c1ceba5f5834e9abb0761847",
	"twisted.des": "4dbe0cf3c64a8d61ea22c8267aa0eeea3671ca75e40a2cd0c58b029a6f9a4e0d",
}

// Generate reads the pinned source and returns effective mod-relative paths.
func Generate(sourceDir, portsDir string) (map[string][]byte, error) {
	if sourceDir == "" || portsDir == "" {
		return nil, fmt.Errorf("source and port recipe directories are required")
	}

	ports, err := loadPorts(portsDir)

	if err != nil {
		return nil, err
	}

	names := make([]string, 0, len(sourceFiles))

	for name := range sourceFiles {
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

		if hex.EncodeToString(sum[:]) != sourceFiles[name] {
			return nil, fmt.Errorf("%s differs from pinned source %s", path, SourceRevision)
		}

		files, err := splitSource(name, body, ports)

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
		if !usedPorts[filepath.Join("vaults", "arrival", id+".des")] {
			return nil, fmt.Errorf("port recipe %s has no source vault", id)
		}
	}

	if len(output) != 339 {
		return nil, fmt.Errorf("arrival source has %d vaults, want 339", len(output))
	}

	return output, nil
}

// Write writes a deliberate refresh or checks the committed effective files.
func Write(sourceDir, portsDir, outDir string, check bool) error {
	files, err := Generate(sourceDir, portsDir)

	if err != nil {
		return err
	}

	return writeGenerated(outDir, files, check)
}
