package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/vault"
)

// The source side-floor restriction must become a level record and survive
// Go save/restore, while the map itself is built by the production Lua hook.
func TestCocytusDelveSideFloorPersists(t *testing.T) {
	rules, err := modfs.Load("testdata/cocytus-delve")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		19,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max
	health.Max = 10000
	health.Current = health.Max
	descendGeneratedTo(t, g, 2)

	found := false

	for _, record := range g.levels[2].VaultRecords() {
		if record.Kind == vault.KindProperty &&
			record.Identity == "no_tele_into" &&
			record.SourceID == "layout_cocytus_delve" {
			found = true
			break
		}
	}

	if !found {
		t.Fatal("Cocytus side floor lost its no_tele_into property")
	}

	health.Max = originalMax
	health.Current = originalMax

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Cocytus side-floor records changed after restore")
	}
}
