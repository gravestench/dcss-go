package populationimport

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGenerateRejectsDifferentTag34TreeWithSameRowCount(t *testing.T) {
	directory := t.TempDir()
	rows := strings.Repeat("  { 1, 3, 1000, FLAT, MONS_RAT },\n", 125)
	files := map[string]string{
		"tag-version.h":   "#define TAG_MAJOR_VERSION 34\n",
		"random-pick.h":   "// altered random picker\n",
		"mon-pick-data.h": "static const vector<pop_entry> population[] =\n{\n{ // Dungeon\n" + rows + "},\n};\n",
	}

	for name, body := range files {
		if err := os.WriteFile(filepath.Join(directory, name), []byte(body), 0o600); err != nil {
			t.Fatal(err)
		}
	}

	if _, err := Generate(directory); err == nil ||
		!strings.Contains(err.Error(), "pinned") {
		t.Fatalf("different source tree accepted or rejected for wrong reason: %v", err)
	}
}
