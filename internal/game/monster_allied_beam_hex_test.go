package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// Reuse the generated D:1 actors and player sight while selecting one
// enemy for a friendly caster. Both spell families must keep that foe.
func alliedSpellFoes(
	t *testing.T,
	overlay string,
) (*Game, akara.Entity, akara.Entity) {
	t.Helper()

	g, caster, _ := moddedEndoplasmGame(t, overlay)
	enemy := nearbyEndoplasmAlly(t, g, caster)
	placePlayerAwayFromRay(t, g, caster, enemy)

	if _, err := g.scripts.Components()["vault.actor_overrides"].Set(
		caster,
		map[string]any{
			"attitude": "friendly",
		},
	); err != nil {
		t.Fatal(err)
	}

	return g, caster, enemy
}

// Keep the observer close while leaving the full projectile ray safe for
// the allied caster. A missed hex can travel beyond its selected foe.
func placePlayerAwayFromRay(
	t *testing.T,
	g *Game,
	caster akara.Entity,
	enemy akara.Entity,
) {
	t.Helper()

	start, _ := g.stores.Positions.Get(caster)
	target, _ := g.stores.Positions.Get(enemy)
	level := g.levels[start.LevelID]

	for _, direction := range []point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	} {
		if target.X-start.X == direction.x &&
			target.Y-start.Y == direction.y {
			continue
		}

		for distance := 3; distance <= 5; distance++ {
			x := start.X + direction.x*distance
			y := start.Y + direction.y*distance

			if !level.Walkable(x, y) ||
				!level.ClearProjectilePath(start.X, start.Y, x, y) {
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
	}

	t.Fatal("no safe player observation cell away from allied projectile")
}

// Magic Dart follows the selected hostile monster through beam contact.
// The nearby player remains a friendly bystander, even across retries.
func TestAlliedMonsterBeamHitsEnemy(t *testing.T) {
	g, caster, enemy := alliedSpellFoes(t,
		"testdata/monster-allied-beam")
	health, _ := g.stores.Health.Get(enemy)
	playerHealth, _ := g.stores.Health.Get(g.player)
	initialEnemy := health.Current
	initialPlayer := playerHealth.Current

	for attempt := 0; attempt < 40; attempt++ {
		energy, _ := g.stores.MonsterEnergy.Get(caster)

		energy.Points = 80

		if _, err := g.runAction(caster, ecs.Intent{}, 10,
			"monster"); err != nil {
			t.Fatal(err)
		}

		if health.Current < initialEnemy {
			break
		}
	}

	if health.Current >= initialEnemy ||
		playerHealth.Current != initialPlayer {
		t.Fatalf("beam HP: enemy %d -> %d, player %d -> %d",
			initialEnemy, health.Current,
			initialPlayer, playerHealth.Current)
	}
}

// Slow uses the shared hex beam and must attach its ECS status to the
// enemy monster, never the player standing nearby.
func TestAlliedMonsterHexSlowsEnemy(t *testing.T) {
	g, caster, enemy := alliedSpellFoes(t,
		"testdata/monster-allied-hex")
	slow := g.scripts.Components()["projectile.slow"]
	playerSlow := g.scripts.Components()["combat.player_slow"]

	if slow == nil {
		t.Fatal("monster slow component is unavailable")
	}

	for attempt := 0; attempt < 80 && !slow.Has(enemy); attempt++ {
		energy, _ := g.stores.MonsterEnergy.Get(caster)

		energy.Points = 80

		if _, err := g.runAction(caster, ecs.Intent{}, 10,
			"monster"); err != nil {
			t.Fatal(err)
		}
	}

	if !slow.Has(enemy) {
		t.Fatal("allied hex did not slow its enemy")
	}

	if playerSlow != nil && playerSlow.Has(g.player) {
		t.Fatal("allied hex slowed the player")
	}
}
