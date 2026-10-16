package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/vault"
	"github.com/gravestench/akara"
)

func TestVaultPopulationMaterializesSourceSelections(t *testing.T) {
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

	level := g.levels[1]

	if level.VaultID() != "zz_vault_population" {
		t.Fatalf("selected vault = %s", level.VaultID())
	}

	objects := 0

	for _, record := range level.VaultRecords() {
		if record.Kind != vault.KindMonster && record.Kind != vault.KindItem {
			continue
		}

		if record.Pending {
			t.Fatalf("authored source stayed pending: %s", record.Identity)
		}

		objects++
	}

	if objects != 4 {
		t.Fatalf("materialized source objects = %d, want 4", objects)
	}

	snapshot := g.Snapshot()
	origins := 0
	plant := false
	goblin := false
	skeleton := false
	stones := false

	for _, entity := range snapshot.Entities {
		for _, dynamic := range entity.Dynamic {
			if dynamic.Schema == "vault.origin" {
				origins++
			}
		}

		if entity.Actor != nil && entity.Actor.KindID == "MONS_PLANT" {
			plant = true
		}

		if entity.Actor != nil && entity.Actor.KindID == "MONS_GOBLIN" {
			goblin = true
		}

		if entity.Item != nil &&
			entity.Item.KindID == "CORPSE_SKELETON" &&
			entity.Corpse != nil &&
			entity.Corpse.MonsterID == "MONS_HUMAN" {
			skeleton = true
		}

		if entity.Item != nil &&
			entity.Item.KindID == "MI_STONE" &&
			entity.Item.Quantity == 4 {
			stones = true
		}
	}

	if origins != 5 ||
		!plant ||
		!goblin ||
		!skeleton ||
		!stones {
		t.Fatalf("vault ECS population: origins=%d plant=%t goblin=%t skeleton=%t stones=%t",
			origins, plant, goblin, skeleton, stones)
	}
}

func TestVaultPopulationClientAndRestore(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-population-client")

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

	if g.levels[1].VaultID() != "zz_vault_population_client" {
		t.Fatalf("selected vault = %s", g.levels[1].VaultID())
	}

	initial := g.Snapshot()
	var sproutID uint64
	var stoneX int
	var stoneY int
	var stoneID uint64
	actorCount := 0
	itemCount := 0
	neutral := false
	friendly := false
	gold := false
	randomKind := false

	for _, entity := range initial.Entities {
		if entity.Actor != nil &&
			entity.Position != nil &&
			entity.Position.LevelID == 1 &&
			entity.ID != initial.PlayerID {
			for _, dynamic := range entity.Dynamic {
				if dynamic.Schema == "vault.origin" {
					actorCount++
				}
			}
		}

		if entity.Actor != nil && entity.Actor.KindID == "MONS_VAULT_SPROUT" {
			sproutID = entity.ID
		}

		for _, dynamic := range entity.Dynamic {
			if dynamic.Schema != "vault.actor_overrides" {
				continue
			}

			attitude := string(dynamic.Values["attitude"])
			neutral = neutral || attitude == `"neutral"`
			friendly = friendly || (entity.ID == sproutID &&
				attitude == `"friendly"` &&
				string(dynamic.Values["colour"]) == `"red"`)
		}

		if entity.Item != nil &&
			entity.Position != nil &&
			entity.Position.LevelID == 1 {
			for _, dynamic := range entity.Dynamic {
				if dynamic.Schema == "vault.origin" {
					itemCount++
				}
			}
		}

		if entity.Item != nil &&
			entity.Item.KindID == "MI_STONE" &&
			entity.Item.Quantity == 4 &&
			entity.Position != nil {
			stoneID = entity.ID
			stoneX = entity.Position.X
			stoneY = entity.Position.Y
		}

		gold = gold || entity.Item != nil &&
			entity.Item.KindID == "OBJ_GOLD" &&
			entity.Item.Quantity > 0
	}

	for _, record := range g.levels[1].VaultRecords() {
		if record.Kind != vault.KindMonster || record.Identity != "0" {
			continue
		}

		for _, argument := range record.Arguments {
			randomKind = randomKind ||
				(argument.Name == "kind_id" && argument.String != "")
		}
	}

	if actorCount != 4 ||
		itemCount != 3 ||
		sproutID == 0 ||
		stoneID == 0 ||
		!neutral ||
		!friendly ||
		!gold ||
		!randomKind {
		t.Fatalf("vault content: actors=%d items=%d sprout=%d stones=%d neutral=%t friendly=%t gold=%t random=%t",
			actorCount, itemCount, sproutID, stoneID, neutral, friendly, gold, randomKind)
	}

	playerPosition, _ := g.stores.Positions.Get(g.player)
	nearby := [][2]int{
		{playerPosition.X, playerPosition.Y - 1},
		{playerPosition.X, playerPosition.Y + 1},
		{playerPosition.X - 1, playerPosition.Y},
		{playerPosition.X + 1, playerPosition.Y},
	}

	moved := false

	for _, cell := range nearby {
		if err := g.levels[1].MoveActor(akara.Entity(sproutID), cell[0], cell[1]); err == nil {
			moved = true
			break
		}
	}

	if !moved {
		t.Fatal("no free tile beside player for mod-added vault monster")
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	visible := false

	for _, entity := range g.View().Entities {
		if entity.ID == sproutID {
			visible = entity.Glyph == 'P' &&
				entity.Name == "vault sprout" &&
				entity.ColorID == "red"
		}
	}

	if !visible {
		t.Fatalf("mod-added vault sprout is absent from the client view: %+v", g.View().Entities)
	}

	if err := g.levels[1].MoveActor(g.player, stoneX, stoneY); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	if !g.stores.CarriedBy.Has(akara.Entity(stoneID)) {
		t.Fatal("authored stone stack was not picked up")
	}

	before := g.Snapshot()
	restored, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("client interaction changed vault population on restore")
	}
}
