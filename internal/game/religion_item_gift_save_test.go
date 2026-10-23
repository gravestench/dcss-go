package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
)

// Direct god acquisition creates a normal floor item with durable Lua
// provenance. Restore must preserve both it and the named RNG state.
func TestReligionItemGiftAndProvenanceSurviveRestore(t *testing.T) {
	rules, err := modfs.Load("testdata/religion-item-gift-probe")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		971,
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

	_, err = g.scripts.Policy("test.religion_item_gift", nil)

	if err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["item.provenance"]
	entities := store.Entities()

	if len(entities) != 1 {
		t.Fatalf("god gift provenance entities = %d, want 1", len(entities))
	}

	before := g.Snapshot()
	loaded, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	restored, found := loaded.scripts.Components()["item.provenance"].Get(
		entities[0])

	if !found {
		t.Fatal("gift provenance was lost on restore")
	}

	god, err := restored.Get("god_id")

	if err != nil {
		t.Fatal(err)
	}

	if god != "GOD_OKAWARU" {
		t.Fatalf("restored gift god = %v", god)
	}

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("direct god gift changed during save and restore")
	}
}
