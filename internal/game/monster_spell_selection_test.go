package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

func moddedEndoplasmGame(t *testing.T) (*Game, akara.Entity, modfs.Ruleset) {
	t.Helper()

	rules, err := modfs.Load("testdata/monster-spell-selection")

	if err != nil {
		t.Fatal(err)
	}

	for seed := uint64(1); seed <= 500; seed++ {
		probe := NewRNGStreams(seed)
		roll, err := probe.Intn("monster_spell", 200)

		if err != nil {
			t.Fatal(err)
		}

		if roll < 10 || roll > 27 {
			continue
		}

		g, err := NewDungeonGameWithRules(
			seed,
			"SP_HUMAN",
			"JOB_FIGHTER",
			"WPN_FLAIL",
			"Tester",
			rules,
		)

		if err != nil {
			t.Fatal(err)
		}

		for _, entity := range g.stores.AI.Entities() {
			actor, found := g.stores.Actors.Get(entity)
			position, located := g.stores.Positions.Get(entity)

			if found &&
				located &&
				actor.KindID == "MONS_ENDOPLASM" &&
				position.LevelID == 1 {
				t.Cleanup(func() {
					g.Close()
				})

				return g, entity, rules
			}
		}

		g.Close()
	}

	t.Fatal("could not generate an endoplasm with a second-slot draw")

	return nil, 0, modfs.Ruleset{}
}

func TestModdedMonsterBookCastsSecondSlotAndRestores(t *testing.T) {
	g, entity, rules := moddedEndoplasmGame(t)
	placePlayerInSlugLine(t, g, entity)

	energy, _ := g.stores.MonsterEnergy.Get(entity)

	energy.Points = 80

	events, err := g.runAction(entity, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("resolved intent = %d, want monster spell",
			g.turn.ResolvedIntent)
	}

	cast := false

	for _, event := range events {
		if strings.Contains(event.Text, "slug dart") {
			cast = true
		}
	}

	if !cast {
		t.Fatalf("second-slot slug dart was not cast: %+v", events)
	}

	if err := g.scheduler.Spend(entity, ecs.Intent{
		Kind:   g.turn.ResolvedIntent,
		ItemID: g.turn.ResolvedItemID,
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("second-slot cast changed on save restore")
	}

	for _, current := range []*Game{g, restored} {
		ready, _ := current.stores.MonsterEnergy.Get(entity)

		ready.Points = 80
	}

	nextOriginal, err := g.runAction(entity, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	originalIntent := g.turn.ResolvedIntent
	nextRestored, err := restored.runAction(entity, ecs.Intent{}, 10,
		"monster")

	if err != nil {
		t.Fatal(err)
	}

	if originalIntent != restored.turn.ResolvedIntent ||
		!reflect.DeepEqual(nextOriginal, nextRestored) ||
		!reflect.DeepEqual(g.rng.States(), restored.rng.States()) {
		t.Fatalf("monster spell continuation diverged: intent %d/%d, "+
			"events %+v/%+v, RNG %+v/%+v",
			originalIntent,
			restored.turn.ResolvedIntent,
			nextOriginal,
			nextRestored,
			g.rng.States(),
			restored.rng.States())
	}
}
