package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/character"
	"github.com/gravestench/akara"
)

func carryHealWounds(t *testing.T, g *Game) uint64 {
	t.Helper()
	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}
	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}
	if _, err := g.Step(Command{Kind: CommandMove, DX: 1}); err != nil {
		t.Fatal(err)
	}
	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}
	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		if item.KindID == "POT_HEAL_WOUNDS" {
			carrier, carried := g.stores.CarriedBy.Get(entity)
			if !carried || carrier.Holder != g.player {
				t.Fatal("heal wounds potion was not picked up")
			}
			return uint64(entity)
		}
	}
	t.Fatal("heal wounds potion missing")
	return 0
}

func TestHealWoundsFloorPickupQuaffAndSaveContinuation(t *testing.T) {
	g := newStepGame(t)
	itemID := carryHealWounds(t, g)
	health, _ := g.stores.Health.Get(g.player)
	health.Current = 1
	loaded, err := Restore(g.Snapshot(), testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	wantRolls := RestoreRNGStreams(g.seed, g.rng.States())
	wantHP, err := character.HealWoundsHP(wantRolls, 1, health.Max)
	if err != nil {
		t.Fatal(err)
	}
	command := Command{Kind: CommandQuaff, ItemID: itemID}
	left, leftErr := g.Step(command)
	right, rightErr := loaded.Step(command)
	if leftErr != nil || rightErr != nil || left.Spent != 10 || left.View.PlayerHP != wantHP || !reflect.DeepEqual(left, right) || !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("heal wounds continuation %+v/%v versus %+v/%v; want HP %d", left, leftErr, right, rightErr, wantHP)
	}
	if !reflect.DeepEqual(wantRolls.States()["potion"], g.rng.States()["potion"]) {
		t.Fatal("heal wounds used the wrong potion draws")
	}
	for _, item := range left.View.Inventory {
		if item.KindID == "POT_HEAL_WOUNDS" {
			t.Fatal("consumed potion remains carried")
		}
	}
}

func TestHealWoundsAtFullHPIsFreeAndKeepsPotion(t *testing.T) {
	g := newStepGame(t)
	itemID := carryHealWounds(t, g)
	before := g.Snapshot()
	result, err := g.Step(Command{Kind: CommandQuaff, ItemID: itemID})
	if err != nil || result.Spent != 0 || !strings.Contains(result.Events[0].Text, "already full") {
		t.Fatalf("full-HP quaff %+v, %v", result, err)
	}
	selected, found := g.stores.Items.Get(akara.Entity(itemID))
	if !found || selected.Quantity != 1 || g.currentAut != Aut(before.CurrentAut) || !reflect.DeepEqual(g.rng.States(), before.RNG) {
		t.Fatal("full-HP refusal consumed item, time, or RNG")
	}
}
