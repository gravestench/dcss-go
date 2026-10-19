package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// Repurpose one existing D:1 roster actor as a second endoplasm and move it
// beside the caster. This preserves the generated floor's initial actor
// budget, which the real save validator checks against live roster actors.
func nearbyEndoplasmAlly(
	t *testing.T,
	g *Game,
	caster akara.Entity,
) akara.Entity {
	t.Helper()

	position, found := g.stores.Positions.Get(caster)

	if !found {
		t.Fatal("caster has no position")
	}

	level := g.levels[position.LevelID]
	actor, _ := g.stores.Actors.Get(caster)
	health, _ := g.stores.Health.Get(caster)
	var ally akara.Entity

	for _, entity := range g.stores.AI.Entities() {
		candidate, placed := g.stores.Positions.Get(entity)

		if entity != caster &&
			placed &&
			candidate.LevelID == position.LevelID &&
			!g.scripts.Components()["vault.origin"].Has(entity) {
			ally = entity
			break
		}
	}

	if ally == 0 {
		t.Fatal("D:1 has no second ordinary monster")
	}

	if _, err := g.stores.Actors.Set(ally, *actor); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Health.Set(ally, *health); err != nil {
		t.Fatal(err)
	}

	if err := level.RemoveActor(ally); err != nil {
		t.Fatal(err)
	}

	for _, delta := range []point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	} {
		x := position.X + delta.x
		y := position.Y + delta.y

		if !level.Walkable(x, y) {
			continue
		}

		if _, occupied := level.ActorAt(x, y); occupied {
			continue
		}

		if err := level.PlaceActor(ally, x, y); err != nil {
			t.Fatal(err)
		}

		return ally
	}

	t.Fatal("caster has no free adjacent ally cell")

	return 0
}

// A real monster action must select the copied ally, grant actor-owned Haste,
// and preserve that state plus next-turn random and event order after reload.
func TestMonsterAllyHasteBookCastAndSave(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-ally-support")
	placePlayerInSlugLine(t, g, caster)
	ally := nearbyEndoplasmAlly(t, g, caster)
	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	boons := g.scripts.Components()["combat.monster_boons"]

	if g.turn.ResolvedIntent != ecs.IntentSpell ||
		!boons.Has(ally) || boons.Has(caster) {
		t.Fatalf("Haste Other missed its ally: intent %d, ally %t, caster %t",
			g.turn.ResolvedIntent, boons.Has(ally), boons.Has(caster))
	}

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) ||
		!loaded.scripts.Components()["combat.monster_boons"].Has(ally) {
		t.Fatal("ally Haste state changed on save restore")
	}

	assertSupportContinuation(t, g, loaded, caster)
}

// A sparse replacement of one spell file must be the resolver called by
// the same book and selected-entity pipeline in the running game.
func TestMonsterAllyHasteEffectOverlay(t *testing.T) {
	g, caster, _ := moddedEndoplasmGame(t,
		"testdata/monster-ally-support-override")
	placePlayerInSlugLine(t, g, caster)
	nearbyEndoplasmAlly(t, g, caster)
	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	events, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("resolved intent = %d, want spell",
			g.turn.ResolvedIntent)
	}

	for _, event := range events {
		if strings.Contains(event.Text, "Modded ally Haste cast.") {
			return
		}
	}

	t.Fatalf("overridden allied spell did not run: %+v", events)
}
