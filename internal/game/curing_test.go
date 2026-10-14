package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/character"
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
	if result, err := g.Step(Command{Kind: CommandPickup}); err != nil || result.Spent != 10 {
		t.Fatalf("pickup = %+v, %v", result, err)
	}
	return uint64(potionID(t, g))
}

func TestQuaffCuringHealsConsumesAndSchedules(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	before, _ := g.stores.Health.Get(g.player)
	before.Current = 1
	expectedRoller := RestoreRNGStreams(g.seed, g.rng.States())
	want, err := character.CuringHP(expectedRoller, 1, before.Max)
	if err != nil {
		t.Fatal(err)
	}
	start := g.currentAut
	result, err := g.Step(Command{Kind: CommandQuaff, ItemID: itemID})
	if err != nil || result.Spent != 10 || result.View.PlayerHP != want || result.View.CurrentAut != start+10 {
		t.Fatalf("quaff = %+v, %v; want HP %d and time %d", result, err, want, start+10)
	}
	if g.world.EntityExists(akara.Entity(itemID)) {
		t.Fatal("last curing potion remained after quaff")
	}
	if !reflect.DeepEqual(expectedRoller.States()["potion"], g.rng.States()["potion"]) {
		t.Fatal("quaff used the wrong number of potion draws")
	}
	monsterActs := 0
	for _, event := range result.Events {
		if event.Kind == "monster" {
			monsterActs++
		}
	}
	if monsterActs != 1 {
		t.Fatalf("rat acted %d times during quaff", monsterActs)
	}
}

func TestQuaffAtFullHPStillConsumesOnePotion(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	item, _ := g.stores.Items.Get(potionID(t, g))
	item.Quantity = 2
	health, _ := g.stores.Health.Get(g.player)
	health.Current = health.Max
	first, err := g.Step(Command{Kind: CommandQuaff, ItemID: itemID})
	if err != nil || first.Spent != 10 || first.View.PlayerHP != health.Max || item.Quantity != 1 {
		t.Fatalf("first quaff = %+v, %v; item %+v", first, err, item)
	}
	second, err := g.Step(Command{Kind: CommandQuaff, ItemID: itemID})
	if err != nil || second.Spent != 10 || g.world.EntityExists(akara.Entity(itemID)) {
		t.Fatalf("second quaff = %+v, %v", second, err)
	}
}

func TestQuaffRejectsWrongItemAndCarrierWithoutTimeOrDraw(t *testing.T) {
	g := newStepGame(t)
	itemID := uint64(potionID(t, g))
	before := g.Snapshot()
	result, err := g.Step(Command{Kind: CommandQuaff, ItemID: itemID})
	if err != nil || result.Spent != 0 || !strings.Contains(strings.ToLower(result.Events[0].Text), "carry") {
		t.Fatalf("floor quaff = %+v, %v", result, err)
	}
	if g.currentAut != Aut(before.CurrentAut) || len(g.rng.States()) != len(before.RNG) {
		t.Fatal("rejected floor quaff spent time or RNG")
	}
	carryCuring(t, g)
	var mightID uint64
	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		if item.KindID == "POT_MIGHT" {
			mightID = uint64(entity)
			item.KindID = "POT_HASTE" // another carried catalogued potion is still unsupported
			break
		}
	}
	before = g.Snapshot()
	result, err = g.Step(Command{Kind: CommandQuaff, ItemID: mightID})
	if err != nil || result.Spent != 0 || !strings.Contains(strings.ToLower(result.Events[0].Text), "unavailable") {
		t.Fatalf("unsupported quaff = %+v, %v", result, err)
	}
	if g.currentAut != Aut(before.CurrentAut) || !reflect.DeepEqual(g.rng.States(), before.RNG) {
		t.Fatal("unsupported quaff spent time or RNG")
	}
}

func TestQuaffSaveContinuation(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	loaded, err := Restore(g.Snapshot(), testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	command := Command{Kind: CommandQuaff, ItemID: itemID}
	left, leftErr := g.Step(command)
	right, rightErr := loaded.Step(command)
	if leftErr != nil || rightErr != nil || !reflect.DeepEqual(left, right) || !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("quaff continuation = %+v/%v versus %+v/%v", left, leftErr, right, rightErr)
	}
}
