package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

func frilledLizardID(t *testing.T, g *Game) akara.Entity {
	t.Helper()
	for _, entity := range g.stores.AI.Entities() {
		actor, found := g.stores.Actors.Get(entity)
		if found && actor.KindID == "MONS_FRILLED_LIZARD" {
			return entity
		}
	}
	t.Fatal("frilled lizard encounter is missing")
	return 0
}

func TestFrilledLizardUsesOrdinaryMeleeDeathAndExperience(t *testing.T) {
	g, err := NewScenario(corpseDropSeed(t, true), testCatalog(t), "WPN_RAPIER", "Tester")
	if err != nil {
		t.Fatal(err)
	}
	defer g.Close()
	lizard := frilledLizardID(t, g)
	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}
	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].MoveActor(lizard, 4, 1); err != nil {
		t.Fatal(err)
	}
	health, _ := g.stores.Health.Get(lizard)
	health.Current = 1
	for attempt := 0; attempt < 100 && g.world.EntityExists(lizard); attempt++ {
		result, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})
		if err != nil {
			t.Fatal(err)
		}
		if result.View.PlayerDead {
			t.Fatal("player died before the frilled lizard")
		}
	}
	if g.world.EntityExists(lizard) {
		t.Fatal("frilled lizard survived 100 attacks")
	}
	progress, _ := g.stores.Progression.Get(g.player)
	if progress.TotalXP != 1 {
		t.Fatalf("frilled lizard granted %d XP, want 1", progress.TotalXP)
	}
	seenDeath := false
	for _, message := range g.View().Messages {
		seenDeath = seenDeath || strings.Contains(message, "frilled lizard dies")
	}
	if !seenDeath {
		t.Fatal("frilled lizard death message missing")
	}
	if len(g.stores.Corpses.Entities()) != 1 {
		t.Fatalf("frilled lizard dropped %d corpses, want one", len(g.stores.Corpses.Entities()))
	}
	for _, corpseID := range g.stores.Corpses.Entities() {
		corpse, _ := g.stores.Corpses.Get(corpseID)
		if corpse.MonsterID != "MONS_FRILLED_LIZARD" {
			t.Fatalf("wrong corpse kind %+v", corpse)
		}
	}
	before := g.Snapshot()
	loaded, err := Restore(before, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("frilled-lizard kill did not survive save restore")
	}
}

func TestFrilledLizardEncounterUsesCatalogAndSurvivesSave(t *testing.T) {
	g := newStepGame(t)
	lizard := frilledLizardID(t, g)
	definition, err := g.catalog.Monster("MONS_FRILLED_LIZARD")
	if err != nil {
		t.Fatal(err)
	}
	actor, _ := g.stores.Actors.Get(lizard)
	health, _ := g.stores.Health.Get(lizard)
	position, _ := g.stores.Positions.Get(lizard)
	ai, _ := g.stores.AI.Get(lizard)
	if definition.Name != "frilled lizard" || definition.AverageHP10x != 20 || definition.Attacks[0].Damage != 3 ||
		actor.Speed != definition.Speed || *position != (ecs.Position{
		LevelID: 2,
		X:       14,
		Y:       1,
	}) ||
		health.Current < 1 || health.Current > 3 || health.Max != health.Current || ai.Behavior != "wander" {
		t.Fatalf("lizard definition %+v actor %+v health %+v position %+v AI %+v", definition, actor, health, position, ai)
	}
	wantRNG := NewRNGStreams(g.seed)
	for _, average := range []int{25, 55, 20} {
		if _, err := monster.RollHP(wantRNG, average); err != nil {
			t.Fatal(err)
		}
	}
	if !reflect.DeepEqual(wantRNG.States(), g.rng.States()) {
		t.Fatal("monster factory used unexpected RNG streams or draw order")
	}
	loaded, err := Restore(g.Snapshot(), testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("lizard state changed across save restore")
	}
}

func TestPreviousTwoAnimalScenarioSaveStillLoads(t *testing.T) {
	g := newStepGame(t)
	previous := g.Snapshot()
	previous.ScenarioID = legacyAnimalScenarioID
	for i := len(previous.Entities) - 1; i >= 0; i-- {
		if previous.Entities[i].Actor != nil && previous.Entities[i].Actor.KindID == "MONS_FRILLED_LIZARD" {
			previous.Entities = append(previous.Entities[:i], previous.Entities[i+1:]...)
		}
	}
	previousRNG := NewRNGStreams(g.seed)
	for _, average := range []int{25, 55} {
		if _, err := monster.RollHP(previousRNG, average); err != nil {
			t.Fatal(err)
		}
	}
	previous.RNG = previousRNG.States()
	loaded, err := Restore(previous, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	if !reflect.DeepEqual(previous, loaded.Snapshot()) {
		t.Fatal("previous two-animal save changed on load")
	}
}
