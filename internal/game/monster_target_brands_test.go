package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
)

// A friendly monster can hit a hostile monster with a real equipped weapon.
// The brand runs in the live action loop and its HP result survives restore.
func TestMonsterWeaponBrandHitsMonsterAndRestores(t *testing.T) {
	game, caster, rules := moddedEndoplasmGame(t, "")
	foe := nearbyEndoplasmAlly(t, game, caster)

	placePlayerAwayFromRay(t, game, caster, foe)
	actor, found := game.stores.Actors.Get(caster)

	if !found {
		t.Fatal("friendly monster has no actor")
	}

	// Hobgoblins have a physical attack without the endoplasm's Freeze
	// spell, so the action enters the monster-target melee owner.
	actor.KindID = "MONS_HOBGOBLIN"

	if _, err := game.scripts.Components()["vault.actor_overrides"].Set(
		caster,
		map[string]any{
			"attitude": "friendly",
		},
	); err != nil {
		t.Fatal(err)
	}

	weaponID := giveTestMonsterWeapon(t, game, caster)
	weapon, found := game.stores.Items.Get(weaponID)

	if !found {
		t.Fatal("friendly monster has no weapon")
	}

	weapon.Ego = "SPWPN_FLAMING"

	foeHealth, found := game.stores.Health.Get(foe)

	if !found {
		t.Fatal("enemy monster has no health")
	}

	initial := foeHealth.Current
	burned := false
	messages := make([]string, 0)

	for attempt := 0; attempt < 60 && !burned; attempt++ {
		energy, _ := game.stores.MonsterEnergy.Get(caster)

		energy.Points = 80

		events, err := game.runAction(caster, ecs.Intent{},
			10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range events {
			messages = append(messages, event.Text)
			burned = burned || strings.Contains(event.Text,
				"weapon burns the")
		}
	}

	if !burned || foeHealth.Current >= initial {
		t.Fatalf("monster brand burn=%t, enemy HP=%d, initial=%d, events=%v",
			burned, foeHealth.Current, initial, messages)
	}

	actor.KindID = "MONS_ENDOPLASM"

	if err := game.scheduler.Spend(caster, ecs.Intent{
		Kind: game.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := game.Snapshot()
	loaded, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("branded monster melee changed during restore")
	}
}
