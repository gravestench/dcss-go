package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/ecs"
)

// A real monster action must reach each Lua aura and leave its caster-owned
// timer in the save. The restored game then advances the same aura state.
func TestMonsterTimedAreaBookCastAndSave(t *testing.T) {
	cases := []struct {
		name      string
		path      string
		component string
	}{
		{
			name:      "toxic radiance",
			path:      "testdata/monster-timed-radiance",
			component: "magic.monster_toxic_radiance",
		},
		{
			name:      "polar vortex",
			path:      "testdata/monster-timed-vortex",
			component: "zap.polar_vortex",
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
				t.Fatalf("resolved intent = %d, want aura spell",
					game.turn.ResolvedIntent)
			}

			state := game.scripts.Components()[testCase.component]

			if state == nil || !state.Has(caster) {
				t.Fatalf("cast did not store %s on caster",
					testCase.component)
			}

			beforeState, _ := state.Get(caster)
			beforeAut, _ := beforeState.Get("remaining_aut")

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
				t.Fatal("timed area state changed on restore")
			}

			if !loaded.scripts.Components()[testCase.component].Has(caster) {
				t.Fatal("restored caster lost its timed aura")
			}

			assertSupportContinuation(t, game, loaded, caster)

			for _, current := range []*Game{game, loaded} {
				active, found := current.scripts.Components()[testCase.component].Get(caster)

				if !found {
					t.Fatal("timed aura expired after one later action")
				}

				afterAut, _ := active.Get("remaining_aut")

				if afterAut.(int64) >= beforeAut.(int64) {
					t.Fatalf("aura did not tick: %v -> %v",
						beforeAut, afterAut)
				}
			}
		})
	}
}
