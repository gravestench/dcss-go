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

	if err != nil ||
		strings.HasPrefix(relative, "..") {
		return "", fmt.Errorf("source path %s is outside %s", path, sourceDir)
	}

	return filepath.ToSlash(filepath.Join("crawl-ref", "source", relative)), nil
}

func readSource(sourceDir, relative string,
	hashes *[]content.SpeciesSourceFile,
) ([]byte, string, error) {
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

	*hashes = append(*hashes, content.SpeciesSourceFile{
		Path:   label,
		SHA256: hex.EncodeToString(sum[:]),
	})

	return data, label, nil
}

// speciesImport owns only one developer-run content refresh. Its source order
// is significant until the final artifact is sorted and validated.
type speciesImport struct {
	sourceDir         string
	speciesHeaderPath string

	files       []content.SpeciesSourceFile
	definitions []content.SpeciesDef
	seen        map[string]string

	speciesIDs map[string]struct{}
	monsterIDs map[string]struct{}
	jobIDs     map[string]struct{}
}

func generateFromSource(sourceDir, revision string) ([]byte, error) {
	if revision != pinnedRevision {
		return nil, fmt.Errorf("source revision %s differs from pinned %s", revision, pinnedRevision)
	}

	importer := speciesImport{
		sourceDir: sourceDir,
		seen:      make(map[string]string),
	}

	if err := importer.readHeaders(); err != nil {
		return nil, err
	}

	if err := importer.readYAML(); err != nil {
		return nil, err
	}

	if err := importer.readLegacy(); err != nil {
		return nil, err
	}

	if err := importer.validateReferences(); err != nil {
		return nil, err
	}

	return importer.encode(revision)
}

func (i *speciesImport) readHeaders() error {
	version, versionPath, err := readSource(i.sourceDir, "tag-version.h", &i.files)

	if err != nil {
		return err
	}

	match := tagMajor.FindSubmatch(version)

	if match == nil {
		return fmt.Errorf("%s: TAG_MAJOR_VERSION definition missing", versionPath)
	}

	major, err := strconv.Atoi(string(match[1]))

	if err != nil ||
		major != 34 {
		return fmt.Errorf("%s: TAG_MAJOR_VERSION must be 34, got %s", versionPath, match[1])
	}

	speciesHeader, speciesPath, err := readSource(i.sourceDir, "species-type.h", &i.files)

	if err != nil {
		return err
	}

	monsterHeader, monsterPath, err := readSource(i.sourceDir, "monster-type.h", &i.files)

	if err != nil {
		return err
	}

	jobHeader, jobPath, err := readSource(i.sourceDir, "job-type.h", &i.files)

	if err != nil {
		return err
	}

	i.speciesIDs, err = sourceparse.ActiveEnumIDs(speciesPath, speciesHeader, "SP_")

	if err != nil {
		return err
	}

	i.monsterIDs, err = sourceparse.ActiveEnumIDs(monsterPath, monsterHeader, "MONS_")

	if err != nil {
		return err
	}

	i.jobIDs, err = sourceparse.ActiveEnumIDs(jobPath, jobHeader, "JOB_")

	if err != nil {
		return err
	}

	i.speciesHeaderPath = speciesPath

	return nil
}

func (i *speciesImport) readYAML() error {
	yamlFiles, err := filepath.Glob(filepath.Join(i.sourceDir, "dat", "species", "*.yaml"))

	if err != nil {
		return fmt.Errorf("species YAML glob: %w", err)
	}

	if len(yamlFiles) == 0 {
		return fmt.Errorf("%s: no species YAML files", i.sourceDir)
	}

	sort.Strings(yamlFiles)

	for _, path := range yamlFiles {
		relative, err := filepath.Rel(i.sourceDir, path)

		if err != nil {
			return err
		}

		data, label, err := readSource(i.sourceDir, relative, &i.files)

		if err != nil {
			return err
		}

		species, tag, err := parseYAML(label, data)

		if err != nil {
			return err
		}

		if tag != 0 && tag != 34 {
			return fmt.Errorf("%s: unsupported TAG_MAJOR_VERSION %d", label, tag)
		}

		if err := i.addSpecies(species, label); err != nil {
			return err
		}
	}

	return nil
}

func (i *speciesImport) readLegacy() error {
	speciesData, speciesPath, err := readSource(
		i.sourceDir,
		"util/species-gen/species-data-deprecated-species.txt",
		&i.files,
	)

	if err != nil {
		return err
	}

	aptitudeData, aptitudePath, err := readSource(
		i.sourceDir,
		"util/species-gen/aptitudes-deprecated-species.txt",
		&i.files,
	)

	if err != nil {
		return err
	}

	legacy, err := parseLegacy(speciesPath, speciesData, aptitudePath, aptitudeData)

	if err != nil {
		return err
	}

	for _, species := range legacy {
		if err := i.addSpecies(species, species.SourcePath); err != nil {
			return err
		}
	}

	return nil
}

func (i *speciesImport) addSpecies(species content.SpeciesDef, label string) error {
	if earlier, duplicate := i.seen[species.ID]; duplicate {
		return fmt.Errorf("%s: duplicate species %s also in %s", label, species.ID, earlier)
	}

	i.seen[species.ID] = label
	i.definitions = append(i.definitions, species)

	return nil
}

func (i *speciesImport) validateReferences() error {
	for id := range i.speciesIDs {
		if _, present := i.seen[id]; !present {
			return fmt.Errorf("%s: active species %s has no definition", i.speciesHeaderPath, id)
		}
	}

	for _, species := range i.definitions {
		if _, active := i.speciesIDs[species.ID]; !active {
			return fmt.Errorf("%s: species %s is not active in %s",
				species.SourcePath, species.ID, i.speciesHeaderPath)
		}

		if _, active := i.monsterIDs[species.MonsterID]; !active {
			return fmt.Errorf("%s: %s has unknown monster %s",
				species.SourcePath, species.ID, species.MonsterID)
		}

		for _, job := range species.RecommendedJobs {
			if _, active := i.jobIDs[job]; !active {
				return fmt.Errorf("%s: %s has unknown recommended job %s",
					species.SourcePath, species.ID, job)
			}
		}
	}

	return nil
}

func (i *speciesImport) encode(revision string) ([]byte, error) {
	sort.Slice(i.definitions, func(first, second int) bool {
		return i.definitions[first].ID < i.definitions[second].ID
	})

	sort.Slice(i.files, func(first, second int) bool {
		return i.files[first].Path < i.files[second].Path
	})

	artifact := content.SpeciesArtifact{
		SchemaVersion:   1,
		SourceRevision:  revision,
		TagMajorVersion: 34,
		SourceFiles:     i.files,
		Species:         i.definitions,
	}

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
		return nil, fmt.Errorf("source checkout has modified tracked files under %s: %w",
			sourceDir, err)
	}

	return generateFromSource(sourceDir, revision)
}

func writeArtifact(sourceDir, outPath string, check bool,
	generate func(string) ([]byte, error),
) error {
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
