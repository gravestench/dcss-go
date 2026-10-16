package vaultimport

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type portRecipe struct {
	ID         string     `json:"id"`
	SourceFile string     `json:"source_file"`
	Edits      []portEdit `json:"edits"`
}

type portEdit struct {
	StartLine int    `json:"start_line"`
	EndLine   int    `json:"end_line"`
	SHA256    string `json:"sha256"`
	Method    string `json:"method"`
	Stage     string `json:"stage"`
}

func loadPorts(dir string) (map[string]portRecipe, error) {
	entries, err := os.ReadDir(dir)

	if err != nil {
		return nil, fmt.Errorf("read vault port recipes: %w", err)
	}

	ports := make(map[string]portRecipe, len(entries))

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".json") {
			return nil, fmt.Errorf("unexpected vault port recipe %q", entry.Name())
		}

		path := filepath.Join(dir, entry.Name())
		body, err := os.ReadFile(path)

		if err != nil {
			return nil, fmt.Errorf("read %s: %w", path, err)
		}

		var recipe portRecipe

		if err := json.Unmarshal(body, &recipe); err != nil {
			return nil, fmt.Errorf("decode %s: %w", path, err)
		}

		if recipe.ID == "" || entry.Name() != recipe.ID+".json" {
			return nil, fmt.Errorf("vault port recipe %s has mismatched ID %q", path, recipe.ID)
		}

		ports[recipe.ID] = recipe
	}

	return ports, nil
}
