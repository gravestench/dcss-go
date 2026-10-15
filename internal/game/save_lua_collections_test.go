package game

import (
	"encoding/json"
	"strings"
	"testing"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

func TestLuaCollectionsSurviveSaveAndRejectDanglingEntity(t *testing.T) {
	rules, err := modfs.Load("../script/testdata/lua")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	target := g.player

	store, found := akara.GetDynamicStore(g.world, "test.collections")

	if !found {
		t.Fatal("test mod collection schema was not registered")
	}

	if _, err := store.Set(g.player, map[string]any{
		"ints":       []any{int64(-5), int64(8)},
		"entity_map": map[string]any{"target": target},
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	loadedStore, found := akara.GetDynamicStore(loaded.world, "test.collections")

	if !found {
		t.Fatal("restored collection schema is missing")
	}

	component, found := loadedStore.Get(loaded.player)

	if !found {
		t.Fatal("restored player collection is missing")
	}

	values, err := component.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	ints := values["ints"].([]any)
	refs := values["entity_map"].(map[string]any)

	if ints[0] != int64(-5) || ints[1] != int64(8) ||
		refs["target"] != target {
		t.Fatalf("restored values = %v", values)
	}

	ints[0] = int64(99)
	restoredInts, err := component.Get("ints")

	if err != nil || restoredInts.([]any)[0] != int64(-5) {
		t.Fatalf("snapshot aliased restored component: %v, %v", restoredInts, err)
	}

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID != uint64(g.player) {
			continue
		}

		for componentIndex := range snapshot.Entities[index].Dynamic {
			record := &snapshot.Entities[index].Dynamic[componentIndex]

			if record.Schema != "test.collections" {
				continue
			}

			record.Values["entity_map"] = json.RawMessage(`{"target":999999999}`)
		}
	}

	_, err = RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err == nil || !strings.Contains(err.Error(), "references missing entity") {
		t.Fatalf("expected dangling entity rejection, got %v", err)
	}
}
