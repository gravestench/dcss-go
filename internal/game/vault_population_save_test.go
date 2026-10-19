package game

import (
	"bytes"
	"encoding/json"
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

func cloneVaultSnapshot(t *testing.T, original save.Snapshot) save.Snapshot {
	t.Helper()

	encoded, err := json.Marshal(original)

	if err != nil {
		t.Fatal(err)
	}

	var copied save.Snapshot

	if err := json.Unmarshal(encoded, &copied); err != nil {
		t.Fatal(err)
	}

	return copied
}

func restoreEqualsVaultSnapshot(
	t *testing.T,
	snapshot save.Snapshot,
	rules modfs.Ruleset,
) {
	t.Helper()

	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	// The JSON clone normalizes nil and empty slices. Compare saved bytes so
	// the test checks every persisted field, including RNG and vault records.
	before, _ := json.Marshal(snapshot)
	after, _ := json.Marshal(restored.Snapshot())

	if !bytes.Equal(before, after) {
		t.Fatal("vault lifecycle changed during restore or consumed RNG")
	}
}

func removeVaultEntity(snapshot *save.Snapshot, wanted func(save.EntityRecord) bool) {
	for index, entity := range snapshot.Entities {
		if wanted(entity) {
			snapshot.Entities = append(snapshot.Entities[:index], snapshot.Entities[index+1:]...)

			return
		}
	}
}

func rejectVaultSnapshot(t *testing.T, snapshot save.Snapshot, rules modfs.Ruleset) {
	t.Helper()

	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err == nil {
		restored.Close()
		t.Fatal("corrupt vault snapshot was restored")
	}
}

func TestVaultPopulationSaveRestore(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-population")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
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

	defer g.Close()

	snapshot := g.Snapshot()
	ambientActors := 0

	for _, entity := range snapshot.Entities {
		if entity.AI == nil ||
			entity.Position == nil ||
			entity.Position.LevelID != 1 {
			continue
		}

		authored := false

		for _, dynamic := range entity.Dynamic {
			authored = authored || dynamic.Schema == "vault.origin"
		}

		if !authored {
			ambientActors++
		}
	}

	if snapshot.Levels[0].InitialActors != ambientActors {
		t.Fatalf("ambient budget includes authored actors: saved=%d ambient=%d",
			snapshot.Levels[0].InitialActors, ambientActors)
	}

	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("authored entities or records changed on restore")
	}

	corrupt := snapshot

	corrupt.Entities = append([]save.EntityRecord(nil), snapshot.Entities...)

	changed := false

	for entityIndex := range corrupt.Entities {
		entity := &corrupt.Entities[entityIndex]

		if entity.Actor == nil || entity.Actor.KindID != "MONS_PLANT" {
			continue
		}

		entity.Dynamic = append([]save.DynamicComponentRecord(nil), entity.Dynamic...)

		for componentIndex := range entity.Dynamic {
			component := &entity.Dynamic[componentIndex]

			if component.Schema != "vault.origin" {
				continue
			}

			original := component.Values

			component.Values = make(map[string]json.RawMessage, len(original))

			for key, value := range original {
				component.Values[key] = value
			}

			component.Values["vault_id"] = json.RawMessage(`"forged_vault"`)
			changed = true
		}
	}

	if !changed {
		t.Fatal("forced vault plant has no origin component")
	}

	forged, err := RestoreWithRules(corrupt, rules, RestorePolicy{})

	if err == nil {
		forged.Close()
		t.Fatal("forged vault origin was restored")
	}

	t.Run("forged actor kind", func(t *testing.T) {
		forgedKind := cloneVaultSnapshot(t, snapshot)

		for index := range forgedKind.Entities {
			actor := forgedKind.Entities[index].Actor

			if actor != nil && actor.KindID == "MONS_PLANT" {
				actor.KindID = "MONS_RAT"
			}
		}

		rejectVaultSnapshot(t, forgedKind, rules)
	})

	t.Run("duplicate occurrence", func(t *testing.T) {
		duplicate := cloneVaultSnapshot(t, snapshot)
		var source map[string]json.RawMessage

		for _, entity := range duplicate.Entities {
			if entity.Item == nil ||
				entity.Item.KindID != "MI_STONE" ||
				entity.Item.Quantity != 4 {
				continue
			}

			for _, dynamic := range entity.Dynamic {
				if dynamic.Schema == "vault.origin" {
					source = dynamic.Values
				}
			}
		}

		if source == nil {
			t.Fatal("floor stones have no origin")
		}

		for entityIndex := range duplicate.Entities {
			entity := &duplicate.Entities[entityIndex]

			if entity.Item == nil ||
				entity.Item.KindID != "MI_STONE" ||
				entity.Item.Quantity != 1 ||
				entity.CarriedBy == nil {
				continue
			}

			for componentIndex := range entity.Dynamic {
				if entity.Dynamic[componentIndex].Schema == "vault.origin" {
					entity.Dynamic[componentIndex].Values = source
				}
			}
		}

		rejectVaultSnapshot(t, duplicate, rules)
	})

	t.Run("forged gear occurrence", func(t *testing.T) {
		forgedGear := cloneVaultSnapshot(t, snapshot)
		changed := false

		for entityIndex := range forgedGear.Entities {
			entity := &forgedGear.Entities[entityIndex]

			if entity.Item == nil ||
				entity.Item.KindID != "MI_STONE" ||
				entity.CarriedBy == nil {
				continue
			}

			for componentIndex := range entity.Dynamic {
				origin := &entity.Dynamic[componentIndex]

				if origin.Schema != "vault.origin" {
					continue
				}

				origin.Values["occurrence"] = json.RawMessage(`4`)
				changed = true
			}
		}

		if !changed {
			t.Fatal("forced goblin gear has no origin")
		}

		rejectVaultSnapshot(t, forgedGear, rules)
	})

	t.Run("missing source record", func(t *testing.T) {
		missing := cloneVaultSnapshot(t, snapshot)
		records := missing.Levels[0].VaultRecords

		for index, record := range records {
			if record.Identity == "stone" {
				missing.Levels[0].VaultRecords = append(records[:index], records[index+1:]...)

				break
			}
		}

		rejectVaultSnapshot(t, missing, rules)
	})
}

