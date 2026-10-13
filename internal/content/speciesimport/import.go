package speciesimport

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
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

const pinnedRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

var tagMajor = regexp.MustCompile(`(?m)^#define\s+TAG_MAJOR_VERSION\s+(\d+)\s*$`)

func sourcePath(sourceDir, path string) (string, error) {
	relative, err := filepath.Rel(sourceDir, path)
	if err != nil || strings.HasPrefix(relative, "..") {
		return "", fmt.Errorf("source path %s is outside %s", path, sourceDir)
	}
	return filepath.ToSlash(filepath.Join("crawl-ref", "source", relative)), nil
}

func readSource(sourceDir, relative string, hashes *[]content.SpeciesSourceFile) ([]byte, string, error) {
	path := filepath.Join(sourceDir, relative)
	label, err := sourcePath(sourceDir, path)
	if err != nil {
		return nil, "", err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, "", fmt.Errorf("%s: %w", label, err)
	}
	sum := sha256.Sum256(data)
	*hashes = append(*hashes, content.SpeciesSourceFile{Path: label, SHA256: hex.EncodeToString(sum[:])})
	return data, label, nil
}

func generateFromSource(sourceDir, revision string) ([]byte, error) {
	if revision != pinnedRevision {
		return nil, fmt.Errorf("source revision %s differs from pinned %s", revision, pinnedRevision)
	}
	var files []content.SpeciesSourceFile
	version, versionPath, err := readSource(sourceDir, "tag-version.h", &files)
	if err != nil {
		return nil, err
	}
	match := tagMajor.FindSubmatch(version)
	if match == nil {
		return nil, fmt.Errorf("%s: TAG_MAJOR_VERSION definition missing", versionPath)
	}
	major, err := strconv.Atoi(string(match[1]))
	if err != nil || major != 34 {
		return nil, fmt.Errorf("%s: TAG_MAJOR_VERSION must be 34, got %s", versionPath, match[1])
	}
	speciesHeader, speciesHeaderPath, err := readSource(sourceDir, "species-type.h", &files)
	if err != nil {
		return nil, err
	}
	monsterHeader, monsterHeaderPath, err := readSource(sourceDir, "monster-type.h", &files)
	if err != nil {
		return nil, err
	}
	jobHeader, jobHeaderPath, err := readSource(sourceDir, "job-type.h", &files)
	if err != nil {
		return nil, err
	}
	speciesIDs, err := sourceparse.ActiveEnumIDs(speciesHeaderPath, speciesHeader, "SP_")
	if err != nil {
		return nil, err
	}
	monsterIDs, err := sourceparse.ActiveEnumIDs(monsterHeaderPath, monsterHeader, "MONS_")
	if err != nil {
		return nil, err
	}
	jobIDs, err := sourceparse.ActiveEnumIDs(jobHeaderPath, jobHeader, "JOB_")
	if err != nil {
		return nil, err
	}
	yamlFiles, err := filepath.Glob(filepath.Join(sourceDir, "dat", "species", "*.yaml"))
	if err != nil {
		return nil, fmt.Errorf("species YAML glob: %w", err)
	}
	if len(yamlFiles) == 0 {
		return nil, fmt.Errorf("%s: no species YAML files", sourceDir)
	}
	sort.Strings(yamlFiles)
	var definitions []content.SpeciesDef
	seen := map[string]string{}
	for _, path := range yamlFiles {
		relative, err := filepath.Rel(sourceDir, path)
		if err != nil {
			return nil, err
		}
		data, label, err := readSource(sourceDir, relative, &files)
		if err != nil {
			return nil, err
		}
		species, tag, err := parseYAML(label, data)
		if err != nil {
			return nil, err
		}
		if tag != 0 && tag != 34 {
			return nil, fmt.Errorf("%s: unsupported TAG_MAJOR_VERSION %d", label, tag)
		}
		if earlier, duplicate := seen[species.ID]; duplicate {
			return nil, fmt.Errorf("%s: duplicate species %s also in %s", label, species.ID, earlier)
		}
		seen[species.ID] = label
		definitions = append(definitions, species)
	}
	legacySpecies, legacySpeciesPath, err := readSource(sourceDir, "util/species-gen/species-data-deprecated-species.txt", &files)
	if err != nil {
		return nil, err
	}
	legacyAptitudes, legacyAptitudesPath, err := readSource(sourceDir, "util/species-gen/aptitudes-deprecated-species.txt", &files)
	if err != nil {
		return nil, err
	}
	legacy, err := parseLegacy(legacySpeciesPath, legacySpecies, legacyAptitudesPath, legacyAptitudes)
	if err != nil {
		return nil, err
	}
	for _, species := range legacy {
		if earlier, duplicate := seen[species.ID]; duplicate {
			return nil, fmt.Errorf("%s: duplicate species %s also in %s", species.SourcePath, species.ID, earlier)
		}
		seen[species.ID] = species.SourcePath
		definitions = append(definitions, species)
	}
	for id := range speciesIDs {
		if _, present := seen[id]; !present {
			return nil, fmt.Errorf("%s: active species %s has no definition", speciesHeaderPath, id)
		}
	}
	for _, species := range definitions {
		if _, active := speciesIDs[species.ID]; !active {
			return nil, fmt.Errorf("%s: species %s is not active in %s", species.SourcePath, species.ID, speciesHeaderPath)
		}
		if _, active := monsterIDs[species.MonsterID]; !active {
			return nil, fmt.Errorf("%s: %s has unknown monster %s", species.SourcePath, species.ID, species.MonsterID)
		}
		for _, job := range species.RecommendedJobs {
			if _, active := jobIDs[job]; !active {
				return nil, fmt.Errorf("%s: %s has unknown recommended job %s", species.SourcePath, species.ID, job)
			}
		}
	}
	sort.Slice(definitions, func(i, j int) bool { return definitions[i].ID < definitions[j].ID })
	sort.Slice(files, func(i, j int) bool { return files[i].Path < files[j].Path })
	artifact := content.SpeciesArtifact{SchemaVersion: 1, SourceRevision: revision, TagMajorVersion: 34, SourceFiles: files, Species: definitions}
	if err := artifact.Validate(); err != nil {
		return nil, err
	}
	encoded, err := json.MarshalIndent(artifact, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("encode species artifact: %w", err)
	}
	return append(encoded, '\n'), nil
}

