package startinggearimport

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

func readKindSource(root, name string) ([]byte, string, error) {
	path := filepath.Join(root, name)
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, path, fmt.Errorf("%s: %w", path, err)
	}
	return data, path, nil
}

func activeEgoIDs(path string, data []byte) (map[string]struct{}, error) {
	lines, err := sourceparse.Tag34Lines(path, data)
	if err != nil {
		return nil, err
	}
	ids := map[string]struct{}{}
	state := 0
	for _, line := range lines {
		line = strings.TrimSpace(strings.SplitN(line, "//", 2)[0])
		if state == 0 {
			if strings.HasPrefix(line, "enum special_missile_type") {
				state = 1
				if strings.Contains(line, "{") {
					state = 2
				}
			}
			continue
		}
		if state == 1 {
			if line != "{" {
				return nil, fmt.Errorf("%s: special_missile_type lacks opening brace", path)
			}
			state = 2
			continue
		}
		if strings.HasPrefix(line, "}") {
			state = 3
			break
		}
		id := strings.TrimSpace(strings.SplitN(strings.TrimSuffix(line, ","), "=", 2)[0])
		if !strings.HasPrefix(id, "SPMSL_") {
			continue
		}
		if _, found := ids[id]; found {
			return nil, fmt.Errorf("%s: duplicate missile ego %s", path, id)
		}
		ids[id] = struct{}{}
	}
	if state != 3 || len(ids) == 0 {
		return nil, fmt.Errorf("%s: no complete special_missile_type enum", path)
	}
	return ids, nil
}

// resolveKinds resolves starter names against the committed complete catalog.
func resolveKinds(catalog content.Catalog, names []string) (map[string]content.ItemDef, error) {
	wanted := map[string]bool{}
	for _, name := range names {
		wanted[name] = true
	}
	resolved := make(map[string]content.ItemDef, len(wanted))
	for _, id := range catalog.ItemIDs() {
		kind, err := catalog.Item(id)
		if err != nil {
			continue
		} // enum-only legacy identity
		if !wanted[kind.Name] {
			continue
		}
		if previous, found := resolved[kind.Name]; found {
			return nil, fmt.Errorf("ambiguous item name %q for %s and %s", kind.Name, previous.ID, kind.ID)
		}
		resolved[kind.Name] = kind
	}
	for name := range wanted {
		if _, found := resolved[name]; !found {
			return nil, fmt.Errorf("unknown item name %q in committed catalog", name)
		}
	}
	for name, kind := range resolved {
		if kind.ExplicitlyRemoved || strings.HasPrefix(kind.Name, "removed ") {
			return nil, fmt.Errorf("starting item %q (%s) is removed", name, kind.ID)
		}
	}
	return resolved, nil
}
