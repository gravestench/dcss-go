package jobimport

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func jobSourceFixture(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	files := map[string]string{
		"tag-version.h": "#define TAG_MAJOR_VERSION 34\n",
		"job-data.h":    jobFixture,
		"job-type.h": "enum job_type {\n JOB_FIGHTER,\n#if TAG_MAJOR_VERSION == 34\n JOB_PRIEST,\n" +
			"#endif\n NUM_JOBS,\n};\n",
		"species-type.h": "enum species_type {\n SP_HUMAN,\n SP_MINOTAUR,\n NUM_SPECIES,\n};\n",
		"spell-type.h":   "enum spell_type {\n SPELL_NO_SPELL,\n SPELL_SHOCK,\n SPELL_BLINK,\n NUM_SPELLS,\n};\n",
		"skill-type.h":   "enum skill_type {\n SK_FIGHTING,\n NUM_SKILLS,\n SK_BLANK_LINE,\n SK_WEAPON,\n};\n",
	}
	for name, data := range files {
		if err := os.WriteFile(filepath.Join(root, name), []byte(data), 0644); err != nil {
			t.Fatal(err)
		}
	}

	return root
}

func changeJobSource(t *testing.T, root, name, old, replacement string) {
	t.Helper()
	path := filepath.Join(root, name)
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}

	if !strings.Contains(string(data), old) {
		t.Fatalf("%s missing %q", name, old)
	}

	if err := os.WriteFile(path, []byte(strings.Replace(string(data), old, replacement, 1)), 0644); err != nil {
		t.Fatal(err)
	}
}

func TestGenerateJobArtifactDeterministic(t *testing.T) {
	root := jobSourceFixture(t)
	first, err := generateFromSource(root, pinnedRevision)
	if err != nil {
		t.Fatal(err)
	}

	second, err := generateFromSource(root, pinnedRevision)
	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(first, second) || first[len(first)-1] != '\n' {
		t.Fatal("job artifact changed between runs or lacks newline")
	}

	var artifact content.JobArtifact
	if err := json.Unmarshal(first, &artifact); err != nil {
		t.Fatal(err)
	}

	if artifact.SchemaVersion != 1 || artifact.SourceRevision != pinnedRevision ||
		artifact.TagMajorVersion != 34 || len(artifact.SourceFiles) != 6 || len(artifact.Jobs) != 2 {
		t.Fatalf("unexpected artifact metadata/counts: %+v", artifact)
	}

	if artifact.Jobs[0].ID != "JOB_FIGHTER" || artifact.Jobs[1].ID != "JOB_PRIEST" ||
		artifact.Jobs[0].Equipment[1] != "wand of flame charges:15, q:2" {
		t.Fatalf("job order or equipment changed: %+v", artifact.Jobs)
	}

	for i, file := range artifact.SourceFiles {
		if len(file.SHA256) != 64 || i > 0 && artifact.SourceFiles[i-1].Path >= file.Path {
			t.Fatalf("bad source provenance order/hash: %+v", artifact.SourceFiles)
		}
	}
}

func TestGenerateJobArtifactRejectsSourceErrors(t *testing.T) {
	for _, tc := range []struct {
		name, file, old, replacement, want string
	}{
		{
			name:        "missing enum job",
			file:        "job-type.h",
			old:         " JOB_PRIEST,",
			replacement: " JOB_EXTRA,\n JOB_PRIEST,",
			want:        "JOB_EXTRA",
		},
		{
			name:        "extra definition",
			file:        "job-type.h",
			old:         " JOB_PRIEST,",
			replacement: "",
			want:        "JOB_PRIEST",
		},
		{
			name:        "duplicate ID",
			file:        "job-data.h",
			old:         "JOB_PRIEST",
			replacement: "JOB_FIGHTER",
			want:        "duplicate",
		},
		{
			name:        "duplicate abbreviation",
			file:        "job-data.h",
			old:         `"Pr", "Priest"`,
			replacement: `"Fi", "Priest"`,
			want:        "abbreviation",
		},
		{
			name:        "unknown species",
			file:        "job-data.h",
			old:         "SP_MINOTAUR",
			replacement: "SP_UNKNOWN",
			want:        "SP_UNKNOWN",
		},
		{
			name:        "unknown spell",
			file:        "job-data.h",
			old:         "SPELL_BLINK",
			replacement: "SPELL_UNKNOWN",
			want:        "SPELL_UNKNOWN",
		},
		{
			name:        "pseudo spell",
			file:        "job-data.h",
			old:         "SPELL_BLINK",
			replacement: "SPELL_NO_SPELL",
			want:        "SPELL_NO_SPELL",
		},
		{
			name:        "unknown skill",
			file:        "job-data.h",
			old:         "SK_FIGHTING",
			replacement: "SK_UNKNOWN",
			want:        "SK_UNKNOWN",
		},
		{
			name:        "pseudo skill",
			file:        "job-data.h",
			old:         "SK_FIGHTING",
			replacement: "SK_BLANK_LINE",
			want:        "SK_BLANK_LINE",
		},
		{
			name:        "wrong tag",
			file:        "tag-version.h",
			old:         "VERSION 34",
			replacement: "VERSION 35",
			want:        "tag-version.h",
		},
		{
			name:        "unsupported conditional",
			file:        "job-data.h",
			old:         "#if TAG_MAJOR_VERSION == 34",
			replacement: "#if FEATURE_X",
			want:        "FEATURE_X",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			root := jobSourceFixture(t)
			changeJobSource(t, root, tc.file, tc.old, tc.replacement)
			_, err := generateFromSource(root, pinnedRevision)
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("want error containing %q, got %v", tc.want, err)
			}
		})
	}

	if _, err := generateFromSource(jobSourceFixture(t), "wrong-revision"); err == nil ||
		!strings.Contains(err.Error(), "revision") {
		t.Fatalf("wrong revision accepted: %v", err)
	}
}

func TestWriteJobArtifactCheckAndAtomicFailure(t *testing.T) {
	root := jobSourceFixture(t)
	out := filepath.Join(t.TempDir(), "jobs.json")
	generate := func(source string) ([]byte, error) {
		return generateFromSource(source, pinnedRevision)
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
		t.Fatal("stale artifact accepted")
	}

	stale, err := os.ReadFile(out)
	if err != nil || string(stale) != "stale" {
		t.Fatalf("check modified stale output: %q, %v", stale, err)
	}

	if err := os.WriteFile(out, before, 0644); err != nil {
		t.Fatal(err)
	}

	changeJobSource(t, root, "tag-version.h", "VERSION 34", "VERSION 35")
	if err := writeArtifact(root, out, false, generate); err == nil {
		t.Fatal("bad source generated an artifact")
	}

	after, err := os.ReadFile(out)
	if err != nil || !bytes.Equal(after, before) {
		t.Fatalf("failed generation damaged artifact: %v", err)
	}
}