func TestVaultPopulationLifecycle(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-population")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
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

	defer g.Close()

	baseline := g.Snapshot()

	t.Run("moved monster", func(t *testing.T) {
		snapshot := cloneVaultSnapshot(t, baseline)
		occupied := make(map[[2]int]bool)

		for _, entity := range snapshot.Entities {
			if entity.Actor != nil &&
				entity.Position != nil &&
				entity.Position.LevelID == 1 {
				occupied[[2]int{entity.Position.X, entity.Position.Y}] = true
			}
		}

		var destination [2]int
		found := false

		for y, row := range snapshot.Levels[0].Cells {
			for x, cell := range row {
				if terrain.Walkable(cell) && !occupied[[2]int{x, y}] {
					destination = [2]int{x, y}
					found = true

					break
				}
			}

			if found {
				break
			}
		}

		if !found {
			t.Fatal("no free destination for vault monster")
		}

		for index := range snapshot.Entities {
			entity := &snapshot.Entities[index]

			if entity.Actor != nil && entity.Actor.KindID == "MONS_PLANT" {
				entity.Position.X = destination[0]
				entity.Position.Y = destination[1]
			}
		}

		restoreEqualsVaultSnapshot(t, snapshot, rules)
	})

	t.Run("killed monster", func(t *testing.T) {
		snapshot := cloneVaultSnapshot(t, baseline)

		removeVaultEntity(&snapshot, func(entity save.EntityRecord) bool {
			return entity.Actor != nil && entity.Actor.KindID == "MONS_PLANT"
		})

		restoreEqualsVaultSnapshot(t, snapshot, rules)
	})

	t.Run("picked up item", func(t *testing.T) {
		snapshot := cloneVaultSnapshot(t, baseline)

		for index := range snapshot.Entities {
			entity := &snapshot.Entities[index]

			if entity.Item != nil &&
				entity.Item.KindID == "MI_STONE" &&
				entity.Item.Quantity == 4 {
				entity.Position = nil
				entity.CarriedBy = &ecs.CarriedBy{
					Holder: akara.Entity(snapshot.PlayerID),
				}
			}
		}

		restoreEqualsVaultSnapshot(t, snapshot, rules)
	})

	t.Run("consumed item", func(t *testing.T) {
		snapshot := cloneVaultSnapshot(t, baseline)

		removeVaultEntity(&snapshot, func(entity save.EntityRecord) bool {
			return entity.Item != nil &&
				entity.Item.KindID == "MI_STONE" &&
				entity.Item.Quantity == 4
		})

		restoreEqualsVaultSnapshot(t, snapshot, rules)
	})

	t.Run("decayed skeleton", func(t *testing.T) {
		snapshot := cloneVaultSnapshot(t, baseline)

		removeVaultEntity(&snapshot, func(entity save.EntityRecord) bool {
			return entity.Item != nil && entity.Item.KindID == "CORPSE_SKELETON"
		})

		restoreEqualsVaultSnapshot(t, snapshot, rules)
	})
}

func TestVaultPopulationPreVaultVersion18(t *testing.T) {
	g, err := NewScenario(41, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	snapshot := g.Snapshot()

	if snapshot.Version != save.Version {
		t.Fatalf("save version = %d, want %d", snapshot.Version, save.Version)
	}

	for _, entity := range snapshot.Entities {
		for _, dynamic := range entity.Dynamic {
			if dynamic.Schema == "vault.origin" {
				t.Fatal("pre-vault scenario unexpectedly has an origin")
			}
		}
	}

	restoreEqualsVaultSnapshot(t, snapshot, g.rules)
}
