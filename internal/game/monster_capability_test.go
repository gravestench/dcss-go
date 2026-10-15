package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

// A mod can equip another cataloged actor without adding an ID handler.
func TestEquippedMonsterUsesLauncherCapability(t *testing.T) {

	for seed := uint64(1); seed <= 30; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		rat := ratID(t, g)
		giveTestMonsterItem(t, g, rat, "WPN_SLING", "weapon", 1)
		events, err := g.runAction(rat, ecs.Intent{}, 0, "monster")
		selected := g.turn.ResolvedIntent == ecs.IntentRanged
		g.Close()

		if err != nil {
			t.Fatal(err)
		}

		if !selected {
			continue
		}

		if len(events) == 0 ||
			!strings.Contains(events[0].Text, "shoots a sling bullet") {
			t.Fatalf("equipped rat ranged events: %+v", events)
		}

		return
	}

	t.Fatal("equipped monster never chose its launcher")
}

func TestMonsterUsesAlternateLauncherAndSwapsWeapons(t *testing.T) {

	for seed := uint64(1); seed <= 30; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		rat := ratID(t, g)
		melee := giveTestMonsterItem(t, g, rat, "WPN_DAGGER", "weapon", 1)
		launcher := giveTestMonsterItem(t, g, rat, "WPN_SLING", "alternate_weapon", 1)
		events, err := g.runAction(rat, ecs.Intent{}, 0, "monster")
		selected := g.turn.ResolvedIntent == ecs.IntentRanged

		if err != nil {
			g.Close()
			t.Fatal(err)
		}

		if !selected {
			g.Close()
			continue
		}

		primary, _ := g.stores.Equipped.Get(launcher)
		alternate, _ := g.stores.Equipped.Get(melee)
		g.Close()

		if primary.Slot != "weapon" ||
			alternate.Slot != "alternate_weapon" {
			t.Fatalf("alternate launcher slots: %q and %q",
				primary.Slot, alternate.Slot)
		}

		if len(events) == 0 ||
			!strings.Contains(events[0].Text, "shoots a sling bullet") {
			t.Fatalf("alternate launcher did not fire: %+v", events)
		}

		return
	}

	t.Fatal("monster never chose its alternate launcher")
}

func TestMonsterLauncherPreventsFallbackThrow(t *testing.T) {

	for seed := uint64(1); seed <= 30; seed++ {
		withMissile, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		withoutMissile, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			withMissile.Close()
			t.Fatal(err)
		}

		withRat := ratID(t, withMissile)
		withoutRat := ratID(t, withoutMissile)
		giveTestMonsterItem(t, withMissile, withRat, "WPN_SLING", "weapon", 1)
		giveTestMonsterItem(t, withoutMissile, withoutRat, "WPN_SLING", "weapon", 1)
		giveTestMonsterItem(t, withMissile, withRat, "MI_STONE", "missile", 4)

		_, withErr := withMissile.runAction(withRat, ecs.Intent{}, 0, "monster")
		_, withoutErr := withoutMissile.runAction(withoutRat, ecs.Intent{}, 0, "monster")
		withIntent := withMissile.turn.ResolvedIntent
		withoutIntent := withoutMissile.turn.ResolvedIntent
		withMissile.Close()
		withoutMissile.Close()

		if withErr != nil {
			t.Fatalf("seed %d with missile: %v", seed, withErr)
		}

		if withoutErr != nil {
			t.Fatalf("seed %d without missile: %v", seed, withoutErr)
		}

		if withIntent != withoutIntent {
			t.Fatalf("seed %d: missile changed launcher choice: %v vs %v",
				seed, withIntent, withoutIntent)
		}
	}
}
