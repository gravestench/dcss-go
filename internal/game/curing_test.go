package game

import (
	"reflect"
	"strings"
	"testing"

	"github.com/gravestench/akara"
)

func carryCuring(t *testing.T, g *Game) uint64 {
	t.Helper()

	if err := g.levels[1].MoveActor(ratID(t, g), 14, 7); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 4, 2); err != nil {
		t.Fatal(err)
	}

	if result, err := g.Step(Command{Kind: CommandPickup}); err != nil ||
		result.Spent != 10 {
		t.Fatalf("pickup = %+v, %v", result, err)
	}

	return uint64(potionID(t, g))
}

func TestQuaffCuringHealsConsumesAndSchedules(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	before, _ := g.stores.Health.Get(g.player)

	before.Current = 1

	start := g.currentAut
	result, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	})

	if err != nil ||
		result.Spent != 10 ||
		result.View.PlayerHP <= 1 ||
		result.View.PlayerHP > before.Max ||
		result.View.CurrentAut != start+10 {
		t.Fatalf("quaff = %+v, %v; want healing and time %d", result, err, start+10)
	}

	if g.world.EntityExists(akara.Entity(itemID)) {
		t.Fatal("last curing potion remained after quaff")
	}

	energy, _ := g.stores.MonsterEnergy.Get(ratID(t, g))

	if energy.Points != 70 {
		t.Fatalf("rat energy = %d, want an action during quaff", energy.Points)
	}
}

func TestQuaffAtFullHPStillConsumesOnePotion(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	item, _ := g.stores.Items.Get(potionID(t, g))

	item.Quantity = 2

	health, _ := g.stores.Health.Get(g.player)

	health.Current = health.Max

	first, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	})

	if err != nil ||
		first.Spent != 10 ||
		first.View.PlayerHP != health.Max ||
		item.Quantity != 1 {
		t.Fatalf("first quaff = %+v, %v; item %+v", first, err, item)
	}

	second, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	})

	if err != nil ||
		second.Spent != 10 ||
		g.world.EntityExists(akara.Entity(itemID)) {
		t.Fatalf("second quaff = %+v, %v", second, err)
	}
}

func TestQuaffRejectsWrongCarrierAndUsesAnotherPotion(t *testing.T) {
	g := newStepGame(t)
	itemID := uint64(potionID(t, g))
	before := g.Snapshot()
	result, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	})

	if err != nil ||
		result.Spent != 0 ||
		!strings.Contains(strings.ToLower(result.Events[0].Text), "carry") {
		t.Fatalf("floor quaff = %+v, %v", result, err)
	}

	if g.currentAut != Aut(before.CurrentAut) ||
		len(g.rng.States()) != len(before.RNG) {
		t.Fatal("rejected floor quaff spent time or RNG")
	}

	carryCuring(t, g)
	var mightID uint64

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)

		if item.KindID == "POT_MIGHT" {
			mightID = uint64(entity)
			item.KindID = "POT_FLIGHT"
			break
		}
	}

	before = g.Snapshot()
	result, err = g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: mightID,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 ||
		!strings.Contains(strings.ToLower(result.Events[0].Text), "buoyant") {
		t.Fatalf("flight quaff = %+v, %v", result, err)
	}

	if g.currentAut != Aut(before.CurrentAut)+10 {
		t.Fatal("flight quaff did not spend a turn")
	}
}

func TestQuaffSaveContinuation(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	command := Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	}

	left, leftErr := g.Step(command)
	right, rightErr := loaded.Step(command)

	if leftErr != nil ||
		rightErr != nil ||
		!reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("quaff continuation = %+v/%v versus %+v/%v", left, leftErr, right, rightErr)
	}
}
