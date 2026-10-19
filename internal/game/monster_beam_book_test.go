package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

// A source-shaped beam must pass through the real monster decision, beam
// contact, and saved turn state before replay continues.
func assertMonsterBeamBookCastAndSave(
	t *testing.T,
	overlay string,
	contactText string,
) {
	t.Helper()

	g, caster, rules := moddedEndoplasmGame(t, overlay)
	placePlayerInSlugLine(t, g, caster)
	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	events, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("monster beam resolved intent %d, want spell",
			g.turn.ResolvedIntent)
	}

	contact := false

	for _, event := range events {
		if strings.Contains(event.Text, contactText) {
			contact = true
		}
	}

	if !contact {
		t.Fatalf("monster beam produced no %q contact: %+v",
			contactText, events)
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
		t.Fatal("monster beam changed on save restore")
	}

	assertSupportContinuation(t, g, loaded, caster)
}

// Natural Fire Breath and magical Metal Splinters use the same intent and
// save path while their Lua profiles choose different contact policies.
func TestMonsterFireBreathBookCastAndSave(t *testing.T) {
	assertMonsterBeamBookCastAndSave(t,
		"testdata/monster-elemental-breaths", "blast of flame")
}

func TestMonsterMetalSplintersBookCastAndSave(t *testing.T) {
	assertMonsterBeamBookCastAndSave(t,
		"testdata/monster-fragment-rays", "spray of metal splinters")
}
