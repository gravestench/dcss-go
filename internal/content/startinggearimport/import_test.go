package startinggearimport

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func gearSourceFixture(t *testing.T) string {
	t.Helper()
	root := t.TempDir()

	for name, data := range map[string]string{
		"tag-version.h":    "#define TAG_MAJOR_VERSION 34\n",
		"job-data.h":       "// synthetic starter job\n",
		"job-type.h":       "enum job_type { JOB_FIGHTER, };\n",
		"species-type.h":   "enum species_type { SP_HUMAN, };\n",
		"spell-type.h":     "enum spell_type { SPELL_NONE, };\n",
		"skill-type.h":     "enum skill_type { SK_MACES_FLAILS, };\n",
		"newgame.cc":       "// weapon choices\n",
		"ng-restr.cc":      "// weapon restrictions\n",
		"ng-setup.cc":      "// starting item order\n",
		"jobs.cc":          "// job item specifications\n",
		"item-prop-enum.h": "enum special_missile_type {\n SPMSL_CURARE,\n};\n",
		"potion-type.h":    "// potion source\n",
		"item-prop.cc":     "// item property source\n",
		"item-name.cc":     "// item names\n",
	} {
		if err := os.WriteFile(filepath.Join(root, name), []byte(data), 0644); err != nil {
			t.Fatal(err)
		}
	}

	return root
}

func fixtureJobs() []content.JobDef {
	return []content.JobDef{
		{
			ID:                 "JOB_FIGHTER",
			SourcePath:         "crawl-ref/source/job-data.h",
			Abbreviation:       "Fi",
			Name:               "Fighter",
			Selectable:         true,
			RecommendedSpecies: []string{"SP_HUMAN"},
			WeaponChoice:       "WCHOICE_NONE",
			Equipment: []string{
				"scale mail",
				"potion of might",
				"dart ego:curare q:3",
			},
		},
	}
}

func TestGenerateStartingGear(t *testing.T) {
	root := gearSourceFixture(t)
	catalog, err := content.LoadItemsForImport()

	if err != nil {
		t.Fatal(err)
	}

	first, err := generateFromSource(root, pinnedRevision, fixtureJobs(), catalog)

	if err != nil {
		t.Fatal(err)
	}

	second, err := generateFromSource(root, pinnedRevision, fixtureJobs(), catalog)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(first, second) || first[len(first)-1] != '\n' {
		t.Fatal("generation is not deterministic or lacks a final newline")
	}

	var artifact content.StartingGearArtifact

	if err := json.Unmarshal(first, &artifact); err != nil {
		t.Fatal(err)
	}

	if artifact.SchemaVersion != 2 ||
		artifact.SourceRevision != pinnedRevision ||
		artifact.TagMajorVersion != 34 ||
		len(artifact.Jobs) != 1 ||
		len(artifact.Jobs[0].Grants) != 3 {
		t.Fatalf("unexpected starter artifact: %+v", artifact)
	}

	grants := artifact.Jobs[0].Grants

	if grants[0].KindID != "ARM_SCALE_MAIL" ||
		grants[1].KindID != "POT_MIGHT" ||
		grants[2].KindID != "MI_DART" ||
		grants[2].Quantity != 3 ||
		grants[2].Ego != "curare" {
		t.Fatalf("grant order or properties changed: %+v", grants)
	}

	if bytes.Contains(first, []byte(`"kinds"`)) {
		t.Fatal("gear artifact still duplicates item definitions")
	}

	if len(artifact.SourceFiles) < 10 {
		t.Fatalf("missing source hashes: %+v", artifact.SourceFiles)
	}

	for i, file := range artifact.SourceFiles {
		if len(file.SHA256) != 64 ||
			i > 0 &&
				artifact.SourceFiles[i-1].Path >= file.Path {
			t.Fatalf("invalid source hash/order: %+v", artifact.SourceFiles)
		}
	}
}

