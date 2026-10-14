package branchimport

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGenerateAndCheckUseOnlyExplicitBranchSources(t *testing.T) {
	dir := t.TempDir()
	for name, body := range map[string]string{
		"tag-version.h": "#define TAG_MAJOR_VERSION 34\n",
		"branch-type.h": syntheticEnum,
		"branch-data.h": syntheticTable,
	} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(body), 0600); err != nil {
			t.Fatal(err)
		}
	}
	first, err := Generate(dir)
	if err != nil {
		t.Fatal(err)
	}
	second, err := Generate(dir)
	if err != nil || !bytes.Equal(first, second) {
		t.Fatalf("nondeterministic branch import: %v", err)
	}
	out := filepath.Join(t.TempDir(), "branches.json")
	if err := Write(dir, out, false); err != nil {
		t.Fatal(err)
	}
	if err := Write(dir, out, true); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "branch-data.h"), []byte(strings.Replace(syntheticTable, "the Dungeon", "a Dungeon", 1)), 0600); err != nil {
		t.Fatal(err)
	}
	if err := Write(dir, out, true); err == nil {
		t.Fatal("accepted stale committed branch content")
	}
}
