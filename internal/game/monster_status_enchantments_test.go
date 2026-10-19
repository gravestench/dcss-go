package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

// Keep the victim outside the ghost's sight so its saved Flay duration can
// decay normally. Both games choose the same open cell after restore.
func movePlayerBeyondGhostSight(t *testing.T, game *Game,
	ghost akara.Entity) {
	t.Helper()

	position, _ := game.stores.Positions.Get(ghost)
	level := game.levels[position.LevelID]

	for y, row := range level.Cells() {
		for x := range row {
			if max(abs(x-position.X), abs(y-position.Y)) <= 7 ||
				!level.Walkable(x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if err := level.MoveActor(game.player, x, y); err != nil {
				t.Fatal(err)
			}

			return
		}
	}

	t.Fatal("no open cell outside the Flayed Ghost's sight")
}

// Aging the actual player actor tests recovery and expiry through the
// action systems, then compares saved state and random streams on both runs.
func assertFlayContinuation(t *testing.T, original, loaded *Game,
	ghost akara.Entity) {
	t.Helper()

	for _, game := range []*Game{original, loaded} {
		movePlayerBeyondGhostSight(t, game, ghost)

		for step := 0; step < 20; step++ {
			if _, err := game.runAction(game.player, ecs.Intent{
				Kind: ecs.IntentWait,
			}, 10, "player"); err != nil {
				t.Fatal(err)
			}
		}

		if game.scripts.Components()["combat.monster_flayed"].Has(game.player) {
			t.Fatal("Flay did not expire on player actions")
		}
	}

	if !reflect.DeepEqual(original.Snapshot(), loaded.Snapshot()) {
		t.Fatal("Flay recovery diverged after save and restore")
	}
}

// Real Dungeon actions must find the new Lua resolver, store its status in
// Akara, and preserve both that state and its RNG across save/restore.
func TestMonsterStatusBookCastAndSave(t *testing.T) {
	cases := []struct {
		name      string
		path      string
		component string
		onPlayer  bool
	}{
		{
			name:      "silence",
			path:      "testdata/monster-status-silence",
			component: "world.monster_silence",
		},

		{
			name:      "flay",
			path:      "testdata/monster-status-flay",
			component: "combat.monster_flayed",
			onPlayer:  true,
		},
	}

	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			game, caster, rules := moddedEndoplasmGame(t,
				testCase.path)
			placePlayerAdjacentToCaster(t, game, caster)

			energy, _ := game.stores.MonsterEnergy.Get(caster)

			energy.Points = 80

			if _, err := game.runAction(caster, ecs.Intent{}, 10,
				"monster"); err != nil {
				t.Fatal(err)
			}

			if game.turn.ResolvedIntent != ecs.IntentSpell {
				t.Fatalf("resolved intent = %d, want status spell",
					game.turn.ResolvedIntent)
			}

			target := caster

			if testCase.onPlayer {
				target = game.player
			}

			store := game.scripts.Components()[testCase.component]

			if store == nil || !store.Has(target) {
				t.Fatalf("cast did not save %s on target",
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

			if !reflect.DeepEqual(before, loaded.Snapshot()) ||
				!loaded.scripts.Components()[testCase.component].Has(target) {
				t.Fatal("status or RNG changed across save and restore")
			}

			if testCase.onPlayer {
				assertFlayContinuation(t, game, loaded, caster)
			} else {
				assertSupportContinuation(t, game, loaded, caster)
			}
		})
	}
}
