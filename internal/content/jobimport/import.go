package jobimport

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

var skillEntry = regexp.MustCompile(`^\s*(SK_[A-Z_]+)\s*,`)

func readJobSource(root, name string, files *[]content.JobSourceFile) ([]byte, string, error) {
	path := filepath.Join(root, name)
	data, err := os.ReadFile(path)
	label := filepath.ToSlash(filepath.Join("crawl-ref", "source", name))

	if err != nil {
		return nil, "", fmt.Errorf("%s: %w", label, err)
	}

	sum := sha256.Sum256(data)
	*files = append(*files, content.JobSourceFile{
		Path:   label,
		SHA256: hex.EncodeToString(sum[:]),
	})

	return data, label, nil
}

func ordinaryJobSkills(path string, data []byte) (map[string]struct{}, error) {
	all, err := sourceparse.ActiveEnumIDs(path, data, "SK_")

	if err != nil {
		return nil, err
	}

	lines, err := sourceparse.Tag34Lines(path, data)

	if err != nil {
		return nil, err
	}

	allowed := map[string]struct{}{}

	for _, line := range lines {
		if strings.Contains(line, "NUM_SKILLS") {
			break
		}

		if match := skillEntry.FindStringSubmatch(line); match != nil {
			if _, active := all[match[1]]; active {
				allowed[match[1]] = struct{}{}
			}
		}
	}

	if _, found := all["SK_WEAPON"]; !found || len(allowed) == 0 {
		return nil, fmt.Errorf("%s: missing ordinary skills or SK_WEAPON", path)
	}

	allowed["SK_WEAPON"] = struct{}{}

	return allowed, nil
}

// jobImport holds source bytes, identity sets, and definitions for one refresh.
// The runtime reads the committed artifact and never owns this state.
type jobImport struct {
	sourceDir     string
	files         []content.JobSourceFile
	jobHeaderPath string

	jobIDs     map[string]struct{}
	speciesIDs map[string]struct{}
	spellIDs   map[string]struct{}
	skillIDs   map[string]struct{}
	jobs       []content.JobDef
}

func generateFromSource(sourceDir, revision string) ([]byte, error) {
	if revision != pinnedRevision {
		return nil, fmt.Errorf("source revision %s differs from pinned %s", revision, pinnedRevision)
	}

	importer := jobImport{sourceDir: sourceDir}

	if err := importer.readVersion(); err != nil {
		return nil, err
	}

	if err := importer.readTables(); err != nil {
		return nil, err
	}

	if err := importer.validateJobs(); err != nil {
		return nil, err
	}

	return importer.encode(revision)
}

func (i *jobImport) readVersion() error {
	version, path, err := readJobSource(i.sourceDir, "tag-version.h", &i.files)

	if err != nil {
		return err
	}

	match := tagMajor.FindSubmatch(version)

	if match == nil {
		return fmt.Errorf("%s: TAG_MAJOR_VERSION definition missing", path)
	}

	major, err := strconv.Atoi(string(match[1]))

	if err != nil ||
		major != 34 {
		return fmt.Errorf("%s: TAG_MAJOR_VERSION must be 34, got %s", path, match[1])
	}

	return nil
}

func (i *jobImport) readTables() error {
	jobData, jobDataPath, err := readJobSource(i.sourceDir, "job-data.h", &i.files)

	if err != nil {
		return err
	}

	jobHeader, jobPath, err := readJobSource(i.sourceDir, "job-type.h", &i.files)

	if err != nil {
		return err
	}

	speciesHeader, speciesPath, err := readJobSource(i.sourceDir, "species-type.h", &i.files)

	if err != nil {
		return err
	}

	spellHeader, spellPath, err := readJobSource(i.sourceDir, "spell-type.h", &i.files)

	if err != nil {
		return err
	}

	skillHeader, skillPath, err := readJobSource(i.sourceDir, "skill-type.h", &i.files)

	if err != nil {
		return err
	}

	i.jobIDs, err = sourceparse.ActiveEnumIDs(jobPath, jobHeader, "JOB_")

	if err != nil {
		return err
	}

	delete(i.jobIDs, "JOB_RANDOM")
	delete(i.jobIDs, "JOB_VIABLE")

	i.speciesIDs, err = sourceparse.ActiveEnumIDs(speciesPath, speciesHeader, "SP_")

	if err != nil {
		return err
	}

	i.spellIDs, err = sourceparse.ActiveEnumIDs(spellPath, spellHeader, "SPELL_")

	if err != nil {
		return err
	}

	delete(i.spellIDs, "SPELL_NO_SPELL")
	delete(i.spellIDs, "SPELL_MELEE")

	i.skillIDs, err = ordinaryJobSkills(skillPath, skillHeader)

	if err != nil {
		return err
	}

	i.jobHeaderPath = jobPath
	i.jobs, err = parseJobData(jobDataPath, jobData)

	return err
}

func (i *jobImport) validateJobs() error {
	seen := make(map[string]bool, len(i.jobs))

	for _, job := range i.jobs {
		if _, active := i.jobIDs[job.ID]; !active {
			return fmt.Errorf("%s: job %s is not an active concrete job", job.SourcePath, job.ID)
		}

		seen[job.ID] = true

		for _, species := range job.RecommendedSpecies {
			if _, active := i.speciesIDs[species]; !active {
				return fmt.Errorf("%s: %s has unknown recommended species %s", job.SourcePath, job.ID, species)
			}
		}

		for _, spell := range job.Spells {
			if _, active := i.spellIDs[spell]; !active {
				return fmt.Errorf("%s: %s has unknown spell %s", job.SourcePath, job.ID, spell)
			}
		}

		for _, grant := range job.Skills {
			if _, active := i.skillIDs[grant.ID]; !active {
				return fmt.Errorf("%s: %s has unknown skill %s", job.SourcePath, job.ID, grant.ID)
			}
		}
	}

	for id := range i.jobIDs {
		if !seen[id] {
			return fmt.Errorf("%s: active job %s has no definition", i.jobHeaderPath, id)
		}
	}

	return nil
}

func (i *jobImport) encode(revision string) ([]byte, error) {
	sort.Slice(i.jobs, func(first, second int) bool {
		return i.jobs[first].ID < i.jobs[second].ID
	})

	sort.Slice(i.files, func(first, second int) bool {
		return i.files[first].Path < i.files[second].Path
	})

	artifact := content.JobArtifact{
		SchemaVersion:   1,
		SourceRevision:  revision,
		TagMajorVersion: 34,
		SourceFiles:     i.files,
		Jobs:            i.jobs,
	}

	if err := artifact.Validate(); err != nil {
		return nil, err
	}

	encoded, err := json.MarshalIndent(artifact, "", "  ")

	if err != nil {
		return nil, fmt.Errorf("encode job artifact: %w", err)
	}

	return append(encoded, '\n'), nil
}

// Generate imports jobs only when explicitly called with a pinned C++ checkout.
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

func writeArtifact(
	sourceDir, outPath string,
	check bool,
	generate func(string) ([]byte, error),
) error {
	data, err := generate(sourceDir)

	if err != nil {
		return err
	}

	if check {
		current, err := os.ReadFile(outPath)

		if err != nil {
			return fmt.Errorf("read committed artifact %s: %w", outPath, err)
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

// Write generates or checks a committed job artifact; ordinary builds never call it.
func Write(sourceDir, outPath string, check bool) error {
	if outPath == "" {
		return fmt.Errorf("output path is required")
	}

	return writeArtifact(sourceDir, outPath, check, Generate)
}
