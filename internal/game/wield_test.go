package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func addCarriedWeapon(t *testing.T, g *Game, kindID string) akara.Entity {
	t.Helper()

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(entity, ecs.Item{
		KindID:   kindID,
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.CarriedBy.Set(entity, ecs.CarriedBy{
		Holder: g.player,
	}); err != nil {
		t.Fatal(err)
	}

	return entity
}

func TestWieldRecoveredStartingWeaponAfterBareHands(t *testing.T) {
	g := newStepGame(t)
	weapon := carriedItemByKind(t, g, "WPN_RAPIER")

	bare, err := g.Step(Command{Kind: CommandWield})

	if err != nil || bare.Spent != 3 || g.stores.Equipped.Has(weapon) {
		t.Fatalf("bare hands = %+v, %v; weapon equipped=%v", bare, err, g.stores.Equipped.Has(weapon))
	}

	input, err := newPlayerCombat(g).attackDelayInput("MONS_RAT")

	if err != nil || !input.Unarmed {
		t.Fatalf("bare-hands attack = %+v, %v", input, err)
	}

	alreadyBare, err := g.Step(Command{Kind: CommandWield})

	if err != nil || alreadyBare.Spent != 0 {
		t.Fatalf("already bare = %+v, %v", alreadyBare, err)
	}

	if _, err := g.Step(Command{
		Kind:   CommandDrop,
		ItemID: uint64(weapon),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	wielded, err := g.Step(Command{
		Kind:   CommandWield,
		ItemID: uint64(weapon),
	})

	if err != nil || wielded.Spent != 5 || !g.stores.Equipped.Has(weapon) {
		t.Fatalf("re-wield = %+v, %v; equipped=%v", wielded, err, g.stores.Equipped.Has(weapon))
	}

	input, err = newPlayerCombat(g).attackDelayInput("MONS_RAT")

	if err != nil || input.Unarmed || input.WeaponSkillID != "SK_SHORT_BLADES" {
		t.Fatalf("re-wield attack = %+v, %v", input, err)
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("re-wield state changed across save and restore")
	}
}

func TestWieldAlternateCarriedWeaponAndRestore(t *testing.T) {
	g := newStepGame(t)
	starting := carriedItemByKind(t, g, "WPN_RAPIER")
	flail := addCarriedWeapon(t, g, "WPN_FLAIL")
	result, err := g.Step(Command{
		Kind:   CommandWield,
		ItemID: uint64(flail),
	})

	if err != nil ||
		result.Spent != 5 ||
		g.stores.Equipped.Has(starting) ||
		!g.stores.Equipped.Has(flail) {
		t.Fatalf("weapon switch = %+v, %v", result, err)
	}

	input, err := newPlayerCombat(g).attackInput("MONS_RAT")

	if err != nil ||
		input.WeaponSkillID != "SK_MACES_FLAILS" ||
		input.WeaponSkill100 != 0 {
		t.Fatalf("untrained flail attack = %+v, %v", input, err)
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatalf("alternate equipped weapon was rejected: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("alternate weapon changed across save and restore")
	}
}

func TestWieldRejectsInvalidChoicesWithoutTime(t *testing.T) {
	g := newStepGame(t)
	starting := carriedItemByKind(t, g, "WPN_RAPIER")
	armour := carriedItemByKind(t, g, "ARM_SCALE_MAIL")

	twoHanded := addCarriedWeapon(t, g, "WPN_GREAT_SWORD")
	before := g.Snapshot()

	for _, itemID := range []akara.Entity{
		starting,
		armour,
		twoHanded,
		999999,
	} {
		result, err := g.Step(Command{
			Kind:   CommandWield,
			ItemID: uint64(itemID),
		})

		if err != nil || result.Spent != 0 {
			t.Fatalf("invalid wield %d = %+v, %v", itemID, result, err)
		}
	}

	after := g.Snapshot()
	before.Messages = after.Messages

	if !reflect.DeepEqual(before, after) || !g.stores.Equipped.Has(starting) {
		t.Fatal("rejected wield changed game state")
	}
}

func TestRestoreRejectsUnsupportedEquippedWeapon(t *testing.T) {
	for _, kindID := range []string{
		"WPN_GREAT_SWORD",
		"WPN_LONGBOW",
	} {
		t.Run(kindID, func(t *testing.T) {
			g := newStepGame(t)
			starting := carriedItemByKind(t, g, "WPN_RAPIER")
			other := addCarriedWeapon(t, g, kindID)
			snapshot := g.Snapshot()

			for index := range snapshot.Entities {
				record := &snapshot.Entities[index]

				switch akara.Entity(record.ID) {
				case starting:
					record.Equipped = nil

				case other:
					record.Equipped = &ecs.Equipped{
						Slot: "weapon",
					}
				}
			}

			_, err := Restore(snapshot, testCatalog(t))

			if err == nil || !strings.Contains(err.Error(), "equipped weapon") {
				t.Fatalf("restored impossible %s equipment: %v", kindID, err)
			}
		})
	}
}
