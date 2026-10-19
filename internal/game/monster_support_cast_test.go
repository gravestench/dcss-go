package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

// Reloading must leave the next monster decision, event sequence, and named
// random streams identical after a selected support spell spent its turn.
func assertSupportContinuation(t *testing.T, original, loaded *Game,
	monster akara.Entity) {
	t.Helper()

	for _, game := range []*Game{original, loaded} {
		energy, _ := game.stores.MonsterEnergy.Get(monster)

		energy.Points = 80
	}

	first, err := original.runAction(monster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	second, err := loaded.runAction(monster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if original.turn.ResolvedIntent != loaded.turn.ResolvedIntent ||
		!reflect.DeepEqual(first, second) ||
		!reflect.DeepEqual(original.rng.States(), loaded.rng.States()) {
		t.Fatal("support spell continuation diverged after save")
	}
}

// A sparse book overlay routes a live monster through selection, the base
// Haste resolver, ECS state, and save continuation without a Go spell switch.
func TestMonsterSelfSupportBookCastAndSave(t *testing.T) {
	g, monster, rules := moddedEndoplasmGame(t,
		"testdata/monster-self-support")
	placePlayerInSlugLine(t, g, monster)

	energy, _ := g.stores.MonsterEnergy.Get(monster)

	energy.Points = 80

	if _, err := g.runAction(monster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("resolved intent = %d, want spell",
			g.turn.ResolvedIntent)
	}

	boons := g.scripts.Components()["combat.monster_boons"]

	if !boons.Has(monster) {
		t.Fatal("Haste did not grant its actor-owned boon")
	}

	if err := g.scheduler.Spend(monster, ecs.Intent{
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

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("Haste cast changed on save restore")
	}

	if !loaded.scripts.Components()["combat.monster_boons"].Has(monster) {
		t.Fatal("Haste boon was lost on restore")
	}

	assertSupportContinuation(t, g, loaded, monster)
}

// A wounded book caster heals itself through the same selected spell intent.
// Its new HP and the consumed spell stream survive an immediate reload.
func TestMonsterSelfHealingBookCastAndSave(t *testing.T) {
	g, monster, rules := moddedEndoplasmGame(t,
		"testdata/monster-self-healing")
	placePlayerInSlugLine(t, g, monster)

	health, _ := g.stores.Health.Get(monster)

	health.Current = 1

	energy, _ := g.stores.MonsterEnergy.Get(monster)

	energy.Points = 80

	if _, err := g.runAction(monster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell || health.Current <= 1 {
		t.Fatalf("Major Healing did not cast: intent %d, HP %d",
			g.turn.ResolvedIntent, health.Current)
	}

	if err := g.scheduler.Spend(monster, ecs.Intent{
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

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("healing cast changed on save restore")
	}

	assertSupportContinuation(t, g, loaded, monster)
}

// A second sparse layer may replace one executable spell file without
// copying the base mod or adding a Go-side effect registration.
func TestMonsterSelfSupportEffectOverlay(t *testing.T) {
	g, monster, _ := moddedEndoplasmGame(t,
		"testdata/monster-self-support-override")
	placePlayerInSlugLine(t, g, monster)

	energy, _ := g.stores.MonsterEnergy.Get(monster)

	energy.Points = 80

	events, err := g.runAction(monster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("resolved intent = %d, want spell",
			g.turn.ResolvedIntent)
	}

	for _, event := range events {
		if strings.Contains(event.Text, "Modded Haste cast.") {
			return
		}
	}

	t.Fatalf("overridden effect did not run: %+v", events)
}
