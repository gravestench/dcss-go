package game

import (
	"reflect"
	"strings"
	"testing"
)

// Successfully selected maps need a saved identity even when they produced
// no cell records, so the next floor can enforce source uniqueness.
func TestGeneratedVaultIDsSurviveSaveAndValidate(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	placed := g.levels[1].VaultIDs()

	if len(placed) == 0 || placed[0] != g.levels[1].VaultID() {
		t.Fatalf("D:1 selected vaults = %v, primary = %q",
			placed, g.levels[1].VaultID())
	}

	snapshot := g.Snapshot()

	if !reflect.DeepEqual(snapshot.Levels[0].VaultIDs, placed) {
		t.Fatalf("saved D:1 vault IDs = %v, want %v",
			snapshot.Levels[0].VaultIDs, placed)
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(restored.levels[1].VaultIDs(), placed) {
		t.Fatalf("restored D:1 vault IDs = %v, want %v",
			restored.levels[1].VaultIDs(), placed)
	}

	snapshot.Levels[0].VaultIDs = append(
		snapshot.Levels[0].VaultIDs,
		"missing_vault_id",
	)

	invalid, err := Restore(snapshot)

	if invalid != nil {
		_ = invalid.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "missing_vault_id") {
		t.Fatalf("restored unknown vault ID = %v", err)
	}
}

// The previous save version lacks a complete placed-map history. Rejecting
// it avoids silently relaxing uniqueness after restoring an older run.
func TestGeneratedVaultIDsRequireCurrentSaveVersion(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	snapshot := g.Snapshot()

	snapshot.Version = 22

	restored, err := Restore(snapshot)

	if restored != nil {
		_ = restored.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "unsupported save version") {
		t.Fatalf("restored save without complete vault history: %v", err)
	}
}
