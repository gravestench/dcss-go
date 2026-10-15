package game

import (
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
	"reflect"
	"testing"
)

func giveTestMonsterWeapon(t *testing.T, g *Game, monsterID akara.Entity) akara.Entity {
	return giveTestMonsterItem(t, g, monsterID, "WPN_DAGGER", "weapon", 1)
}

func giveTestMonsterItem(
	t *testing.T,
	g *Game,
	monsterID akara.Entity,
	kindID string,
	slot string,
	quantity int,
) akara.Entity {
	t.Helper()

	itemID, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(itemID, ecs.Item{
		KindID:   kindID,
		Quantity: quantity,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.CarriedBy.Set(itemID, ecs.CarriedBy{
		Holder: monsterID,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Equipped.Set(itemID, ecs.Equipped{
		Slot: slot,
	}); err != nil {
		t.Fatal(err)
	}

	return itemID
}

func TestRestoreRejectsMonsterItemInWrongSlot(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	monsterID := ratID(t, g)
	giveTestMonsterItem(t, g, monsterID, "MI_STONE", "weapon", 4)

	if loaded, err := Restore(g.Snapshot()); err == nil {
		loaded.Close()
		t.Fatal("accepted a missile in a weapon slot")
	}
}

func TestMonsterWeaponOwnershipSurvivesSaveRestore(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)
	weapon := giveTestMonsterWeapon(t, g, rat)
	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("monster equipment changed on restore")
	}

	carrier, found := loaded.stores.CarriedBy.Get(weapon)

	if !found ||
		carrier.Holder != rat ||
		!loaded.stores.Equipped.Has(weapon) {
		t.Fatal("restored monster lost its equipped weapon")
	}

	itemIndex := -1
	monsterIndex := -1

	for index, record := range snapshot.Entities {
		if record.ID == uint64(weapon) {
			itemIndex = index
		}

		if record.ID == uint64(rat) {
			monsterIndex = index
		}
	}

	if itemIndex < 0 || monsterIndex < 0 {
		t.Fatal("saved monster or weapon record missing")
	}

	snapshot.Entities[itemIndex], snapshot.Entities[monsterIndex] =
		snapshot.Entities[monsterIndex], snapshot.Entities[itemIndex]

	reordered, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer reordered.Close()

	carrier, found = reordered.stores.CarriedBy.Get(weapon)

	if !found || carrier.Holder != rat {
		t.Fatal("item-before-holder save lost its carrier")
	}
}

func TestRestoreRejectsWeaponPlusOutsideSourceShort(t *testing.T) {
	g := newStepGame(t)
	weaponID := giveTestMonsterWeapon(t, g, ratID(t, g))
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Plus = 32768

	if _, err := Restore(g.Snapshot()); err == nil {
		t.Fatal("restored a weapon enchantment outside C++ short range")
	}
}

func TestRestoreRejectsInvalidMonsterWeaponOwner(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	weapon := giveTestMonsterWeapon(t, g, ratID(t, g))
	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID == uint64(weapon) {
			snapshot.Entities[index].CarriedBy.Holder = akara.Entity(999999)
			break
		}
	}

	if loaded, err := Restore(snapshot); err == nil {
		loaded.Close()
		t.Fatal("accepted item carried by a missing monster")
	}
}

func TestRestoreRejectsTwoEquippedMonsterWeapons(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)
	giveTestMonsterWeapon(t, g, rat)
	giveTestMonsterWeapon(t, g, rat)

	if loaded, err := Restore(g.Snapshot()); err == nil {
		loaded.Close()
		t.Fatal("accepted two weapons in one monster equipment slot")
	}
}

func TestDeadMonsterDropsItsWeaponEntity(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)
	weapon := giveTestMonsterWeapon(t, g, rat)
	position, _ := g.stores.Positions.Get(rat)
	deathCell := *position

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)

	health.Current = 1

	playerHealth, _ := g.stores.Health.Get(g.player)
	originalMax := playerHealth.Max

	playerHealth.Current = 100
	playerHealth.Max = 100

	for attempt := 0; attempt < 100 && g.world.EntityExists(rat); attempt++ {
		if _, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		}); err != nil {
			t.Fatal(err)
		}
	}

	if g.world.EntityExists(rat) {
		t.Fatal("monster survived repeated player attacks")
	}

	if g.stores.CarriedBy.Has(weapon) || g.stores.Equipped.Has(weapon) {
		t.Fatal("dead monster still owns its weapon")
	}

	dropped, found := g.stores.Positions.Get(weapon)

	if !found || *dropped != deathCell {
		t.Fatalf("weapon drop = %+v, found=%v", dropped, found)
	}

	playerHealth.Max = originalMax
	playerHealth.Current = originalMax

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("dropped monster weapon changed on restore")
	}

	if err := g.levels[1].MoveActor(g.player, deathCell.X, deathCell.Y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	carrier, found := g.stores.CarriedBy.Get(weapon)

	if !found ||
		carrier.Holder != g.player ||
		g.stores.Positions.Has(weapon) {
		t.Fatal("player could not pick up the dropped monster weapon")
	}
}
