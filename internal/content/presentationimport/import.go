// Package presentationimport refreshes committed console menu content from the pinned DCSS source.
package presentationimport

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
)

const pinnedRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

var sourceGroup = regexp.MustCompile(
	`(?s)\{\s*"([^"]+)"\s*,\s*coord_def\([^)]*\)\s*,\s*\d+\s*,\s*\{([^}]*)\}\s*\}`,
)

var sourceID = regexp.MustCompile(`[A-Z]+_[A-Z_]+`)

var tagMajor = regexp.MustCompile(`(?m)^#define\s+TAG_MAJOR_VERSION\s+(\d+)\s*$`)

var startupModeEntry = regexp.MustCompile(
	`(?s)\{\s*(GAME_TYPE_[A-Z_]+)\s*,\s*` +
		`((?:"[^"]*"\s*)+)\s*,\s*((?:"[^"]*"\s*)+)\s*\}`,
)

var quotedString = regexp.MustCompile(`"(?:\\.|[^"\\])*"`)

var skillID = regexp.MustCompile(`SK_[A-Z_]+`)

func parseSkillColumns(path string, data []byte) ([][]string, error) {
	marker := "static const skill_type skill_display_order[]"
	start := bytes.Index(data, []byte(marker))

	if start < 0 {
		return nil, fmt.Errorf("%s: skill display order missing", path)
	}

	text := string(data[start:])
	end := strings.Index(text, "};")

	if end < 0 {
		return nil, fmt.Errorf("%s: skill display order unterminated", path)
	}

	var columns [][]string
	var column []string

	for _, id := range skillID.FindAllString(text[:end], -1) {
		switch id {
		case "SK_TITLE":
			continue

		case "SK_BLANK_LINE":
			column = append(column, "")

		case "SK_COLUMN_BREAK":
			if len(column) > 0 {
				columns = append(columns, column)
				column = nil
			}

		default:
			column = append(column, id)
		}
	}

	if len(columns) == 0 || len(column) != 0 {
		return nil, fmt.Errorf("%s: invalid skill columns", path)
	}

	return columns, nil
}

func parseStartupModes(path string, data []byte) ([]content.StartupMode, error) {
	marker := "static const game_modes_menu_item entries[]"
	start := bytes.Index(data, []byte(marker))

	if start < 0 {
		return nil, fmt.Errorf("%s: startup mode table missing", path)
	}

	text := string(data[start:])
	end := strings.Index(text, "};")

	if end < 0 {
		return nil, fmt.Errorf("%s: startup mode table unterminated", path)
	}

	join := func(value string) (string, error) {
		var result strings.Builder

		for _, part := range quotedString.FindAllString(value, -1) {
			decoded, err := strconv.Unquote(part)

			if err != nil {
				return "", err
			}

			result.WriteString(decoded)
		}

		return result.String(), nil
	}

	var modes []content.StartupMode

	for _, match := range startupModeEntry.FindAllStringSubmatch(text[:end], -1) {
		label, err := join(match[2])

		if err != nil {
			return nil, fmt.Errorf("%s: %w", path, err)
		}

		description, err := join(match[3])

		if err != nil {
			return nil, fmt.Errorf("%s: %w", path, err)
		}

		modes = append(modes, content.StartupMode{
			ID:          match[1],
			Label:       label,
			Description: description,
		})
	}

	if len(modes) == 0 {
		return nil, fmt.Errorf("%s: no startup modes", path)
	}

	return modes, nil
}

func parseGroups(path string, data []byte, variable, prefix string) ([]content.MenuGroup, error) {
	marker := variable + "[]"
	start := bytes.Index(data, []byte(marker))

	if start < 0 {
		return nil, fmt.Errorf("%s: missing %s", path, marker)
	}

	text := string(data[start:])
	end := strings.Index(text, "};")

	if end < 0 {
		return nil, fmt.Errorf("%s: unterminated %s", path, marker)
	}

	text = text[:end]
	var groups []content.MenuGroup

	for _, match := range sourceGroup.FindAllStringSubmatch(text, -1) {
		group := content.MenuGroup{Label: match[1]}

		for _, id := range sourceID.FindAllString(match[2], -1) {
			if !strings.HasPrefix(id, prefix) {
				return nil, fmt.Errorf("%s: unexpected menu ID %s", path, id)
			}

			group.IDs = append(group.IDs, id)
		}

		if len(group.IDs) == 0 {
			return nil, fmt.Errorf("%s: empty group %s", path, group.Label)
		}

		groups = append(groups, group)
	}

	if len(groups) == 0 {
		return nil, fmt.Errorf("%s: no %s groups", path, variable)
	}

	return groups, nil
}

