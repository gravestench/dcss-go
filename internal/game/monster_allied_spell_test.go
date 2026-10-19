package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/ecs"
)

// A friendly caster uses the same spellbook against an enemy actor. Its
// selected foe, damage, and RNG state must survive the normal action and save.
func TestAlliedMonsterSmitesEnemyAndRestores(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-direct-strikes")
	placePlayerInSlugLine(t, g, caster)
	enemy := nearbyEndoplasmAlly(t, g, caster)

	overrides := g.scripts.Components()["vault.actor_overrides"]

	if _, err := overrides.Set(caster, map[string]any{
		"attitude": "friendly",
	}); err != nil {
		t.Fatal(err)
	}

	enemyHealth, _ := g.stores.Health.Get(enemy)
	playerHealth, _ := g.stores.Health.Get(g.player)
	energy, _ := g.stores.MonsterEnergy.Get(caster)

	beforeEnemy := enemyHealth.Current
	beforePlayer := playerHealth.Current

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell ||
		enemyHealth.Current >= beforeEnemy ||
		playerHealth.Current != beforePlayer {
		t.Fatalf("allied cast intent=%d, enemy HP=%d, player HP=%d",
			g.turn.ResolvedIntent,
			enemyHealth.Current,
			playerHealth.Current)
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
		t.Fatal("allied spell state changed on restore")
	}
}

// Freeze uses the same selected monster foe but applies cold resistance and
// damage through the monster owner instead of the player's health policy.
func TestAlliedMonsterFreezesEnemy(t *testing.T) {
	g, caster, _ := moddedEndoplasmGame(t,
		"testdata/monster-allied-freeze")
	placePlayerInSlugLine(t, g, caster)
	enemy := nearbyEndoplasmAlly(t, g, caster)

	if _, err := g.scripts.Components()["vault.actor_overrides"].Set(
		caster,
		map[string]any{
			"attitude": "friendly",
		},
	); err != nil {
		t.Fatal(err)
	}

	enemyHealth, _ := g.stores.Health.Get(enemy)
	enemyActor, _ := g.stores.Actors.Get(enemy)
	playerHealth, _ := g.stores.Health.Get(g.player)
	energy, _ := g.stores.MonsterEnergy.Get(caster)

	beforeEnemy := enemyHealth.Current
	beforePlayer := playerHealth.Current

	enemyActor.KindID = "MONS_ICE_BEAST"

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell ||
		enemyHealth.Current != beforeEnemy ||
		playerHealth.Current != beforePlayer {
		t.Fatalf("cold-immune foe: Freeze intent=%d, enemy HP=%d, player HP=%d",
			g.turn.ResolvedIntent,
			enemyHealth.Current,
			playerHealth.Current)
	}
}

// A neutral caster has no enemy on the player's side. It must not select a
// player spell intent that resolution would reject as friendly fire.
func TestNeutralMonsterDoesNotCastAtPlayer(t *testing.T) {
	g, caster, _ := moddedEndoplasmGame(t,
		"testdata/monster-direct-strikes")
	placePlayerInSlugLine(t, g, caster)

	if _, err := g.scripts.Components()["vault.actor_overrides"].Set(
		caster,
		map[string]any{
			"attitude": "neutral",
		},
	); err != nil {
		t.Fatal(err)
	}

	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent == ecs.IntentSpell {
		t.Fatal("neutral monster cast Smiting at the player")
	}
}

// Frenzy may retarget nearby actors for melee, but its shared route must not
// grant a stealth-bypassing spell cast to a caster whose allegiance changed.
func TestFrenziedAllyDoesNotOfferSpell(t *testing.T) {
	g, caster, _ := moddedEndoplasmGame(t,
		"testdata/monster-direct-strikes")
	placePlayerInSlugLine(t, g, caster)
	nearbyEndoplasmAlly(t, g, caster)

	if _, err := g.scripts.Components()["vault.actor_overrides"].Set(
		caster,
		map[string]any{
			"attitude": "friendly",
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["magic.monster_allegiance"].Set(
		caster,
		map[string]any{
			"frenzy_aut": int64(100),
		},
	); err != nil {
		t.Fatal(err)
	}

	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := g.runAction(caster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent == ecs.IntentSpell {
		t.Fatal("frenzied caster offered a spell while routing")
	}
}