// Generate reads a pinned C++ checkout and returns deterministic artifact bytes.
func Generate(sourceDir string) ([]byte, error) {
	if sourceDir == "" {
		return nil, fmt.Errorf("source directory is required")
	}
	cmd := exec.Command("git", "-C", sourceDir, "rev-parse", "HEAD")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("read source Git revision: %w", err)
	}
	revision := strings.TrimSpace(string(output))
	if revision != pinnedRevision {
		return nil, fmt.Errorf("source revision %s differs from pinned %s", revision, pinnedRevision)
	}
	cmd = exec.Command("git", "-C", sourceDir, "diff", "--quiet", "HEAD", "--", ".")
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("source checkout has modified tracked files under %s: %w", sourceDir, err)
	}
	return generateFromSource(sourceDir, revision)
}

func writeArtifact(sourceDir, outPath string, check bool, generate func(string) ([]byte, error)) error {
	data, err := generate(sourceDir)
	if err != nil {
		return err
	}
	if check {
		current, err := os.ReadFile(outPath)
		if err != nil {
			return fmt.Errorf("read checked-in artifact %s: %w", outPath, err)
		}
		if !bytes.Equal(current, data) {
			return fmt.Errorf("artifact %s is stale; regenerate without -check", outPath)
		}
		return nil
	}
	file, err := os.CreateTemp(filepath.Dir(outPath), "."+filepath.Base(outPath)+".tmp-*")
	if err != nil {
		return fmt.Errorf("create artifact temp file: %w", err)
	}
	tempPath := file.Name()
	defer os.Remove(tempPath)
	if _, err := file.Write(data); err != nil {
		file.Close()
		return fmt.Errorf("write artifact: %w", err)
	}
	if err := file.Sync(); err != nil {
		file.Close()
		return fmt.Errorf("sync artifact: %w", err)
	}
	if err := file.Close(); err != nil {
		return fmt.Errorf("close artifact: %w", err)
	}
	if err := os.Rename(tempPath, outPath); err != nil {
		return fmt.Errorf("replace artifact %s: %w", outPath, err)
	}
	return nil
}

// Write generates or verifies a species artifact without changing the source checkout.
func Write(sourceDir, outPath string, check bool) error {
	if outPath == "" {
		return fmt.Errorf("output path is required")
	}
	return writeArtifact(sourceDir, outPath, check, Generate)
}
