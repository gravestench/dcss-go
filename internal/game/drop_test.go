package game

import (
	"reflect"
	"testing"

	"github.com/gravestench/akara"
)

func carriedItemByKind(t *testing.T, g *Game, kindID string) akara.Entity {
	t.Helper()

	for _, entity := range g.stores.CarriedBy.Entities() {
		carrier, _ := g.stores.CarriedBy.Get(entity)
		item, found := g.stores.Items.Get(entity)

		if found &&
			carrier.Holder == g.player && item.KindID == kindID {
			return entity
		}
	}

	t.Fatalf("carried %s missing", kindID)

	return 0
}

func TestDropFullItemAndPickItUpAgain(t *testing.T) {
	g := newStepGame(t)
	itemID := carriedItemByKind(t, g, "POT_MIGHT")
	playerPosition, _ := g.stores.Positions.Get(g.player)
	result, err := g.Step(Command{
		Kind:   CommandDrop,
		ItemID: uint64(itemID),
	})

	if err != nil ||
		result.Spent != 10 || g.stores.CarriedBy.Has(itemID) {
		t.Fatalf("drop = %+v, %v; still carried=%v", result, err, g.stores.CarriedBy.Has(itemID))
	}

	position, found := g.stores.Positions.Get(itemID)

	if !found || *position != *playerPosition {
		t.Fatalf("dropped item position = %+v, found=%v", position, found)
	}

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	if !g.stores.CarriedBy.Has(itemID) || g.stores.Positions.Has(itemID) {
		t.Fatal("dropped potion could not be picked up again")
	}
}

func TestPartialDropMergesMatchingFloorStackAndSaves(t *testing.T) {
	g := newStepGame(t)
	itemID := carriedItemByKind(t, g, "POT_MIGHT")
	item, _ := g.stores.Items.Get(itemID)

	item.Quantity = 3

	first, err := g.Step(Command{
		Kind:     CommandDrop,
		ItemID:   uint64(itemID),
		Quantity: 2,
	})

	if err != nil ||
		first.Spent != 10 || item.Quantity != 1 {
		t.Fatalf("partial drop = %+v, %v; carried quantity=%d", first, err, item.Quantity)
	}

	position, _ := g.stores.Positions.Get(g.player)
	floor, found := g.floorItemAt(*position)

	if !found || floor == itemID {
		t.Fatalf("partial drop did not create a separate floor stack: %d", floor)
	}

	dropped, _ := g.stores.Items.Get(floor)

	if dropped.Quantity != 2 || dropped.KindID != item.KindID {
		t.Fatalf("floor stack = %+v", dropped)
	}

	second, err := g.Step(Command{
		Kind:     CommandDrop,
		ItemID:   uint64(itemID),
		Quantity: 10,
	})

	if err != nil ||
		second.Spent != 10 ||
		dropped.Quantity != 3 ||
		g.stores.Items.Has(itemID) {
		t.Fatalf("merged drop = %+v, %v; floor=%+v; old item=%v", second, err, dropped, g.stores.Items.Has(itemID))
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("drop state changed across save and restore")
	}
}

