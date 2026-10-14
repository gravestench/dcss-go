package monsterimport

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

const pinnedRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

var sourceNames = []string{
	"tag-version.h", "monster-type.h", "mon-data.h", "mon-util.h", "mon-enum.h",
	"mon-flags.h", "mon-holy-type.h", "size-type.h", "mon-mst.h", "defines.h", "colour.h",
}

func readSources(sourceDir string) (map[string][]byte, []content.JobSourceFile, error) {
	data := make(map[string][]byte, len(sourceNames))
	files := make([]content.JobSourceFile, 0, len(sourceNames))
	for _, name := range sourceNames {
		path := filepath.Join(sourceDir, name)
		body, err := os.ReadFile(path)
		if err != nil {
			return nil, nil, fmt.Errorf("read %s: %w", path, err)
		}
		data[name] = body
		hash := sha256.Sum256(body)
		files = append(files, content.JobSourceFile{
			Path:   "crawl-ref/source/" + name,
			SHA256: hex.EncodeToString(hash[:]),
		})
	}
	sort.Slice(files, func(i, j int) bool { return files[i].Path < files[j].Path })
	return data, files, nil
}

func enumMembers(path, name string, data []byte) (map[string]bool, error) {
	if name == "COLOURS" {
		start := bytes.Index(data, []byte("enum COLOURS"))
		if start < 0 {
			return nil, fmt.Errorf("%s: missing COLOURS", path)
		}
		end := bytes.Index(data[start:], []byte("};"))
		if end < 0 {
			return nil, fmt.Errorf("%s: unterminated COLOURS", path)
		}
		data = data[start : start+end+2]
	}
	activeSource, err := activeText(path, data)
	if err != nil {
		return nil, err
	}
	marker := regexp.MustCompile(`\benum\s+` + regexp.QuoteMeta(name) + `\b[^{}]*\{`)
	where := marker.FindStringIndex(activeSource)
	if where == nil {
		return nil, fmt.Errorf("%s: missing enum %s", path, name)
	}
	open := where[1] - 1
	inner, _, err := balanced(activeSource, open, '{', '}')
	if err != nil {
		return nil, fmt.Errorf("%s: enum %s: %w", path, name, err)
	}
	parts, err := splitFields(inner)
	if err != nil {
		return nil, fmt.Errorf("%s: enum %s: %w", path, name, err)
	}
	members := map[string]bool{}
	idPattern := regexp.MustCompile(`^[A-Z][A-Z0-9_]*$`)
	for _, part := range parts {
		id := strings.TrimSpace(strings.SplitN(part, "=", 2)[0])
		if !idPattern.MatchString(id) {
			return nil, fmt.Errorf("%s: enum %s has unsupported member %q", path, name, part)
		}
		if members[id] {
			return nil, fmt.Errorf("%s: enum %s duplicate %s", path, name, id)
		}
		members[id] = true
	}
	if len(members) == 0 {
		return nil, fmt.Errorf("%s: enum %s empty", path, name)
	}
	return members, nil
}

func monsterMembers(path string, data []byte) (map[string]bool, error) {
	activeSource, err := activeText(path, data)
	if err != nil {
		return nil, err
	}
	marker := regexp.MustCompile(`\benum\s+monster_type\b[^{}]*\{`)
	where := marker.FindStringIndex(activeSource)
	if where == nil {
		return nil, fmt.Errorf("%s: missing monster_type", path)
	}
	inner, _, err := balanced(activeSource, where[1]-1, '{', '}')
	if err != nil {
		return nil, err
	}
	parts, err := splitFields(inner)
	if err != nil {
		return nil, err
	}
	ids := map[string]bool{}
	for _, part := range parts {
		if strings.Contains(part, "=") {
			continue
		} // aliases and non-monster sentinels
		id := strings.TrimSpace(part)
		if !strings.HasPrefix(id, "MONS_") {
			continue
		}
		if ids[id] {
			return nil, fmt.Errorf("%s: duplicate monster enum %s", path, id)
		}
		ids[id] = true
	}
	if len(ids) == 0 {
		return nil, fmt.Errorf("%s: no active monster IDs", path)
	}
	return ids, nil
}

func activeText(path string, data []byte) (string, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, data)
	if err != nil {
		return "", err
	}
	var active strings.Builder
	for _, line := range lines {
		active.WriteString(line.Text)
		active.WriteByte('\n')
	}
	return active.String(), nil
}

