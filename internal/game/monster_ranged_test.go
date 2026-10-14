package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
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

func TestGoblinSlingUsesLiveItemAndMissileEnergy(t *testing.T) {
	g := newStepGame(t)
	monsterID, slingID := equipTestGoblinSling(t, g)
	monsterPosition, _ := g.stores.Positions.Get(monsterID)
	playerPosition, _ := g.stores.Positions.Get(g.player)
	level := g.levels[monsterPosition.LevelID]
	decision := newMonsterDecisionSystem(g)

	var intent ecs.Intent
	var shoot bool

	for attempt := 0; attempt < 20 && !shoot; attempt++ {
		var err error
		intent, shoot, err = decision.chooseGoblinSling(
			monsterID,
			*monsterPosition,
			*playerPosition,
			level,
		)

		if err != nil {
			t.Fatal(err)
		}
	}

	if !shoot ||
		intent.Kind != ecs.IntentRanged ||
		intent.ItemID != slingID {
		t.Fatalf("goblin sling intent = %+v, shoot %v", intent, shoot)
	}

	before, _ := g.stores.Health.Get(g.player)
	beforeHP := before.Current

	g.turn.Actor = monsterID

	if err := newCombatSystem(g).resolveGoblinSling(&intent); err != nil {
		t.Fatal(err)
	}

	after, _ := g.stores.Health.Get(g.player)
	item, _ := g.stores.Items.Get(slingID)

	if after.Current > beforeHP ||
		item.Quantity != 1 ||
		len(g.turn.Events) != 2 ||
		!strings.Contains(g.turn.Events[0].Text, "shoots a sling bullet") {
		t.Fatalf("shot HP %d -> %d, sling %+v, events %+v",
			beforeHP, after.Current, item, g.turn.Events)
	}

	energy, _ := g.stores.MonsterEnergy.Get(monsterID)

	energy.Points = 80

	if err := g.scheduler.Spend(monsterID, ecs.IntentRanged); err != nil {
		t.Fatal(err)
	}

	if energy.Points != 70 {
		t.Fatalf("goblin missile energy = %d, want 70", energy.Points)
	}
}

func TestGoblinSlingRejectsRemovedLauncherAfterIntent(t *testing.T) {
	g := newStepGame(t)
	monsterID, slingID := equipTestGoblinSling(t, g)

	g.turn.Actor = monsterID

	intent := ecs.Intent{
		Kind:   ecs.IntentRanged,
		ItemID: slingID,
	}

	g.stores.Equipped.Remove(slingID)

	if err := newCombatSystem(g).resolveGoblinSling(&intent); err == nil {
		t.Fatal("stale ranged intent fired a removed sling")
	}
}

func TestGoblinSlingAcceptsSourceGeneratedBrands(t *testing.T) {
	for _, brand := range []string{
		"",
		"SPWPN_FLAMING",
		"SPWPN_FREEZING",
		"SPWPN_VORPAL",
	} {
		t.Run(brand, func(t *testing.T) {
			g := newStepGame(t)
			monsterID, slingID := equipTestGoblinSling(t, g)
			item, _ := g.stores.Items.Get(slingID)

			item.Ego = brand

			position, _ := g.stores.Positions.Get(monsterID)
			player, _ := g.stores.Positions.Get(g.player)
			decision := newMonsterDecisionSystem(g)

			for attempt := 0; attempt < 20; attempt++ {
				intent, shoot, err := decision.chooseGoblinSling(
					monsterID,
					*position,
					*player,
					g.levels[position.LevelID],
				)

				if err != nil {
					t.Fatal(err)
				}

				if shoot {
					if intent.ItemID != slingID {
						t.Fatalf("branded sling intent = %+v", intent)
					}

					return
				}
			}

			t.Fatal("branded sling never selected a shot")
		})
	}
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
