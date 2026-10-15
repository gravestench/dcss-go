package save

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRejectUnsupportedVersion(t *testing.T) {
	path := filepath.Join(t.TempDir(), "run.json")

	if err := os.WriteFile(path, []byte(`{"version":1}`), 0600); err != nil {
		t.Fatal(err)
	}

	if _, err := Read(path); err == nil ||
		!strings.Contains(err.Error(), "version") {
		t.Fatalf("Read unsupported version = %v", err)
	}
}

func TestFailedWritePreservesOldSave(t *testing.T) {
	path := filepath.Join(t.TempDir(), "run.json")

	if err := Write(path, Snapshot{
		Version: Version,
	}); err != nil {
		t.Fatal(err)
	}

	if err := Write(path, Snapshot{Version: 1}); err == nil {
		t.Fatal("unsupported snapshot accepted")
	}

	snapshot, err := Read(path)

	if err != nil ||
		snapshot.Version != Version {
		t.Fatalf("old save lost: %+v, %v", snapshot, err)
	}
}

func TestRejectVersionFourSave(t *testing.T) {
	path := filepath.Join(t.TempDir(), "old.json")

	if err := os.WriteFile(path, []byte(`{"version":4}`), 0600); err != nil {
		t.Fatal(err)
	}

	if _, err := Read(path); err == nil ||
		!strings.Contains(err.Error(), "version") {
		t.Fatalf("old save error = %v", err)
	}
}

func TestOldSaveReportsVersionBeforeRetiredFields(t *testing.T) {
	path := filepath.Join(t.TempDir(), "old.json")
	data := []byte(`{"version":13,"source_revision":"old"}`)

	if err := os.WriteFile(path, data, 0600); err != nil {
		t.Fatal(err)
	}

	_, err := Read(path)

	if err == nil ||
		err.Error() != "unsupported save version 13" {
		t.Fatalf("old save error = %v", err)
	}
}
