package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// A live monster choice exercises the embedded spell resolver, grid,
// scheduler, and save path on the same ruleset as normal gameplay.
func TestMonsterWindBlastCastAndRestore(t *testing.T) {
	game, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-wind-blast")
	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{},
		10, "monster"); err != nil {
		t.Fatal(err)
	}

	if game.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("Wind Blast intent = %d, want spell",
			game.turn.ResolvedIntent)
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
		t.Fatal("Wind Blast world changed on restore")
	}
}
