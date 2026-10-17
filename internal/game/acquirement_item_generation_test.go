package game

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func TestAcquirementItemGenerationKeepsOfferedEntities(t *testing.T) {
	game := newStepGame(t)
	scroll := addIdentificationTestItem(t, game, "SCR_ACQUIREMENT", true)
	first, err := game.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if first.Selection == nil || len(first.Selection.Options) != 4 {
		t.Fatalf("acquirement selection = %+v", first.Selection)
	}

	before := game.Snapshot()
	reserved := map[uint64]ecs.Item{}

	for _, record := range before.Entities {
		if record.ReservedBy != nil && record.ReservedBy.Owner == scroll {
			reserved[record.ID] = *record.Item
		}
	}

	if len(reserved) != 4 {
		t.Fatalf("reserved offers = %d, want 4", len(reserved))
	}

	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	second, err := loaded.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(first.Selection, second.Selection) {
		t.Fatal("offer menu changed after restore")
	}

	if !reflect.DeepEqual(before.RNG, loaded.Snapshot().RNG) {
		t.Fatal("reopening offers consumed item RNG")
	}

	selected := second.Selection.Options[0].ID
	result, err := loaded.Step(Command{
		Kind:     CommandRead,
		ItemID:   uint64(scroll),
		TargetID: selected,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("grant spent %d aut: %v", result.Spent, err)
	}

	remaining := 0

	for id := range reserved {
		entity := akara.Entity(id)

		if !loaded.world.EntityExists(entity) {
			continue
		}

		remaining++

		if _, onFloor := loaded.stores.Positions.Get(entity); !onFloor {
			t.Fatalf("chosen offer %d is not on floor", id)
		}
	}

	if remaining != 1 {
		t.Fatalf("remaining offer entities = %d, want 1", remaining)
	}
}

func TestAcquirementItemGenerationRejectsUnlistedReservation(t *testing.T) {
	game := newStepGame(t)
	scroll := addIdentificationTestItem(t, game, "SCR_ACQUIREMENT", true)

	if _, err := game.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := game.Snapshot()
	changed := false

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID != uint64(scroll) {
			continue
		}

		for componentIndex := range snapshot.Entities[index].Dynamic {
			part := &snapshot.Entities[index].Dynamic[componentIndex]

			if part.Schema == "scroll.acquirement_offers" {
				part.Values["offer_ids"] = json.RawMessage(`[]`)
				changed = true
			}
		}
	}

	if !changed {
		t.Fatal("acquirement owner has no menu component")
	}

	loaded, err := Restore(snapshot)

	if err == nil {
		loaded.Close()
		t.Fatal("unlisted reserved offers were restored")
	}

	if !strings.Contains(err.Error(), "reservation") {
		t.Fatalf("restore error = %v", err)
	}
}

func TestAcquirementUniqueOfferSurvivesRestore(t *testing.T) {
	game := newStepGame(t)
	scroll := addIdentificationTestItem(t, game, "SCR_ACQUIREMENT", true)
	offer, err := game.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Items.Set(offer, ecs.Item{
		KindID:   "WPN_DOUBLE_SWORD",
		Quantity: 1,
		Plus:     7,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.ReservedBy.Set(offer, ecs.ReservedBy{
		Owner: scroll,
	}); err != nil {
		t.Fatal(err)
	}

	artefacts := game.scripts.Components()["item.artefact"]

	if _, err := artefacts.Set(offer, map[string]any{
		"kind":       "unique",
		"unique_id":  "UNRAND_SINGING_SWORD",
		"seed":       uint64(0),
		"name":       "Singing Sword",
		"appearance": "Singing Sword",
		"brand":      "SPWPN_VORPAL",
		"properties": map[string]any{
			"plus":  int64(7),
			"value": int64(1000),
		},

		"known": map[string]any{
			"plus":  false,
			"value": false,
		},
		"flags": []any{},
	}); err != nil {
		t.Fatal(err)
	}

	history := game.scripts.Components()["character.unique_history"]

	if _, err := history.Set(game.player, map[string]any{
		"status": map[string]any{
			"UNRAND_SINGING_SWORD": "nonlevel",
		},
	}); err != nil {
		t.Fatal(err)
	}

	menu := game.scripts.Components()["scroll.acquirement_offers"]

	if _, err := menu.Set(scroll, map[string]any{
		"offer_ids": []any{offer},
	}); err != nil {
		t.Fatal(err)
	}

	before := game.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("unique offer or history changed across restore")
	}

	result, err := loaded.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Selection == nil ||
		len(result.Selection.Options) != 1 ||
		result.Selection.Options[0].Label != "Singing Sword" {
		t.Fatalf("restored unique offer = %+v", result.Selection)
	}

	if !reflect.DeepEqual(before.RNG, loaded.Snapshot().RNG) {
		t.Fatal("reopening unique offer consumed RNG")
	}
}