func sourceSymbols(data map[string][]byte) (symbolSets, error) {
	from := func(file, name string) (map[string]bool, error) {
		return enumMembers("crawl-ref/source/"+file, name, data[file])
	}
	var s symbolSets
	var err error
	steps := []struct {
		target     *map[string]bool
		file, name string
	}{
		{&s.attackType, "mon-enum.h", "attack_type"}, {&s.attackFlavour, "mon-enum.h", "attack_flavour"},
		{&s.spellbook, "mon-mst.h", "mon_spellbook_type"}, {&s.classFlag, "mon-flags.h", "monclass_flag_type"},
		{&s.resistance, "mon-enum.h", "mon_resist_flags"}, {&s.holiness, "mon-holy-type.h", "mon_holy_type_flags"},
		{&s.shout, "mon-enum.h", "shout_type"}, {&s.intelligence, "mon-enum.h", "mon_intel_type"},
		{&s.habitat, "mon-enum.h", "habitat_type"}, {&s.itemUse, "mon-enum.h", "mon_itemuse_type"},
		{&s.size, "size-type.h", "size_type"}, {&s.shape, "mon-enum.h", "mon_body_shape"},
		{&s.colour, "defines.h", "COLOURS"}, {&s.tileVariation, "mon-util.h", "mon_type_tile_variation"},
	}
	for _, step := range steps {
		*step.target, err = from(step.file, step.name)
		if err != nil {
			return s, err
		}
	}
	elemental, err := from("colour.h", "element_type")
	if err != nil {
		return s, err
	}
	for id := range elemental {
		s.colour[id] = true
	}
	s.monster, err = monsterMembers("crawl-ref/source/monster-type.h", data["monster-type.h"])
	return s, err
}