func parseDescriptions(path string, data []byte) (map[string]string, error) {
	records := make(map[string]string)

	for _, part := range strings.Split(string(data), "%%%%") {
		part = strings.TrimSpace(part)

		if part == "" {
			continue
		}

		line, body, found := strings.Cut(part, "\n")
		name := strings.TrimSpace(line)
		body = strings.TrimSpace(body)

		if !found ||
			name == "" || body == "" {
			return nil, fmt.Errorf("%s: malformed description %q", path, name)
		}

		if _, duplicate := records[name]; duplicate {
			return nil, fmt.Errorf("%s: duplicate description %s", path, name)
		}

		records[name] = body
	}

	if len(records) == 0 {
		return nil, fmt.Errorf("%s: no descriptions", path)
	}

	return records, nil
}

func readSource(root, relative string, files *[]content.JobSourceFile) ([]byte, error) {
	data, err := os.ReadFile(filepath.Join(root, relative))

	if err != nil {
		return nil, fmt.Errorf("source %s: %w", relative, err)
	}

	sum := sha256.Sum256(data)

	*files = append(*files, content.JobSourceFile{
		Path:   filepath.ToSlash(filepath.Join("crawl-ref", "source", relative)),
		SHA256: hex.EncodeToString(sum[:]),
	})

	return data, nil
}

func generateFromSource(sourceDir string) (content.PresentationArtifact, error) {
	catalog, err := content.LoadDefinitionsForImport()

	if err != nil {
		return content.PresentationArtifact{}, fmt.Errorf("load committed definitions: %w", err)
	}

	artifact := content.PresentationArtifact{
		SchemaVersion:       1,
		SourceRevision:      pinnedRevision,
		TagMajorVersion:     34,
		SpeciesDescriptions: map[string]string{},
		JobDescriptions:     map[string]string{},
	}

	if err := validateTagVersion(sourceDir, &artifact); err != nil {
		return artifact, err
	}

	if err := loadMenuGroups(sourceDir, &artifact); err != nil {
		return artifact, err
	}

	speciesDescriptions, jobDescriptions, err := loadDescriptions(sourceDir, &artifact)

	if err != nil {
		return artifact, err
	}

	if err := loadMenuControls(sourceDir, &artifact); err != nil {
		return artifact, err
	}

	if err := attachSpeciesDescriptions(catalog, speciesDescriptions, &artifact); err != nil {
		return artifact, err
	}

	if err := attachJobDescriptions(catalog, jobDescriptions, &artifact); err != nil {
		return artifact, err
	}

	sort.Slice(
		artifact.SourceFiles,
		func(i, j int) bool {
			return artifact.SourceFiles[i].Path < artifact.SourceFiles[j].Path
		},
	)

	return artifact, nil
}

func validateTagVersion(sourceDir string, artifact *content.PresentationArtifact) error {
	version, err := readSource(sourceDir, "tag-version.h", &artifact.SourceFiles)

	if err != nil {
		return err
	}

	if match := tagMajor.FindSubmatch(version); match == nil ||
		string(match[1]) != "34" {
		return fmt.Errorf("tag-version.h: expected TAG_MAJOR_VERSION 34")
	}

	return nil
}

func loadMenuGroups(sourceDir string, artifact *content.PresentationArtifact) error {
	speciesGroups, err := readSource(sourceDir, "species-groups.h", &artifact.SourceFiles)

	if err != nil {
		return err
	}

	artifact.SpeciesGroups, err = parseGroups(
		"species-groups.h",
		speciesGroups,
		"species_groups",
		"SP_",
	)

	if err != nil {
		return err
	}

	jobGroups, err := readSource(sourceDir, "newgame.cc", &artifact.SourceFiles)

	if err != nil {
		return err
	}

	artifact.JobGroups, err = parseGroups("newgame.cc", jobGroups, "jobs_order", "JOB_")

	return err
}

