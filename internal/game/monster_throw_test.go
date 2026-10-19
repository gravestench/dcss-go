package game

import (
	"crawl/internal/ecs"
	"github.com/gravestench/akara"
	"strings"
	"testing"
)

func equipTestKoboldMissile(
	t *testing.T,
	g *Game,
	kindID string,
) (akara.Entity, akara.Entity) {
	t.Helper()

	monsterID := ratID(t, g)
	actor, found := g.stores.Actors.Get(monsterID)

	if !found {
		t.Fatal("test monster has no actor")
	}

	actor.KindID = "MONS_KOBOLD"

	missileID := giveTestMonsterItem(t, g, monsterID, kindID, "missile", 4)
	missile, _ := g.stores.Items.Get(missileID)

	if kindID == "MI_DART" {
		missile.Ego = "poisoned"
	}

	return monsterID, missileID
}

func TestKoboldStoneRunsThroughOrderedMonsterSystems(t *testing.T) {

	for seed := uint64(1); seed <= 30; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		monsterID, missileID := equipTestKoboldMissile(t, g, "MI_STONE")
		events, err := g.runAction(monsterID, ecs.Intent{}, 0, "monster")

		if err != nil {
			g.Close()
			t.Fatal(err)
		}

		if g.turn.ResolvedIntent == ecs.IntentRanged {
			missile, _ := g.stores.Items.Get(missileID)

			if missile.Quantity != 4 ||
				len(events) < 2 ||
				!strings.Contains(events[0].Text, "throws a stone") {
				g.Close()
				t.Fatalf("ordered throw left item %+v and events %+v", missile, events)
			}

			g.Close()

			return
		}

		g.Close()
	}

	t.Fatal("no seed selected an integrated kobold throw")
}
