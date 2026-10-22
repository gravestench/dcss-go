package game

import (
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

// Create a visible floor pile through the hosted item and position stores.
// The next visibility refresh will pass its entity ID to Lua sighting policy.
func placeGoldUnderPlayer(t *testing.T, g *Game, quantity int) akara.Entity {
	t.Helper()

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	gold, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.stores.Items.Set(gold, ecs.Item{
		KindID:   "OBJ_GOLD",
		Quantity: quantity,
	})

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Positions.Set(gold, *position); err != nil {
		t.Fatal(err)
	}

	return gold
}

// A floor pile first seen while godless must retain its late-donation status
// through save and restore. The visibility host passes entity identity to
// Lua; the gold rule, rather than Go, decides what that sighting means.
func TestZinGoldSightingSurvivesSave(t *testing.T) {
	g := newStepGame(t)
	gold := placeGoldUnderPlayer(t, g, 20)

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	assertLateGold := func(current *Game) {
		t.Helper()

		store := current.scripts.Components()["item.gold_tithe"]
		state, present := store.Get(gold)

		if !present {
			t.Fatal("visible gold has no tithe state")
		}

		value, err := state.Get("state")

		if err != nil {
			t.Fatal(err)
		}

		if value != "no_piety" {
			t.Fatalf("gold tithe state = %v, want no_piety", value)
		}
	}

	assertLateGold(g)

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	assertLateGold(restored)
}

// Prayer and pickup exercise the real command systems. A pile seen before
// Zin takes two gold but awards no piety, and the wallet survives restore.
func TestZinLateGoldPickupAfterPrayer(t *testing.T) {
	g, err := NewDungeonGame(
		673,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	placePrayerAltar(t, g, "GOD_ZIN")
	placeGoldUnderPlayer(t, g, 20)

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	_, err = g.Step(Command{
		Kind:     CommandPray,
		TargetID: "GOD_ZIN",
		Forced:   true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if worshipGod(t, g) != "GOD_ZIN" {
		t.Fatal("prayer did not join Zin")
	}

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	assertCash := func(current *Game) {
		t.Helper()

		wallet, found := current.scripts.Components()["character.wallet"].Get(
			current.player,
		)

		if !found {
			t.Fatal("player has no wallet")
		}

		gold, goldErr := wallet.Get("gold")
		donations, donationErr := wallet.Get("donations")

		if goldErr != nil || donationErr != nil {
			t.Fatalf("read wallet: gold=%v, donations=%v",
				goldErr, donationErr)
		}

		if gold != int64(18) || donations != int64(2) {
			t.Fatalf("late gold: balance=%v donations=%v", gold, donations)
		}

		worship, found := current.scripts.Components()["religion.worship"].Get(
			current.player,
		)

		if !found {
			t.Fatal("player has no worship state")
		}

		piety, err := worship.Get("piety")

		if err != nil || piety != int64(15) {
			t.Fatalf("late donation piety=%v, error=%v", piety, err)
		}
	}

	assertCash(g)

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	assertCash(restored)

	// A newly seen pile uses the live Dungeon depth for ordinary piety.
	// This also proves the late mark did not stick to the whole item class.
	placeGoldUnderPlayer(t, restored, 20)

	if err := restored.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	wallet, found := restored.scripts.Components()["character.wallet"].Get(
		restored.player,
	)
	if !found {
		t.Fatal("restored player has no wallet")
	}

	balance, balanceErr := wallet.Get("gold")
	donations, donationsErr := wallet.Get("donations")
	if balanceErr != nil || donationsErr != nil {
		t.Fatalf("read wallet: balance=%v donations=%v",
			balanceErr, donationsErr)
	}

	if balance != int64(36) || donations != int64(4) {
		t.Fatalf("fresh gold: balance=%v donations=%v", balance, donations)
	}

	devotion, found := restored.scripts.Components()["religion.worship"].Get(
		restored.player,
	)
	if !found {
		t.Fatal("restored player has no worship state")
	}

	points, err := devotion.Get("piety")
	if err != nil {
		t.Fatal(err)
	}

	if points.(int64) <= 15 {
		t.Fatalf("fresh gold awarded no Zin piety: %v", points)
	}
}
