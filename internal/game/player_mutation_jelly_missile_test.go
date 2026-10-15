package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestJellyMissileAbsorbsAnIncomingGoblinShot(t *testing.T) {
	for seed := uint64(1); seed <= 100; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		monster, _ := equipTestGoblinSling(t, g)
		addPlayerMutation(t, g, "MUT_JELLY_MISSILE")

		health, _ := g.stores.Health.Get(g.player)

		health.Current = health.Max - 5

		events, err := g.runAction(monster, ecs.Intent{}, 0, "monster")

		if err != nil {
			g.Close()
			t.Fatal(err)
		}

		shot := false
		eaten := false

		for _, event := range events {
			if strings.Contains(event.Text, "shoots a sling bullet") {
				shot = true
			}

			if strings.Contains(event.Text, "attached jelly eats") {
				eaten = true
			}
		}

		g.Close()

		if eaten {
			if !shot {
				t.Fatal("jelly ate a projectile without a monster shot")
			}

			return
		}
	}

	t.Fatal("no seeded goblin shot triggered Jelly Missile")
}
