package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/terrain"
	"github.com/gravestench/akara"
)

func newShopGame(t *testing.T) *Game {
	t.Helper()

	g, err := NewShopScenario(17, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	return g
}

func TestModAddedShopTypeHasRulesetIdentity(t *testing.T) {
	rules, err := modfs.Load("testdata/shop-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(19, "SP_HUMAN", "JOB_FIGHTER",
		"WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	snapshot := g.Snapshot()

	if snapshot.RulesetHash != rules.Hash() {
		t.Fatal("modded shop did not participate in ruleset identity")
	}

	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatalf("modded shop ruleset cannot restore its save: %v", err)
	}

	defer restored.Close()

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("base ruleset restored a save with a modded shop definition")
	}
}

func TestFixedDungeonPopulatesShopEntrance(t *testing.T) {
	g := newShopGame(t)
	shops := g.scripts.Components()["world.shop"].Entities()

	if len(shops) != 1 {
		t.Fatalf("fixed Dungeon shop count = %d, want 1", len(shops))
	}

	value, _ := g.scripts.Components()["world.shop"].Get(shops[0])
	fields, err := value.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	levelID := int(fields["level_id"].(int64))
	x := int(fields["x"].(int64))
	y := int(fields["y"].(int64))

	if cell := g.levels[levelID].terrain[y][x]; cell != terrain.ShopEntrance {
		t.Fatalf("shop cell = %s, want %s", cell, terrain.ShopEntrance)
	}

	if stock := g.scripts.Components()["shop.stock"].Entities(); len(stock) == 0 {
		t.Fatal("fixed Dungeon shop has no stock")
	}
}

func TestShopViewAndPurchaseUseSavedECSStock(t *testing.T) {
	g := newShopGame(t)

	if err := g.levels[1].MoveActor(g.player, 3, 2); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.wallet"].Set(
		g.player,
		map[string]any{
			"gold":      int64(10000),
			"purchases": int64(0),
		},
	); err != nil {
		t.Fatal(err)
	}

	shop, err := g.ShopAtPlayer("type")

	if err != nil {
		t.Fatal(err)
	}

	if !shop.Available ||
		len(shop.Items) != 3 ||
		shop.Gold != 10000 {
		t.Fatalf("shop view = %+v", shop)
	}

	first := shop.Items[0]
	_, err = g.BuyShopSelection(shop.ID, []ShopSelection{
		{
			ID:        first.ID,
			Price:     first.Price + 1,
			Quantity:  first.Quantity,
			Signature: first.Signature,
		},
	})

	if err == nil {
		t.Fatal("changed shop quote was accepted")
	}

	unchanged, err := g.ShopAtPlayer("type")

	if err != nil {
		t.Fatal(err)
	}

	if unchanged.Gold != shop.Gold ||
		len(unchanged.Items) != len(shop.Items) {
		t.Fatalf("rejected quote changed stock or gold: %+v, %v", unchanged, err)
	}

	result, err := g.BuyShop(shop.ID, []uint64{first.ID})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != first.Price || len(result.Acquired) != 1 {
		t.Fatalf("purchase = %+v, quoted price = %d", result, first.Price)
	}

	if g.scripts.Components()["shop.stock"].Has(akara.Entity(first.ID)) ||
		!g.stores.CarriedBy.Has(akara.Entity(first.ID)) {
		t.Fatal("purchased item did not transfer from stock to inventory")
	}

	after, err := g.ShopAtPlayer("type")

	if err != nil {
		t.Fatal(err)
	}

	if after.Gold != 10000-first.Price || len(after.Items) != 2 {
		t.Fatalf("shop after purchase = %+v", after)
	}
}

func TestShopStockAndWalletSaveRoundTrip(t *testing.T) {
	g := newStepGame(t)
	position, _ := g.stores.Positions.Get(g.player)
	shop, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.wallet"].Set(
		g.player,
		map[string]any{
			"gold":      int64(123),
			"purchases": int64(25),
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["world.shop"].Set(
		shop,
		map[string]any{
			"kind_id":  "SHOP_WEAPON",
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
			"name":     "Test Weapon Shop",
			"greed":    int64(12),
			"open":     true,
		},
	); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[position.LevelID].SetCell(
		position.X, position.Y, terrain.ShopEntrance,
	); err != nil {
		t.Fatal(err)
	}

	item, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(item, ecs.Item{
		KindID:   "WPN_CLUB",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["shop.stock"].Set(
		item,
		map[string]any{
			"shop_id": uint64(shop),
			"order":   int64(1),
		},
	); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("shop stock or wallet changed across save and restore")
	}

	if err := g.levels[position.LevelID].SetCell(
		position.X, position.Y, terrain.Floor,
	); err != nil {
		t.Fatal(err)
	}

	if _, err := Restore(g.Snapshot()); err == nil ||
		!strings.Contains(err.Error(), "shop") {
		t.Fatalf("shop without entrance terrain was accepted: %v", err)
	}

	if err := g.levels[position.LevelID].SetCell(
		position.X, position.Y, terrain.ShopEntrance,
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["shop.stock"].Set(item,
		map[string]any{
			"shop_id": uint64(999999),
			"order":   int64(1),
		}); err != nil {
		t.Fatal(err)
	}

	if _, err := Restore(g.Snapshot()); err == nil ||
		!strings.Contains(err.Error(), "shop") {
		t.Fatalf("orphan shop stock was accepted: %v", err)
	}
}
