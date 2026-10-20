package game

import (
	"encoding/json"
	"reflect"
	"testing"
)

func TestItemGenerationSessionSave(t *testing.T) {
	game := newStepGame(t)
	store := game.scripts.Components()["character.item_sets"]
	state, found := store.Get(game.player)

	if !found {
		t.Fatal("new character has no persisted item-set choices")
	}

	choices, err := state.Get("choices")

	if err != nil {
		t.Fatal(err)
	}

	selected, ok := choices.(map[string]any)

	if !ok || len(selected) != 4 {
		t.Fatalf("item-set choices = %#v", choices)
	}

	for name, id := range selected {
		if _, valid := id.(string); !valid {
			t.Fatalf("item set %s has non-string choice %#v", name, id)
		}
	}

	before := game.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("item-set choices or RNG changed across restore")
	}
}

func TestItemGenerationRejectsInvalidSavedChoices(t *testing.T) {
	game := newStepGame(t)
	checks := []struct {
		name   string
		schema string
		field  string
		value  json.RawMessage
	}{
		{
			name:   "missing set",
			schema: "character.item_sets",
			field:  "choices",
			value:  json.RawMessage(`{}`),
		},

		{
			name:   "unknown unique",
			schema: "character.unique_history",
			field:  "status",
			value:  json.RawMessage(`{"UNRAND_NOT_REAL":"ordinary"}`),
		},

		{
			name:   "unknown rune",
			schema: "character.runes",
			field:  "collected",
			value:  json.RawMessage(`{"WPN_DAGGER":true}`),
		},

		{
			name:   "invalid Pan decision",
			schema: "character.unique_history",
			field:  "pan_states",
			value:  json.RawMessage(`{"MONS_IGNACIO":"maybe"}`),
		},
	}

	for _, check := range checks {
		t.Run(check.name, func(t *testing.T) {
			snapshot := game.Snapshot()
			player := savedPlayer(t, &snapshot)
			changed := false

			for index := range player.Dynamic {
				state := &player.Dynamic[index]

				if state.Schema == check.schema {
					state.Values[check.field] = check.value
					changed = true
				}
			}

			if !changed {
				t.Fatalf("saved player has no %s", check.schema)
			}

			loaded, err := Restore(snapshot)

			if err == nil {
				loaded.Close()
				t.Fatal("invalid item generation state restored")
			}
		})
	}
}
