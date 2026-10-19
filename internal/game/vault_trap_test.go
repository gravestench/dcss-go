package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/modfs"
	"crawl/internal/vault"
)

func TestArrivalTrapMaterializesAsSavedEntity(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-traps")

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

	if game.levels[1].VaultID() != "zz_trap_test" {
		t.Fatalf("selected vault = %s", game.levels[1].VaultID())
	}

	store := game.scripts.Components()[trapSchema]

	if len(store.Entities()) != 1 {
		t.Fatalf("materialized traps = %d, want one; records = %+v",
			len(store.Entities()), game.levels[1].VaultRecords())
	}

	trap := store.Entities()[0]
	position, found := game.stores.Positions.Get(trap)

	if !found || position.LevelID != 1 {
		t.Fatalf("trap has no D:1 position: %+v", position)
	}

	placed := false

	for _, record := range game.levels[1].VaultRecords() {
		if record.Kind == vault.KindFeature && record.Identity == "TRAP_TELEPORT" {
			if record.Pending {
				t.Fatal("authored trap stayed pending")
			}

			placed = true
		}
	}

	if !placed {
		t.Fatal("authored trap record missing")
	}

	directions := []struct {
		dx int
		dy int
	}{
		{dx: -1},
		{dx: 1},
		{dy: -1},
		{dy: 1},
	}

	entry := Command{Kind: CommandMove}
	foundEntry := false

	for _, direction := range directions {
		x := position.X - direction.dx
		y := position.Y - direction.dy

		if game.levels[1].Walkable(x, y) {
			if err := game.levels[1].MoveActor(game.player, x, y); err != nil {
				t.Fatal(err)
			}

			entry.DX = direction.dx
			entry.DY = direction.dy
			foundEntry = true
			break
		}
	}

	if !foundEntry {
		t.Fatal("trap has no walkable approach")
	}

	if err := game.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	state, found := store.Get(trap)

	if !found {
		t.Fatal("authored trap has no state")
	}

	if err := state.Set("revealed", false); err != nil {
		t.Fatal(err)
	}

	for _, entity := range game.View().Entities {
		if entity.ID == uint64(trap) {
			t.Fatal("hidden trap appears in the dungeon view")
		}
	}

	if err := state.Set("revealed", true); err != nil {
		t.Fatal(err)
	}

	visibleTrap := false

	for _, entity := range game.View().Entities {
		if entity.ID == uint64(trap) &&
			entity.Role == "trap" &&
			entity.Glyph == '^' &&
			entity.Name == "teleport trap" {
			visibleTrap = true
		}
	}

	if !visibleTrap {
		t.Fatal("authored trap is absent from the dungeon view")
	}

	loaded, err := RestoreWithRules(game.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if len(loaded.scripts.Components()[trapSchema].Entities()) != 1 {
		t.Fatal("authored trap disappeared on restore")
	}

	floorItem, err := game.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Items.Set(floorItem, ecs.Item{
		KindID:   "POT_CURING",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := game.stores.Positions.Set(floorItem, *position); err != nil {
		t.Fatal(err)
	}

	result, err := game.Step(entry)

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("trap entry spent %d aut, want 10", result.Spent)
	}

	continued, err := loaded.Step(entry)

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(result.Events, continued.Events) {
		t.Fatalf("trap events changed after restore: live=%+v restored=%+v",
			result.Events, continued.Events)
	}

	if !reflect.DeepEqual(game.Snapshot().RNG, loaded.Snapshot().RNG) {
		t.Fatal("trap RNG changed after restore")
	}

	if len(store.Entities()) != 0 {
		player, _ := game.stores.Positions.Get(game.player)
		t.Fatalf("one-shot trap remained after entry: trap=%+v player=%+v events=%+v",
			position, player, result.Events)
	}

	for _, entity := range game.View().Entities {
		if entity.ID == uint64(trap) {
			t.Fatal("consumed trap appears in the dungeon view")
		}
	}

	itemPosition, stillPresent := game.stores.Positions.Get(floorItem)

	if !stillPresent ||
		itemPosition.X != position.X ||
		itemPosition.Y != position.Y ||
		!game.stores.Items.Has(floorItem) {
		t.Fatal("consuming the trap removed its floor item")
	}
}
