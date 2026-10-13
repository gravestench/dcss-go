package speciesimport

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func sourceFixture(t *testing.T) string {
	t.Helper()
	root := filepath.Join(t.TempDir(), "crawl-ref", "source")
	files := map[string][]byte{
		"dat/species/human.yaml": []byte(humanYAML),
		"tag-version.h":          []byte("#define TAG_MAJOR_VERSION 34\n"),
		"species-type.h":         []byte("enum species_type {\n SP_HUMAN,\n#if TAG_MAJOR_VERSION == 34\n SP_HIGH_ELF,\n SP_LAVA_ORC,\n SP_SLUDGE_ELF,\n#endif\n NUM_SPECIES,\n};\n"),
		"monster-type.h":         []byte("enum monster_type {\n MONS_HUMAN,\n MONS_ELF,\n MONS_LAVA_ORC,\n};\n"),
		"job-type.h":             []byte("enum job_type {\n JOB_FIGHTER,\n NUM_JOBS,\n};\n"),
	}
	legacy, aptitudes := legacyFixtures(t)
	files["util/species-gen/species-data-deprecated-species.txt"] = legacy
	files["util/species-gen/aptitudes-deprecated-species.txt"] = aptitudes
	for path, data := range files {
		full := filepath.Join(root, path)
		if err := os.MkdirAll(filepath.Dir(full), 0755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(full, data, 0644); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

func replaceFixture(t *testing.T, root, path, old, replacement string) {
	t.Helper()
	full := filepath.Join(root, path)
	data, err := os.ReadFile(full)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), old) {
		t.Fatalf("fixture %s missing %q", path, old)
	}
	if err := os.WriteFile(full, []byte(strings.Replace(string(data), old, replacement, 1)), 0644); err != nil {
		t.Fatal(err)
	}
}

func TestGenerateSpeciesArtifactDeterministic(t *testing.T) {
	root := sourceFixture(t)
	first, err := generateFromSource(root, pinnedRevision)
	if err != nil {
		t.Fatal(err)
	}
	second, err := generateFromSource(root, pinnedRevision)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(first, second) || len(first) == 0 || first[len(first)-1] != '\n' {
		t.Fatal("artifact bytes changed or lack final newline")
	}
	var artifact content.SpeciesArtifact
	if err := json.Unmarshal(first, &artifact); err != nil {
		t.Fatal(err)
	}
	if artifact.SchemaVersion != 1 || artifact.SourceRevision != pinnedRevision || artifact.TagMajorVersion != 34 || len(artifact.Species) != 4 || len(artifact.SourceFiles) != 7 {
		t.Fatalf("wrong artifact metadata/counts: %+v", artifact)
	}
	for i := 1; i < len(artifact.Species); i++ {
		if artifact.Species[i-1].ID >= artifact.Species[i].ID {
			t.Fatalf("species unsorted: %s >= %s", artifact.Species[i-1].ID, artifact.Species[i].ID)
		}
	}
	for i := 1; i < len(artifact.SourceFiles); i++ {
		if artifact.SourceFiles[i-1].Path >= artifact.SourceFiles[i].Path {
			t.Fatalf("source files unsorted")
		}
	}
	for _, file := range artifact.SourceFiles {
		if len(file.SHA256) != 64 {
			t.Fatalf("bad source SHA-256 for %s", file.Path)
		}
	}
}

func TestGenerateSpeciesArtifactRejectsSourceErrors(t *testing.T) {
	cases := []struct{ name, path, old, replacement, want string }{
		{"duplicate ID", "dat/species/human.yaml", "SP_HUMAN", "SP_HIGH_ELF", "SP_HIGH_ELF"},
		{"missing active species", "species-type.h", " SP_HUMAN,", " SP_EXTRA, SP_HUMAN,", "SP_EXTRA"},
		{"missing monster reference", "dat/species/human.yaml", "MONS_HUMAN", "MONS_MISSING", "MONS_MISSING"},
		{"missing job reference", "dat/species/human.yaml", "JOB_FIGHTER", "JOB_MISSING", "JOB_MISSING"},
		{"wrong tag", "tag-version.h", "VERSION 34", "VERSION 35", "tag-version.h"},
		{"unsupported conditional", "species-type.h", "TAG_MAJOR_VERSION == 34", "FEATURE_X", "FEATURE_X"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			root := sourceFixture(t)
			replaceFixture(t, root, tc.path, tc.old, tc.replacement)
			_, err := generateFromSource(root, pinnedRevision)
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("want error containing %q, got %v", tc.want, err)
			}
		})
	}
	root := sourceFixture(t)
	if _, err := generateFromSource(root, "unexpected-revision"); err == nil || !strings.Contains(err.Error(), "revision") {
		t.Fatalf("wrong revision accepted: %v", err)
	}
}

func TestWriteSpeciesArtifactCheckAndAtomicFailure(t *testing.T) {
	out := filepath.Join(t.TempDir(), "species.json")
	generated := func(string) ([]byte, error) { return []byte("current\n"), nil }
	if err := writeArtifact("unused", out, false, generated); err != nil {
		t.Fatal(err)
	}
	if err := writeArtifact("unused", out, true, generated); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(out, []byte("stale\n"), 0644); err != nil {
		t.Fatal(err)
	}
	if err := writeArtifact("unused", out, true, generated); err == nil {
		t.Fatal("stale artifact accepted by check mode")
	}
	data, err := os.ReadFile(out)
	if err != nil {
		t.Fatal(err)
	}
	if string(data) != "stale\n" {
		t.Fatalf("check mode changed output to %q", data)
	}
	failing := func(string) ([]byte, error) { return nil, os.ErrInvalid }
	if err := writeArtifact("unused", out, false, failing); err == nil {
		t.Fatal("failed generation accepted")
	}
	data, err = os.ReadFile(out)
	if err != nil {
		t.Fatal(err)
	}
	if string(data) != "stale\n" {
		t.Fatalf("failed generation truncated output to %q", data)
	}
}