func TestDropEquipmentRulesAndInvalidRequests(t *testing.T) {
	g := newStepGame(t)
	armour := carriedItemByKind(t, g, "ARM_SCALE_MAIL")
	shield := carriedItemByKind(t, g, "ARM_BUCKLER")

	weapon := carriedItemByKind(t, g, "WPN_RAPIER")
	before := g.Snapshot()

	for _, id := range []akara.Entity{armour, shield} {
		result, err := g.Step(Command{
			Kind:   CommandDrop,
			ItemID: uint64(id),
		})

		if err != nil ||
			result.Spent != 0 {
			t.Fatalf("equipped armour/shield drop = %+v, %v", result, err)
		}
	}

	for _, command := range []Command{
		{
			Kind:   CommandDrop,
			ItemID: 999999,
		},

		{
			Kind:     CommandDrop,
			ItemID:   uint64(weapon),
			Quantity: -1,
		},
	} {
		result, err := g.Step(command)

		if err != nil ||
			result.Spent != 0 {
			t.Fatalf("invalid drop = %+v, %v", result, err)
		}
	}

	after := g.Snapshot()

	before.Messages = after.Messages

	if !reflect.DeepEqual(before, after) {
		t.Fatal("rejected drops changed game state")
	}

	result, err := g.Step(Command{
		Kind:   CommandDrop,
		ItemID: uint64(weapon),
	})

	if err != nil ||
		result.Spent != 10 || g.stores.Equipped.Has(weapon) {
		t.Fatalf("weapon drop = %+v, %v; equipped=%v", result, err, g.stores.Equipped.Has(weapon))
	}

	if !g.stores.Positions.Has(weapon) || g.stores.CarriedBy.Has(weapon) {
		t.Fatal("unwielded weapon is not on the floor")
	}

	if _, err := newPlayerCombat(g).attackDelayInput("MONS_RAT"); err != nil {
		t.Fatalf("unarmed follow-up unavailable: %v", err)
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatalf("save with dropped weapon was rejected: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("dropped weapon changed across save and restore")
	}
}

func TestPickupMergesReturnedPartialStack(t *testing.T) {
	g := newStepGame(t)
	carriedID := carriedItemByKind(t, g, "POT_MIGHT")
	carried, _ := g.stores.Items.Get(carriedID)

	carried.Quantity = 3

	if _, err := g.Step(Command{
		Kind:     CommandDrop,
		ItemID:   uint64(carriedID),
		Quantity: 2,
	}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	floorID, found := g.floorItemAt(*position)

	if !found {
		t.Fatal("partial drop did not leave a floor stack")
	}

	result, err := g.Step(Command{Kind: CommandPickup})

	if err != nil ||
		result.Spent != 10 ||
		carried.Quantity != 3 ||
		g.stores.Items.Has(floorID) {
		t.Fatalf(
			"returned stack = %+v, %v; carried=%+v floor=%v",
			result,
			err,
			carried,
			g.stores.Items.Has(floorID),
		)
	}
}

func TestRestoreAfterPickingUpDroppedWeapon(t *testing.T) {
	g := newStepGame(t)
	weapon := carriedItemByKind(t, g, "WPN_RAPIER")

	if _, err := g.Step(Command{
		Kind:   CommandDrop,
		ItemID: uint64(weapon),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	if !g.stores.CarriedBy.Has(weapon) || g.stores.Equipped.Has(weapon) {
		t.Fatal("picked up weapon should remain carried and unequipped")
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatalf("save with carried unequipped weapon was rejected: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("carried unequipped weapon changed across save and restore")
	}
}

func TestStackTransfersDoNotOverflowQuantity(t *testing.T) {
	maxInt := int(^uint(0) >> 1)

	t.Run("drop", func(t *testing.T) {
		g := newStepGame(t)
		carriedID := carriedItemByKind(t, g, "POT_MIGHT")
		carried, _ := g.stores.Items.Get(carriedID)

		carried.Quantity = 2

		if _, err := g.Step(Command{
			Kind:     CommandDrop,
			ItemID:   uint64(carriedID),
			Quantity: 1,
		}); err != nil {
			t.Fatal(err)
		}

		position, _ := g.stores.Positions.Get(g.player)
		floorID, _ := g.floorItemAt(*position)
		floor, _ := g.stores.Items.Get(floorID)

		floor.Quantity = maxInt

		if _, err := g.Step(Command{
			Kind:   CommandDrop,
			ItemID: uint64(carriedID),
		}); err != nil {
			t.Fatal(err)
		}

		if floor.Quantity != maxInt {
			t.Fatalf("full floor stack overflowed to %d", floor.Quantity)
		}

		if g.stores.CarriedBy.Has(carriedID) || !g.stores.Positions.Has(carriedID) {
			t.Fatal("overflowing drop did not leave a second floor stack")
		}
	})

	t.Run("pickup", func(t *testing.T) {
		g := newStepGame(t)
		carriedID := carriedItemByKind(t, g, "POT_MIGHT")
		carried, _ := g.stores.Items.Get(carriedID)

		carried.Quantity = 2

		if _, err := g.Step(Command{
			Kind:     CommandDrop,
			ItemID:   uint64(carriedID),
			Quantity: 1,
		}); err != nil {
			t.Fatal(err)
		}

		carried.Quantity = maxInt

		position, _ := g.stores.Positions.Get(g.player)
		floorID, _ := g.floorItemAt(*position)

		if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
			t.Fatal(err)
		}

		if carried.Quantity != maxInt {
			t.Fatalf("full carried stack overflowed to %d", carried.Quantity)
		}

		if !g.stores.CarriedBy.Has(floorID) || g.stores.Positions.Has(floorID) {
			t.Fatal("overflowing pickup did not leave a second carried stack")
		}
	})
}
