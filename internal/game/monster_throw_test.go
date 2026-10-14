package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
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

func TestKoboldThrowUsesLiveMissileWithoutConsumingStack(t *testing.T) {
	g := newStepGame(t)
	monsterID, missileID := equipTestKoboldMissile(t, g, "MI_STONE")
	monsterPosition, _ := g.stores.Positions.Get(monsterID)
	playerPosition, _ := g.stores.Positions.Get(g.player)
	decision := newMonsterDecisionSystem(g)

	var intent ecs.Intent
	var throw bool

	for attempt := 0; attempt < 30 && !throw; attempt++ {
		var err error
		intent, throw, err = decision.chooseKoboldThrow(
			monsterID,
			*monsterPosition,
			*playerPosition,
			g.levels[monsterPosition.LevelID],
		)

		if err != nil {
			t.Fatal(err)
		}
	}

	if !throw ||
		intent.Kind != ecs.IntentRanged ||
		intent.ItemID != missileID {
		t.Fatalf("kobold throw intent = %+v, throw %v", intent, throw)
	}

	g.turn.Actor = monsterID

	if err := newCombatSystem(g).resolveKoboldThrow(&intent); err != nil {
		t.Fatal(err)
	}

	missile, _ := g.stores.Items.Get(missileID)

	if missile.Quantity != 4 ||
		len(g.turn.Events) != 2 ||
		!strings.Contains(g.turn.Events[0].Text, "throws a stone") {
		t.Fatalf("stone stack %+v and events %+v", missile, g.turn.Events)
	}

	energy, _ := g.stores.MonsterEnergy.Get(monsterID)

	energy.Points = 80

	if err := g.scheduler.Spend(monsterID, ecs.IntentRanged); err != nil {
		t.Fatal(err)
	}

	if energy.Points != 70 {
		t.Fatalf("kobold missile energy = %d, want 70", energy.Points)
	}
}

func TestKoboldThrowsOnExactlyOneInThreeChoiceDraws(t *testing.T) {
	g := newStepGame(t)
	monsterID, missileID := equipTestKoboldMissile(t, g, "MI_STONE")
	monsterPosition, _ := g.stores.Positions.Get(monsterID)
	playerPosition, _ := g.stores.Positions.Get(g.player)
	decision := newMonsterDecisionSystem(g)

	decision.rng = NewRNGStreams(777)

	expected := NewRNGStreams(777)

	for attempt := 0; attempt < 30; attempt++ {
		roll, err := expected.Intn("ai", 3)

		if err != nil {
			t.Fatal(err)
		}

		intent, throw, err := decision.chooseKoboldThrow(
			monsterID,
			*monsterPosition,
			*playerPosition,
			g.levels[monsterPosition.LevelID],
		)

		if err != nil ||
			throw != (roll == 0) ||
			(throw && intent.ItemID != missileID) {
			t.Fatalf("choice %d: roll %d, throw %v, intent %+v: %v",
				attempt, roll, throw, intent, err)
		}
	}
}

func TestKoboldPoisonDartAddsPlayerPoisonWithoutHPDamage(t *testing.T) {
	g := newStepGame(t)
	monsterID, missileID := equipTestKoboldMissile(t, g, "MI_DART")

	g.turn.Actor = monsterID

	playerHealth, _ := g.stores.Health.Get(g.player)
	beforeHP := playerHealth.Current
	intent := ecs.Intent{
		Kind:   ecs.IntentRanged,
		ItemID: missileID,
	}

	for attempt := 0; attempt < 100; attempt++ {
		g.turn.Events = nil

		if err := newCombatSystem(g).resolveKoboldThrow(&intent); err != nil {
			t.Fatal(err)
		}

		if poison, found := g.stores.Poison.Get(g.player); found {
			missile, _ := g.stores.Items.Get(missileID)

			if playerHealth.Current != beforeHP ||
				missile.Quantity != 4 ||
				poison.AmountScaled < 6000 ||
				poison.AmountScaled > 13000 ||
				poison.SourceMonsterID != "MONS_KOBOLD" ||
				len(g.turn.Events) != 3 {
				t.Fatalf("dart HP %d -> %d, item %+v, poison %+v, events %+v",
					beforeHP, playerHealth.Current, missile, poison, g.turn.Events)
			}

			return
		}
	}

	t.Fatal("poisoned dart never hit")
}

func TestKoboldThrowRejectsRemovedStackAfterIntent(t *testing.T) {
	g := newStepGame(t)
	monsterID, missileID := equipTestKoboldMissile(t, g, "MI_STONE")

	g.turn.Actor = monsterID

	intent := ecs.Intent{
		Kind:   ecs.IntentRanged,
		ItemID: missileID,
	}

	g.stores.Equipped.Remove(missileID)

	if err := newCombatSystem(g).resolveKoboldThrow(&intent); err == nil {
		t.Fatal("stale throw intent used a removed missile stack")
	}
}

func TestKoboldStoneRunsThroughOrderedMonsterSystems(t *testing.T) {
	catalog := testCatalog(t)

	for seed := uint64(1); seed <= 30; seed++ {
		g, err := NewScenario(seed, catalog, "WPN_RAPIER", "Tester")

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
