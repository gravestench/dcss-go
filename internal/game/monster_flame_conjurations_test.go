package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// Each spell reaches its real monster spellbook resolver, then persists its
// world state and RNG through a save and another actor action.
func TestMonsterFlameSpellbookCastAndRestore(t *testing.T) {
	cases := []struct {
		name      string
		path      string
		component string
	}{
		{
			name:      "marshlight",
			path:      "testdata/monster-flame-marshlight",
			component: "magic.summon_construct",
		},

		{
			name:      "holy flames",
			path:      "testdata/monster-flame-holy",
			component: "world.cloud",
		},

		{
			name:      "stoke flames",
			path:      "testdata/monster-flame-stoke",
			component: "magic.summon",
		},
	}

	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			game, caster, rules := moddedEndoplasmGame(t,
				testCase.path)
			placePlayerInSlugLine(t, game, caster)

			energy, _ := game.stores.MonsterEnergy.Get(caster)

			energy.Points = 80

			if _, err := game.runAction(caster, ecs.Intent{}, 10,
				"monster"); err != nil {
				t.Fatal(err)
			}

			if game.turn.ResolvedIntent != ecs.IntentSpell {
				t.Fatalf("resolved intent = %d, want spell",
					game.turn.ResolvedIntent)
			}

			store := game.scripts.Components()[testCase.component]

			if store == nil || len(store.Entities()) == 0 {
				t.Fatalf("cast did not create %s",
					testCase.component)
			}

			if err := game.scheduler.Spend(caster, ecs.Intent{
				Kind: game.turn.ResolvedIntent,
			}); err != nil {
				t.Fatal(err)
			}

			before := game.Snapshot()
			loaded, err := RestoreWithRules(before, rules,
				RestorePolicy{})

			if err != nil {
				t.Fatal(err)
			}

			defer loaded.Close()

			if !reflect.DeepEqual(before, loaded.Snapshot()) {
				t.Fatal("flame conjuration changed on save restore")
			}

			assertSupportContinuation(t, game, loaded, caster)
		})
	}
}

// A Marshlight summon must reach construct decision on its own live action.
// The focused Lua test invokes foxfire directly; this catches a missing
// source-spell registration in the production scheduler.
func TestMonsterMarshlightFoxfireActs(t *testing.T) {
	game, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-flame-marshlight")
	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{}, 10,
		"monster"); err != nil {
		t.Fatal(err)
	}

	foxfires := game.scripts.Components()["magic.summon_construct"].Entities()

	if len(foxfires) != 2 {
		t.Fatalf("Marshlight made %d foxfires, want two", len(foxfires))
	}

	if err := game.scheduler.Spend(caster, ecs.Intent{
		Kind: game.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	loaded, err := RestoreWithRules(game.Snapshot(), rules,
		RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	playerHealth, _ := game.stores.Health.Get(game.player)
	startingHP := playerHealth.Current
	changed := false

	for _, foxfire := range foxfires {
		before, _ := game.stores.Positions.Get(foxfire)
		beforeX := before.X
		beforeY := before.Y

		if _, err := game.runAction(foxfire, ecs.Intent{}, 10,
			"monster"); err != nil {
			t.Fatal(err)
		}

		if _, err := loaded.runAction(foxfire, ecs.Intent{}, 10,
			"monster"); err != nil {
			t.Fatal(err)
		}

		after, exists := game.stores.Positions.Get(foxfire)
		currentHealth, _ := game.stores.Health.Get(game.player)

		if !exists ||
			beforeX != after.X ||
			beforeY != after.Y ||
			currentHealth.Current < startingHP {
			changed = true
		}
	}

	if !changed {
		t.Fatal("Marshlight foxfires neither moved nor struck")
	}

	if !reflect.DeepEqual(game.Snapshot(), loaded.Snapshot()) {
		t.Fatal("restored Marshlight foxfires diverged on their actions")
	}
}

// A killed inferno must cross summon expiry and reach actor death in the
// production scheduler; the focused Lua test runs those phases directly.
func TestMonsterStokeFlamesExplodesOnDeath(t *testing.T) {
	game, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-flame-stoke")
	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{}, 10,
		"monster"); err != nil {
		t.Fatal(err)
	}

	summons := game.scripts.Components()["magic.summon"].Entities()

	if len(summons) != 1 {
		t.Fatalf("Stoke Flames made %d summons, want one", len(summons))
	}

	if err := game.scheduler.Spend(caster, ecs.Intent{
		Kind: game.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	inferno := summons[0]
	loaded, err := RestoreWithRules(game.Snapshot(), rules,
		RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	health, exists := game.stores.Health.Get(inferno)
	loadedHealth, loadedExists := loaded.stores.Health.Get(inferno)

	if !exists || !loadedExists {
		t.Fatal("inferno has no health before or after restore")
	}

	health.Current = 0
	loadedHealth.Current = 0

	if _, err := game.runAction(game.player, ecs.Intent{
		Kind: ecs.IntentWait,
	}, 10, "player"); err != nil {
		t.Fatal(err)
	}

	if _, err := loaded.runAction(loaded.player, ecs.Intent{
		Kind: ecs.IntentWait,
	}, 10, "player"); err != nil {
		t.Fatal(err)
	}

	if _, exists := game.stores.Actors.Get(inferno); exists {
		t.Fatal("dead inferno survived actor death")
	}

	clouds := game.scripts.Components()["world.cloud"].Entities()

	if len(clouds) == 0 {
		t.Fatal("inferno death left no Fire Storm clouds")
	}

	if !reflect.DeepEqual(game.Snapshot(), loaded.Snapshot()) {
		t.Fatal("restored inferno death diverged from live death")
	}
}
