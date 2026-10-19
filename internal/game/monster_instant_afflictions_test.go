package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// An imported book reaches each new Lua effect through the normal AI turn.
// Its player-owned state must survive restore and the next action unchanged.
func TestMonsterInstantAfflictionsCastAndRestore(t *testing.T) {
	testCases := []struct {
		name string
		path string
	}{
		{
			name: "malmutate",
			path: "testdata/monster-affliction-malmutate",
		},

		{
			name: "entropic weave",
			path: "testdata/monster-affliction-entropic",
		},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			game, caster, rules := moddedEndoplasmGame(t,
				testCase.path)
			placePlayerAdjacentToCaster(t, game, caster)

			beforeMutations := playerMutationRecords(t, game)
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

			switch testCase.name {
			case "malmutate":
				if reflect.DeepEqual(beforeMutations,
					playerMutationRecords(t, game)) {
					t.Fatal("Malmutate cast did not change player mutations")
				}

			case "entropic weave":
				store := game.scripts.Components()["character.corrosion"]

				if store == nil || !store.Has(game.player) {
					t.Fatal("Entropic Weave cast did not corrode player gear")
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
				t.Fatal("affliction state changed on restore")
			}

			for _, current := range []*Game{game, loaded} {
				if _, err := current.runAction(current.player,
					ecs.Intent{Kind: ecs.IntentWait},
					10, "player"); err != nil {
					t.Fatal(err)
				}
			}

			if !reflect.DeepEqual(game.Snapshot(), loaded.Snapshot()) {
				t.Fatal("affliction continuation diverged after restore")
			}
		})
	}
}