func loadDescriptions(
	sourceDir string,
	artifact *content.PresentationArtifact,
) (map[string]string, map[string]string, error) {
	speciesText, err := readSource(sourceDir, "dat/descript/species.txt", &artifact.SourceFiles)

	if err != nil {
		return nil, nil, err
	}

	speciesDescriptions, err := parseDescriptions("species.txt", speciesText)

	if err != nil {
		return nil, nil, err
	}

	jobText, err := readSource(sourceDir, "dat/descript/backgrounds.txt", &artifact.SourceFiles)

	if err != nil {
		return nil, nil, err
	}

	jobDescriptions, err := parseDescriptions("backgrounds.txt", jobText)

	if err != nil {
		return nil, nil, err
	}

	return speciesDescriptions, jobDescriptions, nil
}

func loadMenuControls(sourceDir string, artifact *content.PresentationArtifact) error {
	startupText, err := readSource(sourceDir, "startup.cc", &artifact.SourceFiles)

	if err != nil {
		return err
	}

	artifact.StartupModes, err = parseStartupModes("startup.cc", startupText)

	if err != nil {
		return err
	}

	skillText, err := readSource(sourceDir, "skills.h", &artifact.SourceFiles)

	if err != nil {
		return err
	}

	artifact.SkillColumns, err = parseSkillColumns("skills.h", skillText)

	return err
}

func attachSpeciesDescriptions(
	catalog content.Catalog,
	descriptions map[string]string,
	artifact *content.PresentationArtifact,
) error {
	for _, group := range artifact.SpeciesGroups {
		for _, id := range group.IDs {
			definition, err := catalog.Species(id)

			if err != nil {
				return err
			}

			if !definition.Selectable {
				return fmt.Errorf("nonselectable species %s in menu", id)
			}

			text := descriptions[definition.Name]

			if text == "" {
				return fmt.Errorf("missing species description %s (%s)", id, definition.Name)
			}

			artifact.SpeciesDescriptions[id] = text
		}
	}

	return nil
}

func attachJobDescriptions(
	catalog content.Catalog,
	descriptions map[string]string,
	artifact *content.PresentationArtifact,
) error {
	for _, group := range artifact.JobGroups {
		for _, id := range group.IDs {
			definition, err := catalog.Job(id)

			if err != nil {
				return err
			}

			if !definition.Selectable {
				return fmt.Errorf("nonselectable job %s in menu", id)
			}

			text := descriptions[definition.Name]

			if text == "" {
				return fmt.Errorf("missing job description %s (%s)", id, definition.Name)
			}

			artifact.JobDescriptions[id] = text
		}
	}

	return nil
}

// Generate reads the pinned, clean C++ source only during an intentional content refresh.
func Generate(sourceDir string) (content.PresentationArtifact, error) {
	if sourceDir == "" {
		return content.PresentationArtifact{}, fmt.Errorf("source directory is required")
	}

	output, err := exec.Command("git", "-C", sourceDir, "rev-parse", "HEAD").Output()

	if err != nil {
		return content.PresentationArtifact{}, fmt.Errorf("read source revision: %w", err)
	}

	if strings.TrimSpace(string(output)) != pinnedRevision {
		return content.PresentationArtifact{}, fmt.Errorf(
			"source revision differs from pinned %s",
			pinnedRevision,
		)
	}

	command := exec.Command("git", "-C", sourceDir, "diff", "--quiet", "HEAD", "--", ".")

	if err := command.Run(); err != nil {
		return content.PresentationArtifact{}, fmt.Errorf(
			"source checkout has modified tracked files: %w",
			err,
		)
	}

	artifact, err := generateFromSource(sourceDir)

	if err != nil {
		return artifact, err
	}

	version, err := exec.Command("git", "-C", sourceDir, "describe", "--tags", "--always").Output()

	if err != nil {
		return artifact, fmt.Errorf("read source version: %w", err)
	}

	artifact.SourceVersion = strings.TrimSpace(string(version))

	return artifact, nil
}

// Write atomically refreshes or checks the committed presentation artifact.
func Write(sourceDir, out string, check bool) error {
	if out == "" {
		return fmt.Errorf("output path is required")
	}

	artifact, err := Generate(sourceDir)

	if err != nil {
		return err
	}

	data, err := json.MarshalIndent(artifact, "", "  ")

	if err != nil {
		return err
	}

	data = append(data, '\n')

	if check {
		current, err := os.ReadFile(out)

		if err != nil {
			return err
		}

		if !bytes.Equal(current, data) {
			return fmt.Errorf("presentation artifact %s is stale", out)
		}

		return nil
	}

	file, err := os.CreateTemp(filepath.Dir(out), ".presentation-*.tmp")

	if err != nil {
		return err
	}

	defer os.Remove(file.Name())

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

	return os.Rename(file.Name(), out)
}
