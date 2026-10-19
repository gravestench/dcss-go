package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"

	"github.com/gravestench/akara"
)

// A cloud's possible area must stay clear of its caster, so use the full
// five-cell spell range instead of the nearer bolt fixture positions.
func placePlayerInCloudLine(t *testing.T, g *Game, caster akara.Entity) {
	t.Helper()

	position, _ := g.stores.Positions.Get(caster)
	level := g.levels[position.LevelID]

	for _, delta := range []point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	} {
		x := position.X + delta.x*5
		y := position.Y + delta.y*5

		if !level.ClearProjectilePath(position.X, position.Y, x, y) {
			continue
		}

		if _, occupied := level.ActorAt(x, y); occupied {
			continue
		}

		if err := level.MoveActor(g.player, x, y); err != nil {
			t.Fatal(err)
		}

		if err := g.refreshVisibility(); err != nil {
			t.Fatal(err)
		}

		return
	}

	t.Fatal("could not place player outside the cloud caster's field")
}

// A source-shaped beam must pass through the real monster decision, beam
// contact, and saved turn state before replay continues.
func assertMonsterBeamBookCastAndSave(
	t *testing.T,
	overlay string,
	contactText string,
	expectedCloud string,
) {
	t.Helper()

	g, caster, rules := moddedEndoplasmGame(t, overlay)

	if expectedCloud == "" {
		placePlayerInSlugLine(t, g, caster)
	} else {
		placePlayerInCloudLine(t, g, caster)
	}

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

	if expectedCloud != "" {
		store := g.scripts.Components()["world.cloud"]
		foundCloud := false

		for _, entity := range store.Entities() {
			cloud, _ := store.Get(entity)
			kind, _ := cloud.Get("kind_id")

			if kind == expectedCloud {
				foundCloud = true
				break
			}
		}

		if !foundCloud {
			t.Fatalf("monster beam left no %s cloud", expectedCloud)
		}
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
		"testdata/monster-elemental-breaths", "blast of flame", "")
}

func TestMonsterMetalSplintersBookCastAndSave(t *testing.T) {
	assertMonsterBeamBookCastAndSave(t,
		"testdata/monster-fragment-rays", "spray of metal splinters", "")
}

// Flaming Cloud must produce a saved fire field through a live monster cast.
func TestMonsterFlamingCloudBookCastAndSave(t *testing.T) {
	assertMonsterBeamBookCastAndSave(t,
		"testdata/monster-cloud-casts", "blast of flame", "CLOUD_FIRE")
}
