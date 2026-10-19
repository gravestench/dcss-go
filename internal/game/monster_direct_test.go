package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/ecs"
)

// A real monster action must use the Lua direct-strike effect, persist its
// damage, and continue with the same saved monster-spell RNG after restore.
func TestMonsterDirectSmitingAndSaveContinuation(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-direct-strikes")
	placePlayerInSlugLine(t, g, caster)

	health, _ := g.stores.Health.Get(g.player)
	energy, _ := g.stores.MonsterEnergy.Get(caster)

	health.Current = health.Max

	before := health.Current

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell || health.Current >= before {
		t.Fatalf("Smiting intent=%d, HP=%d -> %d",
			g.turn.ResolvedIntent, before, health.Current)
	}

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind:   g.turn.ResolvedIntent,
		ItemID: g.turn.ResolvedItemID,
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("direct-strike HP or RNG changed on restore")
	}

	for _, current := range []*Game{g, loaded} {
		hp, _ := current.stores.Health.Get(current.player)
		ready, _ := current.stores.MonsterEnergy.Get(caster)

		hp.Current = hp.Max
		ready.Points = 80
	}

	liveEvents, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	loadedEvents, err := loaded.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(liveEvents, loadedEvents) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("direct-strike RNG continuation diverged after restore")
	}
}
