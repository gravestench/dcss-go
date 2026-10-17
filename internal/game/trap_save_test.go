package game

import (
	"encoding/json"
	"reflect"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/save"
)

const trapSchema = "world.trap"

func trapSnapshot(t *testing.T) (save.Snapshot, uint64) {
	t.Helper()

	game := newStepGame(t)
	defer game.Close()

	trap, err := game.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	position := ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       4,
	}

	if _, err := game.stores.Positions.Set(trap, position); err != nil {
		t.Fatal(err)
	}

	store := game.scripts.Components()[trapSchema]

	if _, err := store.Set(trap, map[string]any{
		"kind_id":       "TRAP_TELEPORT",
		"level_id":      int64(1),
		"x":             int64(4),
		"y":             int64(4),
		"charges":       int64(1),
		"revealed":      true,
		"source_record": "",
	}); err != nil {
		t.Fatal(err)
	}

	return game.Snapshot(), uint64(trap)
}

func TestTrapSaveRejectsDuplicateCell(t *testing.T) {
	game := newStepGame(t)
	defer game.Close()

	for range 2 {
		trap, err := game.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		position := ecs.Position{
			LevelID: 1,
			X:       4,
			Y:       4,
		}

		if _, err := game.stores.Positions.Set(trap, position); err != nil {
			t.Fatal(err)
		}

		if _, err := game.scripts.Components()[trapSchema].Set(trap, map[string]any{
			"kind_id":       "TRAP_TELEPORT_PERMANENT",
			"level_id":      int64(1),
			"x":             int64(4),
			"y":             int64(4),
			"charges":       int64(0),
			"revealed":      true,
			"source_record": "",
		}); err != nil {
			t.Fatal(err)
		}
	}

	loaded, err := Restore(game.Snapshot())

	if err == nil {
		loaded.Close()
		t.Fatal("two traps on one cell restored")
	}
}

func TestModTrapRestoresWithEffectiveRules(t *testing.T) {
	rules, err := modfs.Load(
		"testdata/vault-traps",
		"../script/testdata/trap-mod",
	)

	if err != nil {
		t.Fatal(err)
	}

	game, err := NewDungeonGameWithRules(
		41,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer game.Close()

	store := game.scripts.Components()[trapSchema]
	trap := store.Entities()[0]
	state, found := store.Get(trap)

	if !found {
		t.Fatal("authored trap has no state")
	}

	if err := state.Set("kind_id", "TRAP_TEST_CUSTOM"); err != nil {
		t.Fatal(err)
	}

	if err := state.Set("charges", int64(0)); err != nil {
		t.Fatal(err)
	}

	if err := state.Set("source_record", ""); err != nil {
		t.Fatal(err)
	}

	loaded, err := RestoreWithRules(game.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if len(loaded.scripts.Components()[trapSchema].Entities()) != 1 {
		t.Fatal("mod-added trap disappeared on restore")
	}
}

func changeTrapField(t *testing.T, snapshot *save.Snapshot, entityID uint64, field string, value string) {
	t.Helper()

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID != entityID {
			continue
		}

		for stateIndex := range snapshot.Entities[index].Dynamic {
			state := &snapshot.Entities[index].Dynamic[stateIndex]

			if state.Schema == trapSchema {
				state.Values[field] = json.RawMessage(value)

				return
			}
		}
	}

	t.Fatal("trap component missing from snapshot")
}

func TestTrapSaveRejectsInvalidState(t *testing.T) {
	before, trapID := trapSnapshot(t)
	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("trap state changed on restore")
	}

	cases := []struct {
		name  string
		field string
		value string
	}{
		{
			name:  "unknown kind",
			field: "kind_id",
			value: `"TRAP_NOT_REAL"`,
		},

		{
			name:  "negative charges",
			field: "charges",
			value: `-1`,
		},

		{
			name:  "mismatched cell",
			field: "x",
			value: `5`,
		},

		{
			name:  "dangling vault origin",
			field: "source_record",
			value: `"missing:1"`,
		},
	}

	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			entities := append([]save.EntityRecord(nil), before.Entities...)
			corrupt := before

			corrupt.Entities = entities

			for index := range corrupt.Entities {
				corrupt.Entities[index].Dynamic = append(
					[]save.DynamicComponentRecord(nil),
					before.Entities[index].Dynamic...,
				)

				for stateIndex := range corrupt.Entities[index].Dynamic {
					state := &corrupt.Entities[index].Dynamic[stateIndex]
					values := make(map[string]json.RawMessage, len(state.Values))

					for key, value := range state.Values {
						values[key] = append(json.RawMessage(nil), value...)
					}

					state.Values = values
				}
			}

			changeTrapField(t, &corrupt, trapID, test.field, test.value)
			loaded, err := Restore(corrupt)

			if err == nil {
				loaded.Close()
				t.Fatal("invalid trap restored")
			}
		})
	}
}
