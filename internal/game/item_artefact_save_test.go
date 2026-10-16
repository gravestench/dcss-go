package game

import (
	"encoding/json"
	"reflect"
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestItemArtefactSave(t *testing.T) {
	game := newStepGame(t)
	item, err := game.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Items.Set(item, ecs.Item{
		KindID:   "WPN_DAGGER",
		Quantity: 1,
		Plus:     5,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Positions.Set(item, ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       4,
	}); err != nil {
		t.Fatal(err)
	}

	artefacts := game.scripts.Components()["item.artefact"]

	if _, err := artefacts.Set(item, map[string]any{
		"kind":       "random",
		"unique_id":  "",
		"seed":       uint64(12345),
		"name":       "Dagger of Fire",
		"appearance": "dagger",
		"brand":      "SPWPN_VENOM",
		"properties": map[string]any{
			"ARTP_FIRE": int64(1),
		},
		"known": map[string]any{
			"ARTP_FIRE": true,
		},
		"flags": []any{},
	}); err != nil {
		t.Fatal(err)
	}

	book, err := game.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Items.Set(book, ecs.Item{
		KindID:   "BOOK_RANDART_LEVEL",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Positions.Set(book, ecs.Position{
		LevelID: 1,
		X:       5,
		Y:       4,
	}); err != nil {
		t.Fatal(err)
	}

	books := game.scripts.Components()["item.random_book"]

	if _, err := books.Set(book, map[string]any{
		"spells": []any{"SPELL_MAGIC_DART"},
		"theme":  "",
		"level":  int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := artefacts.Set(book, map[string]any{
		"kind":       "random",
		"unique_id":  "",
		"seed":       uint64(54321),
		"name":       "book of Sorcery",
		"appearance": "book",
		"brand":      "",
		"properties": map[string]any{},
		"known":      map[string]any{},
		"flags":      []any{},
	}); err != nil {
		t.Fatal(err)
	}

	manual, err := game.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Items.Set(manual, ecs.Item{
		KindID:   "BOOK_MANUAL",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Positions.Set(manual, ecs.Position{
		LevelID: 1,
		X:       6,
		Y:       4,
	}); err != nil {
		t.Fatal(err)
	}

	manuals := game.scripts.Components()["item.manual"]

	if _, err := manuals.Set(manual, map[string]any{
		"skill_id": "SK_AXES",
		"points":   int64(2000),
	}); err != nil {
		t.Fatal(err)
	}

	before := game.Snapshot()
	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("artefact identity, values, or knowledge changed on restore")
	}

	invalid := game.Snapshot()
	changed := false

	for index := range invalid.Entities {
		if invalid.Entities[index].ID != uint64(book) {
			continue
		}

		for stateIndex := range invalid.Entities[index].Dynamic {
			state := &invalid.Entities[index].Dynamic[stateIndex]

			if state.Schema == "item.random_book" {
				state.Values["spells"] = json.RawMessage(`[]`)
				changed = true
			}
		}
	}

	if !changed {
		t.Fatal("saved book has no spell component")
	}

	corrupt, err := Restore(invalid)

	if err == nil {
		corrupt.Close()
		t.Fatal("random book without spells restored")
	}

	invalid = game.Snapshot()
	changed = false

	for index := range invalid.Entities {
		if invalid.Entities[index].ID != uint64(manual) {
			continue
		}

		for stateIndex := range invalid.Entities[index].Dynamic {
			state := &invalid.Entities[index].Dynamic[stateIndex]

			if state.Schema == "item.manual" {
				state.Values["skill_id"] = json.RawMessage(`"SK_NOT_REAL"`)
				changed = true
			}
		}
	}

	if !changed {
		t.Fatal("saved manual has no skill component")
	}

	corrupt, err = Restore(invalid)

	if err == nil {
		corrupt.Close()
		t.Fatal("manual with unknown skill restored")
	}
}
