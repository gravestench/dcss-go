package game

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/save"
	"github.com/gravestench/akara"
)

func itemNameInInventory(t *testing.T, g *Game, entity akara.Entity) string {
	t.Helper()

	for _, item := range g.View().Inventory {
		if item.ID == uint64(entity) {
			return item.Name
		}
	}

	t.Fatalf("item %d missing from inventory view", entity)

	return ""
}

func itemNameOnFloor(t *testing.T, g *Game, entity akara.Entity) string {
	t.Helper()

	for _, item := range g.View().Entities {
		if item.ID == uint64(entity) {
			return item.Name
		}
	}

	t.Fatalf("item %d missing from floor view", entity)

	return ""
}

func addIdentificationTestItem(
	t *testing.T,
	g *Game,
	kind string,
	carried bool,
) akara.Entity {
	t.Helper()
	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	item := ecs.Item{
		KindID:   kind,
		Quantity: 1,
	}

	if _, err := g.stores.Items.Set(entity, item); err != nil {
		t.Fatal(err)
	}

	if carried {
		_, err = g.stores.CarriedBy.Set(entity, ecs.CarriedBy{
			Holder: g.player,
		})
	} else {
		position, _ := g.stores.Positions.Get(g.player)
		_, err = g.stores.Positions.Set(entity, *position)
	}

	if err != nil {
		t.Fatal(err)
	}

	return entity
}

func TestWeaponSightingsSurviveItemRemovalAndRestore(t *testing.T) {
	game := newStepGame(t)
	weapon := addIdentificationTestItem(t, game, "WPN_DAGGER", false)

	if err := game.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if !game.world.DestroyEntity(weapon) {
		t.Fatal("could not remove seen weapon")
	}

	before := game.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	store := loaded.scripts.Components()["character.item_knowledge"]
	state, found := store.Get(loaded.player)

	if !found {
		t.Fatal("restored player has no item knowledge")
	}

	value, err := state.Get("seen_types")

	if err != nil {
		t.Fatal(err)
	}

	seen := value.(map[string]any)

	if seen["WPN_DAGGER"] != true {
		t.Fatalf("dropped weapon sighting was lost: %#v", seen)
	}
}

func TestItemAppearanceDiscoveryUpdatesFloorAndSurvivesSave(t *testing.T) {
	g := newStepGame(t)
	carried := addIdentificationTestItem(t, g, "POT_CURING", true)
	floor := addIdentificationTestItem(t, g, "POT_CURING", false)
	health, _ := g.stores.Health.Get(g.player)

	health.Current = 1

	hidden := itemNameInInventory(t, g, carried)

	if strings.Contains(hidden, "curing") ||
		hidden != itemNameOnFloor(t, g, floor) {
		t.Fatalf("unknown potion names differ or reveal type: %q", hidden)
	}

	before := g.Snapshot()
	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if itemNameInInventory(t, restored, carried) != hidden ||
		itemNameOnFloor(t, restored, floor) != hidden ||
		!reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("item appearance changed across save and restore")
	}

	result, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: uint64(carried),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("quaff = %+v, %v", result, err)
	}

	if name := itemNameOnFloor(t, g, floor); name != "potion of curing" {
		t.Fatalf("discovered floor potion = %q", name)
	}
}

func TestModAddedAmuletReceivesUnknownAppearance(t *testing.T) {
	rules, err := modfs.Load("testdata/item-identification-mod")

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

	charm := addIdentificationTestItem(t, g, "MOD_ANCESTRAL_CHARM", true)
	name := itemNameInInventory(t, g, charm)

	if !strings.Contains(name, "amulet") ||
		strings.Contains(name, "charm") {
		t.Fatalf("mod amulet appearance = %q", name)
	}

	snapshot := g.Snapshot()
	player := savedPlayer(t, &snapshot)
	found := false

	for _, record := range player.Dynamic {
		if record.Schema != "character.item_knowledge" {
			continue
		}

		seeds := map[string]int64{}

		if err := json.Unmarshal(record.Values["appearance_seeds"], &seeds); err != nil {
			t.Fatal(err)
		}

		_, found = seeds["MOD_ANCESTRAL_CHARM"]
	}

	if !found {
		t.Fatal("mod amulet missing from saved appearance map")
	}
}

func mutateKnowledge(
	t *testing.T,
	snapshot *save.Snapshot,
	change func(map[string]int64),
) {
	t.Helper()
	player := savedPlayer(t, snapshot)

	for index := range player.Dynamic {
		record := &player.Dynamic[index]

		if record.Schema != "character.item_knowledge" {
			continue
		}

		seeds := map[string]int64{}

		if err := json.Unmarshal(record.Values["appearance_seeds"], &seeds); err != nil {
			t.Fatal(err)
		}

		change(seeds)
		encoded, err := json.Marshal(seeds)

		if err != nil {
			t.Fatal(err)
		}

		record.Values["appearance_seeds"] = encoded

		return
	}

	t.Fatal("saved player lacks item knowledge")
}

func TestRestoreRejectsCorruptItemKnowledge(t *testing.T) {
	g := newStepGame(t)
	cases := []struct {
		name   string
		change func(map[string]int64)
	}{
		{
			name: "duplicate appearance",
			change: func(seeds map[string]int64) {
				seeds["POT_MIGHT"] = seeds["POT_CURING"]
			},
		},

		{
			name: "unknown type",
			change: func(seeds map[string]int64) {
				seeds["POT_NOT_IN_CATALOG"] = 0
			},
		},
	}

	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			invalid := g.Snapshot()
			mutateKnowledge(t, &invalid, test.change)
			restored, err := Restore(invalid)

			if err == nil {
				restored.Close()
				t.Fatal("corrupt item knowledge restored")
			}
		})
	}
}

func TestRestoreRejectsIncompatibleItemKnowledge(t *testing.T) {
	g := newStepGame(t)
	invalid := g.Snapshot()
	changed := false

	for entityIndex := range invalid.Entities {
		entity := &invalid.Entities[entityIndex]

		if entity.Item == nil || entity.Item.KindID != "WPN_RAPIER" {
			continue
		}

		for componentIndex := range entity.Dynamic {
			record := &entity.Dynamic[componentIndex]

			if record.Schema == "item.identification" {
				record.Values["known_type"] = json.RawMessage("true")
				changed = true
			}
		}
	}

	if !changed {
		t.Fatal("starting weapon has no saved identification state")
	}

	restored, err := Restore(invalid)

	if err == nil {
		restored.Close()
		t.Fatal("weapon with incompatible type knowledge restored")
	}

	if !strings.Contains(err.Error(), "non-identifiable") {
		t.Fatalf("wrong item identification error: %v", err)
	}
}
