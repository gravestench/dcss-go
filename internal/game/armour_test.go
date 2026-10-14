package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func addCarriedArmour(t *testing.T, g *Game, kindID string) akara.Entity {
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

func TestTakeOffArmourSpendsFiveTurnsAndCanBeInterrupted(t *testing.T) {
	g := newStepGame(t)
	shield := carriedItemByKind(t, g, "ARM_BUCKLER")
	start := g.View().CurrentAut

	first, err := g.Step(Command{
		Kind:   CommandTakeOff,
		ItemID: uint64(shield),
	})

	if err != nil || first.Spent != 10 || !g.stores.Equipped.Has(shield) {
		t.Fatalf("takeoff start = %+v, %v", first, err)
	}

	for turn := 0; turn < 3; turn++ {
		result, err := g.Step(Command{Kind: CommandContinueEquipment})

		if err != nil || result.Spent != 10 || !g.stores.Equipped.Has(shield) {
			t.Fatalf("takeoff turn %d = %+v, %v", turn, result, err)
		}

		if len(result.Events) == 0 ||
			!strings.Contains(result.Events[len(result.Events)-1].Text, "continue taking off") {
			t.Fatalf("takeoff turn %d lacks source continuation text", turn)
		}
	}

	if g.View().CurrentAut != start+40 {
		t.Fatal("equipment delay skipped scheduled turns")
	}

	cancelled, err := g.Step(Command{Kind: CommandCancelEquipment})

	if err != nil || cancelled.Spent != 0 || !g.stores.Equipped.Has(shield) {
		t.Fatalf("cancelled takeoff = %+v, %v", cancelled, err)
	}

	if g.View().EquipmentDelay != nil {
		t.Fatal("cancelled delay remains active")
	}
}

func TestArmourSwapSavesMidDelayAndChangesDefenseAtFinish(t *testing.T) {
	g := newStepGame(t)
	old := carriedItemByKind(t, g, "ARM_SCALE_MAIL")
	plate := addCarriedArmour(t, g, "ARM_PLATE_ARMOUR")
	startDefense := g.View().PlayerAC
	rat := ratID(t, g)
	ratActor, _ := g.stores.Actors.Get(rat)
	initialMonsterAut := ratActor.NextAut

	first, err := g.Step(Command{
		Kind:   CommandWear,
		ItemID: uint64(plate),
	})

	if err != nil || first.Spent != 10 || !g.stores.Equipped.Has(old) {
		t.Fatalf("armour swap start = %+v, %v", first, err)
	}

	if ratActor.NextAut <= initialMonsterAut {
		t.Fatal("monster did not act during armour swap command turn")
	}

	monsterAutAfterStart := ratActor.NextAut

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	restoredRat, _ := restored.stores.Actors.Get(rat)

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("equipment delay changed across save and restore")
	}

	for turn := 2; turn <= 10; turn++ {
		result, err := restored.Step(Command{Kind: CommandContinueEquipment})

		if err != nil || result.Spent != 10 {
			t.Fatalf("armour swap turn %d = %+v, %v", turn, result, err)
		}

		if turn < 5 && result.View.PlayerAC != startDefense {
			t.Fatalf("armour changed before removal completed on turn %d", turn)
		}

		if turn == 5 {
			if restoredRat.NextAut <= monsterAutAfterStart {
				t.Fatal("monster did not act during removal phase")
			}

			if restored.stores.Equipped.Has(old) || restored.stores.Equipped.Has(plate) {
				t.Fatal("swap did not leave the body slot empty after removal")
			}

			midSwap, restoreErr := Restore(restored.Snapshot(), testCatalog(t))

			if restoreErr != nil {
				t.Fatal(restoreErr)
			}

			if !reflect.DeepEqual(restored.Snapshot(), midSwap.Snapshot()) {
				t.Fatal("wear phase changed across save and restore")
			}

			midSwap.Close()
		}
	}

	if restored.stores.Equipped.Has(old) || !restored.stores.Equipped.Has(plate) {
		t.Fatal("armour swap did not equip the new armour")
	}

	if restored.View().EquipmentDelay != nil {
		t.Fatal("completed delay remains active")
	}

	if restored.View().PlayerAC <= startDefense {
		t.Fatal("plate armour did not raise final AC")
	}

	if restoredRat.NextAut <= monsterAutAfterStart {
		t.Fatal("monster did not act during wear phase")
	}
}

func TestRestoreRejectsEquipmentDelayWithMissingItem(t *testing.T) {
	g := newStepGame(t)
	shield := carriedItemByKind(t, g, "ARM_BUCKLER")

	if _, err := g.Step(Command{
		Kind:   CommandTakeOff,
		ItemID: uint64(shield),
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID == uint64(g.player) {
			snapshot.Entities[index].Equipment.OldItemID = 999999
		}
	}

	if restored, err := Restore(snapshot, testCatalog(t)); err == nil {
		restored.Close()
		t.Fatal("missing delay item was accepted")
	}
}

func TestRestoreRejectsPendingShieldWithTwoHandedWeapon(t *testing.T) {
	g := newStepGame(t)
	shield := carriedItemByKind(t, g, "ARM_BUCKLER")
	g.stores.Equipped.Remove(shield)

	greatSword := addCarriedWeapon(t, g, "WPN_GREAT_SWORD")
	result, err := g.Step(Command{
		Kind:   CommandWield,
		ItemID: uint64(greatSword),
	})

	if err != nil || result.Spent == 0 {
		t.Fatalf("great sword wield = %+v, %v", result, err)
	}

	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID == snapshot.PlayerID {
			snapshot.Entities[index].Equipment = &ecs.EquipmentDelay{
				ItemID:    shield,
				Slot:      "shield",
				Phase:     "wear",
				Remaining: armourEquipTurns - 1,
			}
		}
	}

	if restored, err := Restore(snapshot, testCatalog(t)); err == nil {
		restored.Close()
		t.Fatal("incompatible delayed shield wear was accepted")
	}
}

func TestRestoreRejectsImpossibleRemovalTurnCount(t *testing.T) {
	g := newStepGame(t)
	shield := carriedItemByKind(t, g, "ARM_BUCKLER")

	if _, err := g.Step(Command{
		Kind:   CommandTakeOff,
		ItemID: uint64(shield),
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID == snapshot.PlayerID {
			snapshot.Entities[index].Equipment.Remaining = armourEquipTurns
		}
	}

	if restored, err := Restore(snapshot, testCatalog(t)); err == nil {
		restored.Close()
		t.Fatal("impossible removal turn count was accepted")
	}
}
