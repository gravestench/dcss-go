package game

import (
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
	"strings"
	"testing"
)

func equipTestGoblinSling(t *testing.T, g *Game) (akara.Entity, akara.Entity) {
	t.Helper()

	monsterID := ratID(t, g)
	actor, found := g.stores.Actors.Get(monsterID)

	if !found {
		t.Fatal("test monster has no actor")
	}

	actor.KindID = "MONS_GOBLIN"

	slingID := giveTestMonsterItem(t, g, monsterID, "WPN_SLING", "weapon", 1)

	return monsterID, slingID
}

func TestGoblinSlingRunsThroughOrderedMonsterSystems(t *testing.T) {
	catalog := testCatalog(t)

	for seed := uint64(1); seed <= 30; seed++ {
		g, err := NewScenario(seed, catalog, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		monsterID, _ := equipTestGoblinSling(t, g)
		before, _ := g.stores.Health.Get(g.player)
		beforeHP := before.Current

		events, err := g.runAction(monsterID, ecs.Intent{}, 0, "monster")

		if err != nil {
			g.Close()
			t.Fatal(err)
		}

		if g.turn.ResolvedIntent == ecs.IntentRanged {
			after, _ := g.stores.Health.Get(g.player)

			if after.Current > beforeHP ||
				len(events) < 2 ||
				!strings.Contains(events[0].Text, "shoots a sling bullet") {
				g.Close()
				t.Fatalf("ordered shot HP %d -> %d, events %+v",
					beforeHP, after.Current, events)
			}

			g.Close()

			return
		}

		g.Close()
	}

	t.Fatal("no seed selected an integrated goblin sling shot")
}
