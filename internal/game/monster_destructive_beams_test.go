package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// Source book slots cast through the live monster action loop. Damage,
// projectile choice, RNG streams, and state must agree after restore.
func TestMonsterDestructiveBeamsCastAndRestore(t *testing.T) {
	testCases := []struct {
		name string
		path string
	}{
		{
			name: "throw barbs",
			path: "testdata/monster-destructive-barbs",
		},

		{
			name: "major destruction",
			path: "testdata/monster-destructive-major",
		},

		{
			name: "legendary destruction",
			path: "testdata/monster-destructive-legendary",
		},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			game, caster, rules := moddedEndoplasmGame(t,
				testCase.path)
			placePlayerInSlugLine(t, game, caster)

			playerHealth, _ := game.stores.Health.Get(game.player)
			beforeHealth := playerHealth.Current

			energy, _ := game.stores.MonsterEnergy.Get(caster)

			energy.Points = 80

			if _, err := game.runAction(caster, ecs.Intent{},
				10, "monster"); err != nil {
				t.Fatal(err)
			}

			if game.turn.ResolvedIntent != ecs.IntentSpell {
				t.Fatalf("resolved intent = %d, want monster spell",
					game.turn.ResolvedIntent)
			}

			if playerHealth.Current >= beforeHealth {
				t.Fatal("destructive cast did not damage the player")
			}

			if testCase.name == "throw barbs" {
				barbs := game.scripts.Components()["combat.barbs"]

				if barbs == nil || !barbs.Has(game.player) {
					t.Fatal("Throw Barbs did not lodge saved spikes")
				}
			}

			if err := game.scheduler.Spend(caster, ecs.Intent{
				Kind: game.turn.ResolvedIntent,
			}); err != nil {
				t.Fatal(err)
			}

			snapshot := game.Snapshot()
			loaded, err := RestoreWithRules(snapshot, rules,
				RestorePolicy{})

			if err != nil {
				t.Fatal(err)
			}

			defer loaded.Close()

			if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
				t.Fatal("destructive cast changed on restore")
			}

			// A lethal double blast reaches game over. Its restored death
			// snapshot is the final state; living cases can take another turn.
			if playerHealth.Current <= 0 {
				return
			}

			for _, current := range []*Game{game, loaded} {
				if _, err := current.runAction(current.player,
					ecs.Intent{Kind: ecs.IntentWait},
					10, "player"); err != nil {
					t.Fatal(err)
				}
			}

			if !reflect.DeepEqual(game.Snapshot(), loaded.Snapshot()) {
				t.Fatal("destructive continuation diverged")
			}
		})
	}
}

// A player barbs wound is owned by ECS across an ordinary move and restore.
// The movement hook must deal damage and the action tick must age the wound.
func TestPlayerBarbsMovementAndRestore(t *testing.T) {
	game := newStepGame(t)
	barbs := game.scripts.Components()["combat.barbs"]

	if barbs == nil {
		t.Fatal("barbs component is unavailable")
	}

	if _, err := barbs.Set(game.player, map[string]any{
		"remaining_aut": int64(60),
		"power":         int64(4),
		"source":        game.player,
	}); err != nil {
		t.Fatal(err)
	}

	health, _ := game.stores.Health.Get(game.player)
	beforeHP := health.Current

	if _, err := game.Step(Command{
		Kind: CommandMove,
		DX:   1,
	}); err != nil {
		t.Fatal(err)
	}

	if health.Current >= beforeHP {
		t.Fatal("player moved with barbs without taking damage")
	}

	state, found := barbs.Get(game.player)

	if !found {
		t.Fatal("movement removed a fresh barbs wound")
	}

	value, err := state.Get("remaining_aut")

	if err != nil {
		t.Fatal(err)
	}

	remaining := value.(int64)

	if remaining != 60 && remaining != 40 {
		t.Fatalf("barbs remaining after movement = %d, want 60 or 40",
			remaining)
	}

	snapshot := game.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("barbs movement state changed on restore")
	}
}
