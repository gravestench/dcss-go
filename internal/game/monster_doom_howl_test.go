package game

import (
	"testing"

	"crawl/internal/ecs"
)

// A source Doom Howl arrival is a permanent monster outside the starting
// scenario roster. Save validation must recognize its distinct origin.
func TestDoomHowlArrivalRestores(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-doom-howl")
	placePlayerInSlugLine(t, g, caster)

	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("Doom Howl resolved intent = %d", g.turn.ResolvedIntent)
	}

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	arrivals := g.scripts.Components()["combat.doom_arrival"]

	for turn := 0; turn < 5 && len(arrivals.Entities()) == 0; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if arrivals == nil || len(arrivals.Entities()) == 0 {
		t.Fatal("Doom Howl did not create a permanent beast")
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
}