func TestGenerateStartingGearRejectsSourceErrors(t *testing.T) {
	catalog, err := content.LoadItemsForImport()

	if err != nil {
		t.Fatal(err)
	}

	for _, tc := range []struct {
		name        string
		file        string
		old         string
		replacement string
		want        string
		jobs        func() []content.JobDef
	}{
		{
			name:        "wrong tag",
			file:        "tag-version.h",
			old:         "VERSION 34",
			replacement: "VERSION 35",
			want:        "tag-version.h",
			jobs:        nil,
		},

		{
			name:        "missing item",
			file:        "",
			old:         "",
			replacement: "",
			want:        "unknown item",
			jobs: func() []content.JobDef {
				jobs := fixtureJobs()
				jobs[0].Equipment[0] = "unknown item"

				return jobs
			},
		},

		{
			name:        "unknown ego",
			file:        "",
			old:         "",
			replacement: "",
			want:        "unknown",
			jobs: func() []content.JobDef {
				jobs := fixtureJobs()
				jobs[0].Equipment[2] = "dart ego:unknown q:3"

				return jobs
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			root := gearSourceFixture(t)

			if tc.file != "" {
				path := filepath.Join(root, tc.file)
				data, err := os.ReadFile(path)

				if err != nil {
					t.Fatal(err)
				}

				if err := os.WriteFile(path, []byte(strings.Replace(string(data), tc.old, tc.replacement, 1)), 0644); err != nil {
					t.Fatal(err)
				}
			}

			jobs := fixtureJobs()

			if tc.jobs != nil {
				jobs = tc.jobs()
			}

			_, err := generateFromSource(root, pinnedRevision, jobs, catalog)

			if err == nil ||
				!strings.Contains(err.Error(), tc.want) {
				t.Fatalf("want %q error, got %v", tc.want, err)
			}
		})
	}

	if _, err := generateFromSource(
		gearSourceFixture(t),
		"wrong-revision",
		fixtureJobs(),
		catalog,
	); err == nil ||
		!strings.Contains(
			err.Error(),
			"revision",
		) {
		t.Fatalf("wrong revision accepted: %v", err)
	}

	_, err = generateFromSource(gearSourceFixture(t), pinnedRevision, nil, catalog)

	if err == nil ||
		!strings.Contains(err.Error(), "job") {
		t.Fatalf("missing jobs accepted: %v", err)
	}
}

func TestWriteStartingGear(t *testing.T) {
	root := gearSourceFixture(t)
	out := filepath.Join(t.TempDir(), "starting-gear.json")
	catalog, err := content.LoadItemsForImport()

	if err != nil {
		t.Fatal(err)
	}

	generate := func(source string) ([]byte, error) {
		return generateFromSource(source, pinnedRevision, fixtureJobs(), catalog)
	}

	if err := writeArtifact(root, out, false, generate); err != nil {
		t.Fatal(err)
	}

	before, err := os.ReadFile(out)

	if err != nil {
		t.Fatal(err)
	}

	if err := writeArtifact(root, out, true, generate); err != nil {
		t.Fatal(err)
	}

	if err := os.WriteFile(out, []byte("stale"), 0644); err != nil {
		t.Fatal(err)
	}

	if err := writeArtifact(root, out, true, generate); err == nil {
		t.Fatal("stale artifact passed check")
	}

	if data, _ := os.ReadFile(out); string(data) != "stale" {
		t.Fatal("failed check changed output")
	}

	if err := os.WriteFile(out, before, 0644); err != nil {
		t.Fatal(err)
	}

	broken := func(string) ([]byte, error) {
		return nil, os.ErrInvalid
	}

	if err := writeArtifact(root, out, false, broken); err == nil {
		t.Fatal("failed generation passed")
	}

	if data, _ := os.ReadFile(out); !bytes.Equal(data, before) {
		t.Fatal("failed generation changed output")
	}
}
