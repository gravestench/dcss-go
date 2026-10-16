package save

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/vault"
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

func TestVaultRecordCodec(t *testing.T) {
	path := filepath.Join(t.TempDir(), "vault.json")
	original := Snapshot{
		Version: Version,
		Levels: []LevelRecord{
			{
				ID:      1,
				VaultID: "enne_arrival_octagon_isle",
				VaultRecords: []vault.Record{
					{
						Kind:     vault.KindOctaRoom,
						SourceID: "enne_arrival_octagon_isle",
						X:        12,
						Y:        9,
						Arguments: []vault.Argument{
							{
								Name: "oblique",
								Kind: vault.ValueInt,
								Int:  4,
							},
						},
					},
				},
			},
		},
	}

	if err := Write(path, original); err != nil {
		t.Fatal(err)
	}

	loaded, err := Read(path)

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(original, loaded) {
		t.Fatalf("vault save changed: %+v", loaded.Levels[0].VaultRecords)
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
