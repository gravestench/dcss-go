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
	*files = append(*files, content.JobSourceFile{Path: label, SHA256: hex.EncodeToString(sum[:])})
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

func generateFromSource(sourceDir, revision string) ([]byte, error) {
	if revision != pinnedRevision {
		return nil, fmt.Errorf("source revision %s differs from pinned %s", revision, pinnedRevision)
	}
	var files []content.JobSourceFile
	version, versionPath, err := readJobSource(sourceDir, "tag-version.h", &files)
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
	jobData, jobDataPath, err := readJobSource(sourceDir, "job-data.h", &files)
	if err != nil {
		return nil, err
	}
	jobHeader, jobHeaderPath, err := readJobSource(sourceDir, "job-type.h", &files)
	if err != nil {
		return nil, err
	}
	speciesHeader, speciesHeaderPath, err := readJobSource(sourceDir, "species-type.h", &files)
	if err != nil {
		return nil, err
	}
	spellHeader, spellHeaderPath, err := readJobSource(sourceDir, "spell-type.h", &files)
	if err != nil {
		return nil, err
	}
	skillHeader, skillHeaderPath, err := readJobSource(sourceDir, "skill-type.h", &files)
	if err != nil {
		return nil, err
	}
	jobIDs, err := sourceparse.ActiveEnumIDs(jobHeaderPath, jobHeader, "JOB_")
	if err != nil {
		return nil, err
	}
	delete(jobIDs, "JOB_RANDOM")
	delete(jobIDs, "JOB_VIABLE")
	speciesIDs, err := sourceparse.ActiveEnumIDs(speciesHeaderPath, speciesHeader, "SP_")
	if err != nil {
		return nil, err
	}
	spellIDs, err := sourceparse.ActiveEnumIDs(spellHeaderPath, spellHeader, "SPELL_")
	if err != nil {
		return nil, err
	}
	delete(spellIDs, "SPELL_NO_SPELL")
	delete(spellIDs, "SPELL_MELEE")
	skillIDs, err := ordinaryJobSkills(skillHeaderPath, skillHeader)
	if err != nil {
		return nil, err
	}
	jobs, err := parseJobData(jobDataPath, jobData)
	if err != nil {
		return nil, err
	}
	seen := make(map[string]bool, len(jobs))
	for _, job := range jobs {
		if _, active := jobIDs[job.ID]; !active {
			return nil, fmt.Errorf("%s: job %s is not an active concrete job", job.SourcePath, job.ID)
		}
		seen[job.ID] = true
		for _, species := range job.RecommendedSpecies {
			if _, active := speciesIDs[species]; !active {
				return nil, fmt.Errorf("%s: %s has unknown recommended species %s", job.SourcePath, job.ID, species)
			}
		}
		for _, spell := range job.Spells {
			if _, active := spellIDs[spell]; !active {
				return nil, fmt.Errorf("%s: %s has unknown spell %s", job.SourcePath, job.ID, spell)
			}
		}
		for _, grant := range job.Skills {
			if _, active := skillIDs[grant.ID]; !active {
				return nil, fmt.Errorf("%s: %s has unknown skill %s", job.SourcePath, job.ID, grant.ID)
			}
		}
	}
	for id := range jobIDs {
		if !seen[id] {
			return nil, fmt.Errorf("%s: active job %s has no definition", jobHeaderPath, id)
		}
	}
	sort.Slice(jobs, func(i, j int) bool { return jobs[i].ID < jobs[j].ID })
	sort.Slice(files, func(i, j int) bool { return files[i].Path < files[j].Path })
	artifact := content.JobArtifact{SchemaVersion: 1, SourceRevision: revision, TagMajorVersion: 34, SourceFiles: files, Jobs: jobs}
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

func writeArtifact(sourceDir, outPath string, check bool, generate func(string) ([]byte, error)) error {
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
