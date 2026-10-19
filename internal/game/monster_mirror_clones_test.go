package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// A live Mara cast creates two copied Akara actors. Their mirror marker,
// independent summon state, and later turn remain stable across restore.
func TestMaraMirrorClonesCastAndRestore(t *testing.T) {
	game, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-mirror-clones")
	actor, found := game.stores.Actors.Get(caster)

	if !found {
		t.Fatal("generated caster has no actor")
	}

	actor.KindID = "MONS_MARA"

	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{}, 10,
		"monster"); err != nil {
		t.Fatal(err)
	}

	if game.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("Mara intent = %d, want spell",
			game.turn.ResolvedIntent)
	}

	mirrors := game.scripts.Components()["magic.summon_mirror"].Entities()

	if len(mirrors) != 2 {
		t.Fatalf("Mara made %d fakes, want two", len(mirrors))
	}

	for _, clone := range mirrors {
		kind, found := game.stores.Actors.Get(clone)

		if !found || kind.KindID != "MONS_MARA" {
			t.Fatal("mirror clone lost Mara body")
		}

		if _, positioned := game.stores.Positions.Get(clone); !positioned {
			t.Fatal("mirror clone has no grid position")
		}
	}

	// The generated Dungeon roster owns the original endoplasm identity.
	// A mirror survives even when its summoner later changes kind.
	actor.KindID = "MONS_ENDOPLASM"

	if err := game.scheduler.Spend(caster, ecs.Intent{
		Kind: game.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	before := game.Snapshot()
	loaded, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("mirror clones changed during restore")
	}

	assertSupportContinuation(t, game, loaded, caster)
}
