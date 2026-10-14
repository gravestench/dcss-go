package startinggearimport

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/jobimport"
)

const pinnedRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

func sourceHashes(sourceDir string) ([]content.JobSourceFile, error) {
	files := make([]content.JobSourceFile, 0, 14)

	for _, name := range []string{
		"tag-version.h",
		"job-data.h",
		"job-type.h",
		"species-type.h",
		"spell-type.h",
		"skill-type.h",
		"item-prop-enum.h",
		"potion-type.h",
		"item-prop.cc",
		"item-name.cc",
		"newgame.cc",
		"ng-restr.cc",
		"ng-setup.cc",
		"jobs.cc",
	} {
		data, _, err := readKindSource(sourceDir, name)

		if err != nil {
			return nil, err
		}

		sum := sha256.Sum256(data)
		files = append(files, content.JobSourceFile{
			Path:   filepath.ToSlash(filepath.Join("crawl-ref", "source", name)),
			SHA256: hex.EncodeToString(sum[:]),
		})
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].Path < files[j].Path
	})

	return files, nil
}

func generateFromSource(sourceDir, revision string, jobs []content.JobDef, catalog content.Catalog) ([]byte, error) {
	if revision != pinnedRevision {
		return nil, fmt.Errorf("source revision %s differs from pinned %s", revision, pinnedRevision)
	}

	if len(jobs) == 0 {
		return nil, fmt.Errorf("source has no jobs")
	}

	version, versionPath, err := readKindSource(sourceDir, "tag-version.h")

	if err != nil {
		return nil, err
	}

	if !bytes.Contains(version, []byte("#define TAG_MAJOR_VERSION 34")) {
		return nil, fmt.Errorf("%s: TAG_MAJOR_VERSION must be 34", versionPath)
	}

	files, err := sourceHashes(sourceDir)

	if err != nil {
		return nil, err
	}

	enumData, enumPath, err := readKindSource(sourceDir, "item-prop-enum.h")

	if err != nil {
		return nil, err
	}

	active, err := activeEgoIDs(enumPath, enumData)

	if err != nil {
		return nil, err
	}

	names := []string{"potion of curing"}
	var gear []content.JobStartingGear
	needsChoices := false

	for _, job := range jobs {
		if !job.Selectable {
			continue
		}

		entry := content.JobStartingGear{JobID: job.ID}

		for _, raw := range job.Equipment {
			name, grant, err := parseEquipmentSpec(job.ID, raw)

			if err != nil {
				return nil, err
			}

			names = append(names, name)
			entry.Grants = append(entry.Grants, grant)
		}

		if job.WeaponChoice != "WCHOICE_NONE" {
			needsChoices = true
		}

		gear = append(gear, entry)
	}

	if len(gear) == 0 {
		return nil, fmt.Errorf("source has no selectable jobs")
	}

	if needsChoices {
		// Base and upgraded choices in newgame.cc:_get_weapons. Every name
		// is resolved against active source definitions before writing.
		names = append(names, "short sword", "mace", "hand axe", "spear", "falchion", "quarterstaff",
			"rapier", "flail", "war axe", "trident", "long sword")
	}

	kinds, err := resolveKinds(catalog, names)

	if err != nil {
		return nil, err
	}

	for i := range gear {
		for j := range gear[i].Grants {
			grant := &gear[i].Grants[j]
			name, _, err := parseEquipmentSpec(gear[i].JobID, grant.Raw)

			if err != nil {
				return nil, err
			}

			kind := kinds[name]
			grant.KindID = kind.ID

			if grant.Ego != "" {
				egoID := "SPMSL_" + strings.ToUpper(grant.Ego)

				if _, found := active[egoID]; kind.Class != "OBJ_MISSILES" || !found {
					return nil, fmt.Errorf(
						"%s: job %s equipment %q has unknown ego %q (%s)",
						enumPath,
						gear[i].JobID,
						grant.Raw,
						grant.Ego,
						egoID,
					)
				}
			}
		}
	}

	sort.Slice(gear, func(i, j int) bool {
		return gear[i].JobID < gear[j].JobID
	})
	artifact := content.StartingGearArtifact{
		SchemaVersion:   2,
		SourceRevision:  revision,
		TagMajorVersion: 34,
		SourceFiles:     files,
		Jobs:            gear,
	}

	if err := artifact.Validate(catalog); err != nil {
		return nil, err
	}

	encoded, err := json.MarshalIndent(artifact, "", "  ")

	if err != nil {
		return nil, fmt.Errorf("encode starting gear artifact: %w", err)
	}

	return append(encoded, '\n'), nil
}

// Generate is an explicit developer action; normal builds use committed JSON.
func Generate(sourceDir string) ([]byte, error) {
	if sourceDir == "" {
		return nil, fmt.Errorf("source directory is required")
	}

	jobData, err := jobimport.Generate(sourceDir)

	if err != nil {
		return nil, err
	}

	var jobArtifact content.JobArtifact

	if err := json.Unmarshal(jobData, &jobArtifact); err != nil {
		return nil, fmt.Errorf("decode source job artifact: %w", err)
	}

	if err := jobArtifact.Validate(); err != nil {
		return nil, err
	}

	if jobArtifact.SourceRevision != pinnedRevision || len(jobArtifact.Jobs) != 31 {
		return nil, fmt.Errorf("source job artifact has wrong revision or job coverage")
	}

	selectable, total := 0, 0
	rawSpecs, itemNames := map[string]bool{}, map[string]bool{}

	for _, job := range jobArtifact.Jobs {
		if !job.Selectable {
			continue
		}

		selectable++

		for _, raw := range job.Equipment {
			name, _, err := parseEquipmentSpec(job.ID, raw)

			if err != nil {
				return nil, err
			}

			total++
			rawSpecs[raw], itemNames[name] = true, true
		}
	}

	if selectable != 25 || total != 63 || len(rawSpecs) != 36 || len(itemNames) != 32 {
		return nil, fmt.Errorf(
			"source starter coverage changed: jobs=%d grants=%d specs=%d names=%d",
			selectable,
			total,
			len(rawSpecs),
			len(itemNames),
		)
	}

	catalog, err := content.LoadItemsForImport()

	if err != nil {
		return nil, err
	}

	data, err := generateFromSource(sourceDir, pinnedRevision, jobArtifact.Jobs, catalog)

	if err != nil {
		return nil, err
	}

	var gear content.StartingGearArtifact

	if err := json.Unmarshal(data, &gear); err != nil {
		return nil, err
	}

	hashes := map[string]string{}

	for _, file := range gear.SourceFiles {
		hashes[file.Path] = file.SHA256
	}

	for _, file := range jobArtifact.SourceFiles {
		if hashes[file.Path] != file.SHA256 {
			return nil, fmt.Errorf("job source hash differs for %s", file.Path)
		}
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

// Write generates or checks the committed artifact atomically.
func Write(sourceDir, outPath string, check bool) error {
	return writeArtifact(sourceDir, outPath, check, Generate)
}