func generateFromSource(sourceDir, revision string) ([]byte, error) {
	if revision != pinnedRevision {
		return nil, fmt.Errorf("source revision %s differs from pinned %s", revision, pinnedRevision)
	}
	data, files, err := readSources(sourceDir)
	if err != nil {
		return nil, err
	}
	if !bytes.Contains(data["tag-version.h"], []byte("#define TAG_MAJOR_VERSION 34")) {
		return nil, fmt.Errorf("%s: TAG_MAJOR_VERSION must be 34", filepath.Join(sourceDir, "tag-version.h"))
	}
	symbols, err := sourceSymbols(data)
	if err != nil {
		return nil, err
	}
	path := "crawl-ref/source/mon-data.h"
	rows, err := parseRows(path, data["mon-data.h"])
	if err != nil {
		return nil, err
	}
	defs, err := decodeRows(path, rows, symbols)
	if err != nil {
		return nil, err
	}
	byID := make(map[string]content.MonsterDef, len(symbols.monster))
	for _, def := range defs {
		if !symbols.monster[def.ID] {
			return nil, fmt.Errorf("%s:%d: %s is absent from active monster enum", path, def.SourceLine, def.ID)
		}
		if _, exists := byID[def.ID]; exists {
			return nil, fmt.Errorf("%s:%d: duplicate monster %s", path, def.SourceLine, def.ID)
		}
		byID[def.ID] = def
	}
	for id := range symbols.monster {
		if _, exists := byID[id]; !exists {
			byID[id] = content.MonsterDef{
				ID:         id,
				Status:     content.MonsterEnumOnly,
				SourcePath: "crawl-ref/source/monster-type.h",
			}
		}
	}
	artifact := content.MonsterArtifact{
		SchemaVersion:   1,
		SourceRevision:  revision,
		TagMajorVersion: 34,
		SourceFiles:     files,
	}
	for _, def := range byID {
		artifact.Monsters = append(artifact.Monsters, def)
	}
	sort.Slice(artifact.Monsters, func(i, j int) bool { return artifact.Monsters[i].ID < artifact.Monsters[j].ID })
	if err := artifact.Validate(); err != nil {
		return nil, err
	}
	encoded, err := json.MarshalIndent(artifact, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(encoded, '\n'), nil
}

// Generate is a developer-only import from the pinned, clean C++ checkout.
func Generate(sourceDir string) ([]byte, error) {
	if sourceDir == "" {
		return nil, fmt.Errorf("source directory is required")
	}
	revision, err := exec.Command("git", "-C", sourceDir, "rev-parse", "HEAD").Output()
	if err != nil {
		return nil, fmt.Errorf("source revision: %w", err)
	}
	if strings.TrimSpace(string(revision)) != pinnedRevision {
		return nil, fmt.Errorf("source revision %s differs from pinned %s", strings.TrimSpace(string(revision)), pinnedRevision)
	}
	args := append([]string{"-C", sourceDir, "status", "--porcelain", "--untracked-files=no", "--"}, sourceNames...)
	status, err := exec.Command("git", args...).Output()
	if err != nil {
		return nil, fmt.Errorf("source status: %w", err)
	}
	if len(bytes.TrimSpace(status)) != 0 {
		return nil, fmt.Errorf("tracked monster sources have local changes: %s", strings.TrimSpace(string(status)))
	}
	data, err := generateFromSource(sourceDir, pinnedRevision)
	if err != nil {
		return nil, err
	}
	var artifact content.MonsterArtifact
	if err := json.Unmarshal(data, &artifact); err != nil {
		return nil, err
	}
	counts := map[content.MonsterStatus]int{}
	for _, def := range artifact.Monsters {
		counts[def.Status]++
	}
	if len(artifact.Monsters) != 700 || counts[content.MonsterDefined] != 562 || counts[content.MonsterRemoved] != 120 || counts[content.MonsterEnumOnly] != 18 {
		return nil, fmt.Errorf("monster partition changed: total=%d defined=%d removed=%d enum_only=%d", len(artifact.Monsters), counts[content.MonsterDefined], counts[content.MonsterRemoved], counts[content.MonsterEnumOnly])
	}
	return data, nil
}

func writeArtifact(sourceDir, outPath string, check bool, generate func(string) ([]byte, error)) error {
	if outPath == "" {
		return fmt.Errorf("output path is required")
	}
	data, err := generate(sourceDir)
	if err != nil {
		return err
	}
	if check {
		current, err := os.ReadFile(outPath)
		if err != nil {
			return err
		}
		if !bytes.Equal(current, data) {
			return fmt.Errorf("artifact %s is stale", outPath)
		}
		return nil
	}
	file, err := os.CreateTemp(filepath.Dir(outPath), ".monsters-*.tmp")
	if err != nil {
		return err
	}
	temp := file.Name()
	defer os.Remove(temp)
	if _, err := file.Write(data); err != nil {
		file.Close()
		return err
	}
	if err := file.Sync(); err != nil {
		file.Close()
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}
	if err := os.Rename(temp, outPath); err != nil {
		return err
	}
	return nil
}

func sortedKeys(values map[string]bool) []string {
	result := make([]string, 0, len(values))
	for id := range values {
		result = append(result, id)
	}
	sort.Strings(result)
	return result
}

// GenerateManifest records the pinned IDs, statuses, and enum vocabulary
// independently of the monster definitions for runtime validation.
func GenerateManifest(sourceDir string) ([]byte, error) {
	definitions, err := Generate(sourceDir)
	if err != nil {
		return nil, err
	}
	var artifact content.MonsterArtifact
	if err := json.Unmarshal(definitions, &artifact); err != nil {
		return nil, err
	}
	data, _, err := readSources(sourceDir)
	if err != nil {
		return nil, err
	}
	s, err := sourceSymbols(data)
	if err != nil {
		return nil, err
	}
	v := content.MonsterVocabulary{
		SchemaVersion:   1,
		SourceRevision:  pinnedRevision,
		TagMajorVersion: 34,
		SourceFiles:     artifact.SourceFiles,
		Symbols: map[string][]string{
			"attack_type":    sortedKeys(s.attackType),
			"attack_flavour": sortedKeys(s.attackFlavour),
			"spellbook":      sortedKeys(s.spellbook),
			"class_flag":     sortedKeys(s.classFlag),
			"resistance":     sortedKeys(s.resistance),
			"holiness":       sortedKeys(s.holiness),
			"shout":          sortedKeys(s.shout),
			"intelligence":   sortedKeys(s.intelligence),
			"habitat":        sortedKeys(s.habitat),
			"item_use":       sortedKeys(s.itemUse),
			"size":           sortedKeys(s.size),
			"shape":          sortedKeys(s.shape),
			"colour":         sortedKeys(s.colour),
			"tile_variation": sortedKeys(s.tileVariation),
		},
	}
	for _, monster := range artifact.Monsters {
		v.Identities = append(v.Identities, content.MonsterIdentity{
			ID:     monster.ID,
			Status: monster.Status,
		})
	}
	if err := v.ValidateArtifact(artifact); err != nil {
		return nil, err
	}
	encoded, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(encoded, '\n'), nil
}

// Write checks or atomically replaces the committed generated artifacts.
func Write(sourceDir, outPath string, check bool) error {
	if outPath == "" {
		return fmt.Errorf("output path is required")
	}
	definitions, err := Generate(sourceDir)
	if err != nil {
		return err
	}
	vocabulary, err := GenerateManifest(sourceDir)
	if err != nil {
		return err
	}
	manifestPath := filepath.Join(filepath.Dir(outPath), "monster-vocabulary.json")
	if check {
		for _, entry := range []struct {
			path     string
			expected []byte
		}{{outPath, definitions}, {manifestPath, vocabulary}} {
			actual, err := os.ReadFile(entry.path)
			if err != nil {
				return err
			}
			if !bytes.Equal(actual, entry.expected) {
				return fmt.Errorf("artifact %s is stale", entry.path)
			}
		}
		return nil
	}
	if err := writeArtifact(sourceDir, outPath, false, func(string) ([]byte, error) { return definitions, nil }); err != nil {
		return err
	}
	return writeArtifact(sourceDir, manifestPath, false, func(string) ([]byte, error) { return vocabulary, nil })
}
