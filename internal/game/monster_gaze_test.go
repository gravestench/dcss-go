package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/ecs"
)

// A real monster must cast through Lua without a projectile, save Weak on
// the player, and continue from the same RNG state after restore.
func TestMonsterWeakeningGazeBookCastAndSave(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-gazes")
	placePlayerInSlugLine(t, g, caster)
	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	weak := g.scripts.Components()["combat.player_weakness"]

	if g.turn.ResolvedIntent != ecs.IntentSpell || !weak.Has(g.player) {
		t.Fatalf("Weakening Gaze intent %d, player weak %t",
			g.turn.ResolvedIntent, weak.Has(g.player))
	}

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) ||
		!loaded.scripts.Components()["combat.player_weakness"].Has(g.player) {
		t.Fatal("player Weak or spell RNG changed on restore")
	}

	assertSupportContinuation(t, g, loaded, caster)
}
