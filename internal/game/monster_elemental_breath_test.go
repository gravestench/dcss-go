package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

// A source-shaped natural breath must pass through the real monster decision,
// beam contact, and saved turn state before replay continues.
func TestMonsterFireBreathBookCastAndSave(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-elemental-breaths")
	placePlayerInSlugLine(t, g, caster)
	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	events, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("Fire Breath resolved intent %d, want spell",
			g.turn.ResolvedIntent)
	}

	contact := false

	for _, event := range events {
		if strings.Contains(event.Text, "blast of flame") {
			contact = true
		}
	}

	if !contact {
		t.Fatalf("Fire Breath produced no beam contact: %+v", events)
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

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("Fire Breath changed on save restore")
	}

	assertSupportContinuation(t, g, loaded, caster)
}
