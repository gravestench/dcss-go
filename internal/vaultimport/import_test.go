package vaultimport

import (
	"crypto/sha256"
	"encoding/hex"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

func TestSplitSourcePreservesConditionalHookPosition(t *testing.T) {
	const script = ": if crawl.one_chance_in(5) then\n" +
		"SUBST: 1 = 2\n" +
		": else\n" +
		"SUBST: 1 = 1\n" +
		": end\n"

	const source = "NAME: test_arrival\n" +
		"TAGS: arrival\n" +
		"COLOUR: . = brown\n" +
		script +
		"MAP\n" +
		"1@1\n" +
		"ENDMAP\n"

	sum := sha256.Sum256([]byte(script))
	recipe := portRecipe{
		ID: "test_arrival",
		Edits: []portEdit{
			{
				StartLine: 4,
				EndLine:   8,
				SHA256:    hex.EncodeToString(sum[:]),
				Method:    "choose_subst",
				Stage:     "run",
			},
		},
	}

	files, err := splitSource("sample.des", []byte(source), map[string]portRecipe{
		"test_arrival": recipe,
	})

	if err != nil {
		t.Fatal(err)
	}

	output := string(files["vaults/arrival/test_arrival.des"])
	color := strings.Index(output, "COLOUR: . = brown")
	hook := strings.Index(output, ": vault.run(\"choose_subst\")")
	mapStart := strings.Index(output, "MAP\n1@1\nENDMAP")

	if color < 0 ||
		hook <= color ||
		mapStart <= hook {
		t.Fatalf("conditional hook moved from source order: %q", output)
	}

	for _, line := range strings.Split(strings.TrimSpace(script), "\n") {
		if !strings.Contains(output, "# source: "+line) {
			t.Fatalf("missing commented source line %q", line)
		}
	}

	changed := strings.Replace(source, "SUBST: 1 = 2", "SUBST: 1 = 3", 1)

	if _, err := splitSource("sample.des", []byte(changed), map[string]portRecipe{
		"test_arrival": recipe,
	}); err == nil {
		t.Fatal("changed script span passed its pinned recipe")
	}
}

func TestSplitSourceRejectsUnknownDirective(t *testing.T) {
	source := []byte("NAME: test_arrival\nUNKNOWN: value\nMAP\n@\nENDMAP\n")

	if _, err := splitSource("sample.des", source, nil); err == nil {
		t.Fatal("unknown DES directive was accepted")
	}
}

func TestSplitSourcePreservesContinuedMarker(t *testing.T) {
	source := []byte("NAME: fog_arrival\n" +
		"MARKER: F = lua:fog_machine { cloud_type = flame, \\\n" +
		"    pow_max = 100, \\\n" +
		"    size = 1 }\n" +
		"MAP\nF@\nENDMAP\n")

	files, err := splitSource("sample.des", source, nil)

	if err != nil {
		t.Fatal(err)
	}

	output := string(files["vaults/arrival/fog_arrival.des"])

	if !strings.Contains(output, "    pow_max = 100, \\\n    size = 1 }") {
		t.Fatalf("continued marker changed: %q", output)
	}
}

func TestPortRecipesCoverRawMapShapingBlock(t *testing.T) {
	ports, err := loadPorts("ports")

	if err != nil {
		t.Fatal(err)
	}

	if len(ports) != 36 {
		t.Fatalf("scripted vault recipes = %d, want 36", len(ports))
	}

	recipe, found := ports["enne_arrival_octagon_isle"]

	if !found ||
		len(recipe.Edits) != 1 ||
		recipe.Edits[0].StartLine != 454 ||
		recipe.Edits[0].EndLine != 464 ||
		recipe.Edits[0].Method != "shape_octagon_isle" {
		t.Fatalf("raw map-shaping script has no source-position port: %+v", recipe)
	}
}

func TestPinnedArrivalImport(t *testing.T) {
	paths, err := filepath.Glob("../modfs/builtin/vaults/arrival/*.des")

	if err != nil {
		t.Fatal(err)
	}

	if len(paths) != 339 {
		t.Fatalf("committed vault count = %d, want 339", len(paths))
	}

	seen := make(map[string]bool)
	arrivalCount := 0
	helpers := make([]string, 0, 2)

	for _, path := range paths {
		body, err := os.ReadFile(path)

		if err != nil {
			t.Fatal(err)
		}

		lines := strings.Split(string(body), "\n")
		name := strings.TrimSpace(strings.TrimPrefix(lines[0], "NAME:"))

		if !strings.HasPrefix(lines[0], "NAME:") ||
			name == "" ||
			seen[name] {
			t.Fatalf("invalid or duplicate vault name in %s", path)
		}

		seen[name] = true

		if filepath.Base(path) != name+".des" {
			t.Fatalf("vault name and file path differ: %s", path)
		}

		for _, line := range lines {
			if strings.HasPrefix(line, "TAGS:") &&
				slices.Contains(strings.Fields(strings.TrimPrefix(line, "TAGS:")), "arrival") {
				arrivalCount++
				break
			}
		}

		if arrivalCount+len(helpers) < len(seen) {
			helpers = append(helpers, name)
		}
	}

	if arrivalCount != 337 ||
		!slices.Contains(helpers, "erik_arrival_cave_to_hall") ||
		!slices.Contains(helpers, "erik_arrival_cave_to_temple") {
		t.Fatalf("arrival/helper split = %d/%v", arrivalCount, helpers)
	}
}

func TestArrivalImportCheckDetectsEditedOutput(t *testing.T) {
	out := t.TempDir()
	path := "vaults/arrival/test_arrival.des"
	files := map[string][]byte{
		path: []byte("NAME: test_arrival\nMAP\n@\nENDMAP\n"),
	}

	if err := writeGenerated(out, files, false); err != nil {
		t.Fatal(err)
	}

	if err := writeGenerated(out, files, true); err != nil {
		t.Fatal(err)
	}

	if err := os.WriteFile(
		filepath.Join(out, path),
		[]byte("NAME: test_arrival\nMAP\n.\nENDMAP\n"),
		0o600,
	); err != nil {
		t.Fatal(err)
	}

	if err := writeGenerated(out, files, true); err == nil {
		t.Fatal("edited committed DES passed importer check")
	}
}

func TestArrivalImportCheckRejectsExtraVault(t *testing.T) {
	out := t.TempDir()
	files := map[string][]byte{
		"vaults/arrival/test_arrival.des": []byte("NAME: test_arrival\nMAP\n@\nENDMAP\n"),
	}

	if err := writeGenerated(out, files, false); err != nil {
		t.Fatal(err)
	}

	extra := filepath.Join(out, "vaults/arrival/stale.des")

	if err := os.WriteFile(extra, []byte("NAME: stale\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	if err := writeGenerated(out, files, true); err == nil {
		t.Fatal("extra committed vault passed importer check")
	}
}
