package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// Roll crosses the imported book, monster AI, Lua ECS status, and save path.
// A later action must not choose the same self spell while already rolling.
func TestMonsterRollCastMoveAndRestore(t *testing.T) {
	game, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-forced-roll")
	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{},
		10, "monster"); err != nil {
		t.Fatal(err)
	}

	if game.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("Roll intent = %d, want spell",
			game.turn.ResolvedIntent)
	}

	rolling := game.scripts.Components()["combat.monster_rolling"]

	if rolling == nil || !rolling.Has(caster) {
		t.Fatal("Roll did not add its saved ECS status")
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
		t.Fatal("rolling status changed on restore")
	}

	for _, current := range []*Game{game, loaded} {
		currentEnergy, _ := current.stores.MonsterEnergy.Get(caster)

		currentEnergy.Points = 80

		if _, err := current.runAction(caster, ecs.Intent{},
			10, "monster"); err != nil {
			t.Fatal(err)
		}

		if current.turn.ResolvedIntent == ecs.IntentSpell {
			t.Fatal("already rolling monster recast Roll")
		}
	}

	if !reflect.DeepEqual(game.Snapshot(), loaded.Snapshot()) {
		t.Fatal("rolling continuation diverged after restore")
	}
}
