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

func removeFixtureRat(t *testing.T, g *Game) {
	t.Helper()

	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	if !g.world.DestroyEntity(rat) {
		t.Fatal("could not remove fixture rat")
	}
}

func TestTakeOffArmourSpendsFiveTurnsAndCanBeInterrupted(t *testing.T) {
	g := newStepGame(t)
	shield := carriedItemByKind(t, g, "ARM_BUCKLER")
	start := g.View().CurrentAut

	first, err := g.Step(Command{
		Kind:   CommandTakeOff,
		ItemID: uint64(shield),
	})

	if err != nil ||
		first.Spent != 10 || !g.stores.Equipped.Has(shield) {
		t.Fatalf("takeoff start = %+v, %v", first, err)
	}

	for turn := 0; turn < 3; turn++ {
		result, err := g.Step(Command{Kind: CommandContinueEquipment})

		if err != nil ||
			result.Spent != 10 || !g.stores.Equipped.Has(shield) {
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

	if err != nil ||
		cancelled.Spent != 0 || !g.stores.Equipped.Has(shield) {
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

	if err != nil ||
		first.Spent != 10 || !g.stores.Equipped.Has(old) {
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

func TestHumanWearsAuxiliaryArmourAcrossSavedDelay(t *testing.T) {
	cases := []struct {
		kindID string
		slot   string
	}{
		{
			kindID: "ARM_HELMET",
			slot:   "head",
		},

		{
			kindID: "ARM_CLOAK",
			slot:   "cloak",
		},

		{
			kindID: "ARM_GLOVES",
			slot:   "gloves",
		},

		{
			kindID: "ARM_BOOTS",
			slot:   "boots",
		},
	}

	for _, test := range cases {
		t.Run(test.slot, func(t *testing.T) {
			g := newStepGame(t)
			itemID := addCarriedArmour(t, g, test.kindID)
			start := g.View().CurrentAut

			first, err := g.Step(Command{
				Kind:   CommandWear,
				ItemID: uint64(itemID),
			})

			if err != nil ||
				first.Spent != 10 || first.View.EquipmentDelay == nil {
				t.Fatalf("wear start = %+v, %v", first, err)
			}

			if first.View.EquipmentDelay.Slot != test.slot ||
				g.stores.Equipped.Has(itemID) {
				t.Fatalf("%s was equipped before its delay", test.kindID)
			}

			restored, err := Restore(g.Snapshot(), testCatalog(t))

			if err != nil {
				t.Fatal(err)
			}

			t.Cleanup(func() {
				restored.Close()
			})

			for turn := 0; turn < 4; turn++ {
				result, stepErr := restored.Step(Command{Kind: CommandContinueEquipment})

				if stepErr != nil || result.Spent != 10 {
					t.Fatalf("wear turn %d = %+v, %v", turn, result, stepErr)
				}
			}

			equipped, found := restored.stores.Equipped.Get(itemID)

			if !found || equipped.Slot != test.slot {
				t.Fatalf("%s was not equipped in %s", test.kindID, test.slot)
			}

			if restored.View().EquipmentDelay != nil ||
				restored.View().CurrentAut != start+50 {
				t.Fatalf("%s did not finish after five turns", test.kindID)
			}
		})
	}
}

func TestHumanCannotWearBarding(t *testing.T) {
	for _, kindID := range []string{
		"ARM_BARDING",
		"ARM_CENTAUR_BARDING",
	} {
		t.Run(kindID, func(t *testing.T) {
			g := newStepGame(t)
			itemID := addCarriedArmour(t, g, kindID)
			start := g.View().CurrentAut

			result, err := g.Step(Command{
				Kind:   CommandWear,
				ItemID: uint64(itemID),
			})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent != 0 || result.View.CurrentAut != start {
				t.Fatalf("barding spent time: %+v", result)
			}

			if result.View.EquipmentDelay != nil ||
				len(result.Events) == 0 ||
				result.Events[0].Text != "You can't wear that!" {
				t.Fatalf("barding refusal = %+v", result)
			}
		})
	}
}

func TestAuxiliaryArmourChangesDefenseWhenDelayFinishes(t *testing.T) {
	g := newStepGame(t)
	removeFixtureRat(t, g)

	pieces := []struct {
		kindID string
		wantAC int
	}{
		{
			kindID: "ARM_HELMET",
			wantAC: 7,
		},

		{
			kindID: "ARM_CLOAK",
			wantAC: 9,
		},

		{
			kindID: "ARM_GLOVES",
			wantAC: 10,
		},

		{
			kindID: "ARM_BOOTS",
			wantAC: 11,
		},
	}

	if g.View().PlayerAC != 6 {
		t.Fatalf("starting AC = %d, want 6", g.View().PlayerAC)
	}

	var gloves akara.Entity

	for _, piece := range pieces {
		itemID := addCarriedArmour(t, g, piece.kindID)

		if piece.kindID == "ARM_GLOVES" {
			gloves = itemID
		}

		before := g.View().PlayerAC
		result, err := g.Step(Command{
			Kind:   CommandWear,
			ItemID: uint64(itemID),
		})

		if err != nil || result.Spent != 10 {
			t.Fatalf("wear %s start: spent %d, err %v", piece.kindID, result.Spent, err)
		}

		for turn := 0; turn < 3; turn++ {
			result, err = g.Step(Command{Kind: CommandContinueEquipment})

			if err != nil ||
				result.Spent != 10 || result.View.PlayerAC != before {
				t.Fatalf("%s changed AC during wear turn %d", piece.kindID, turn)
			}
		}

		result, err = g.Step(Command{Kind: CommandContinueEquipment})

		if err != nil ||
			result.Spent != 10 || result.View.PlayerAC != piece.wantAC {
			t.Fatalf("wear %s ended at AC %d, want %d: %v",
				piece.kindID, result.View.PlayerAC, piece.wantAC, err)
		}
	}

	result, err := g.Step(Command{
		Kind:   CommandTakeOff,
		ItemID: uint64(gloves),
	})

	if err != nil || result.Spent != 10 {
		t.Fatalf("remove gloves start: spent %d, err %v", result.Spent, err)
	}

	for turn := 0; turn < 3; turn++ {
		result, err = g.Step(Command{Kind: CommandContinueEquipment})

		if err != nil ||
			result.Spent != 10 || result.View.PlayerAC != 11 {
			t.Fatalf("gloves changed AC during removal turn %d", turn)
		}
	}

	result, err = g.Step(Command{Kind: CommandContinueEquipment})

	if err != nil ||
		result.Spent != 10 || result.View.PlayerAC != 10 {
		t.Fatalf("gloves removal ended at AC %d, want 10: %v", result.View.PlayerAC, err)
	}
}

func TestRestoreRejectsHumanWearingBarding(t *testing.T) {
	g := newStepGame(t)
	barding := addCarriedArmour(t, g, "ARM_BARDING")

	if _, err := g.stores.Equipped.Set(barding, ecs.Equipped{
		Slot: "boots",
	}); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err == nil {
		restored.Close()
		t.Fatal("restored barding on Human")
	}
}

func TestRestoreRejectsQueuedBarding(t *testing.T) {
	for _, kindID := range []string{
		"ARM_BARDING",
		"ARM_CENTAUR_BARDING",
	} {
		for _, phase := range []string{"remove", "wear"} {
			t.Run(kindID+"/"+phase, func(t *testing.T) {
				g := newStepGame(t)
				barding := addCarriedArmour(t, g, kindID)
				var boots akara.Entity

				if phase == "remove" {
					boots = addCarriedArmour(t, g, "ARM_BOOTS")

					if _, err := g.stores.Equipped.Set(boots, ecs.Equipped{
						Slot: "boots",
					}); err != nil {
						t.Fatal(err)
					}
				}

				if _, err := g.stores.Equipment.Set(g.player, ecs.EquipmentDelay{
					ItemID:    barding,
					OldItemID: boots,
					Slot:      "boots",
					Phase:     phase,
					Remaining: armourEquipTurns - 1,
				}); err != nil {
					t.Fatal(err)
				}

				restored, err := Restore(g.Snapshot(), testCatalog(t))

				if err == nil {
					restored.Close()
					t.Fatal("restored Human equipment delay for barding")
				}
			})
		}
	}
}

func TestAuxiliaryArmourSwapTakesTenTurnsAcrossSave(t *testing.T) {
	g := newStepGame(t)
	removeFixtureRat(t, g)

	helmet := addCarriedArmour(t, g, "ARM_HELMET")
	hat := addCarriedArmour(t, g, "ARM_HAT")

	if _, err := g.stores.Equipped.Set(helmet, ecs.Equipped{
		Slot: "head",
	}); err != nil {
		t.Fatal(err)
	}

	if g.View().PlayerAC != 7 {
		t.Fatalf("helmet AC = %d, want 7", g.View().PlayerAC)
	}

	first, err := g.Step(Command{
		Kind:   CommandWear,
		ItemID: uint64(hat),
	})

	if err != nil || first.Spent != 10 {
		t.Fatalf("swap start: spent %d, err %v", first.Spent, err)
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		restored.Close()
	})

	for turn := 2; turn <= 10; turn++ {
		result, stepErr := restored.Step(Command{Kind: CommandContinueEquipment})

		if stepErr != nil || result.Spent != 10 {
			t.Fatalf("swap turn %d: spent %d, err %v", turn, result.Spent, stepErr)
		}

		if turn == 5 {
			if restored.stores.Equipped.Has(helmet) ||
				restored.stores.Equipped.Has(hat) ||
				result.View.PlayerAC != 6 {
				t.Fatal("old helmet remained after removal phase")
			}
		}
	}

	equipped, found := restored.stores.Equipped.Get(hat)

	if !found ||
		equipped.Slot != "head" || restored.View().CurrentAut != 100 {
		t.Fatal("hat was not equipped after ten turns")
	}

	if restored.View().EquipmentDelay != nil || restored.View().PlayerAC != 6 {
		t.Fatal("head swap left a delay or wrong defense")
	}
}
