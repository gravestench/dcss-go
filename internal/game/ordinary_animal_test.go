package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func quokkaID(t *testing.T, g *Game) akara.Entity {
	t.Helper()
	for _, entity := range g.stores.AI.Entities() {
		actor, ok := g.stores.Actors.Get(entity)
		if ok && actor.KindID == "MONS_QUOKKA" {
			return entity
		}
	}
	t.Fatal("fixture quokka is missing")
	return 0
}

func TestQuokkaScenarioUsesCatalogSpeedHPAndSave(t *testing.T) {
	g := newStepGame(t)
	quokka := quokkaID(t, g)
	actor, _ := g.stores.Actors.Get(quokka)
	position, _ := g.stores.Positions.Get(quokka)
	health, _ := g.stores.Health.Get(quokka)
	definition, err := g.catalog.Monster("MONS_QUOKKA")
	if err != nil || actor.Speed != definition.Speed || actor.Speed != 12 || *position != (ecs.Position{LevelID: 2, X: 14, Y: 7}) || health.Max < 3 || health.Max > 8 {
		t.Fatalf("quokka actor %+v position %+v health %+v definition %+v: %v", actor, position, health, definition, err)
	}
	if _, err := character.OrdinaryAnimalExperience(definition, health.Max); err != nil {
		t.Fatal(err)
	}
	loaded, err := Restore(g.Snapshot(), testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("quokka HP or schedule changed on save restore")
	}
}

func TestUnseenQuokkaDoesNotAnnounceItsTurns(t *testing.T) {
	g := newStepGame(t)
	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}
	result, err := g.Step(Command{Kind: CommandDownstairs})
	if err != nil {
		t.Fatal(err)
	}
	if result.View.LevelID != 2 {
		t.Fatalf("downstairs reached level %d", result.View.LevelID)
	}
	for _, entity := range result.View.Entities {
		if entity.KindID == "MONS_QUOKKA" {
			t.Fatal("fixture quokka should start outside sight")
		}
	}
	for _, event := range result.Events {
		if strings.Contains(strings.ToLower(event.Text), "quokka") {
			t.Fatalf("unseen quokka announced: %+v", event)
		}
	}
	for _, message := range result.View.Messages {
		if strings.Contains(strings.ToLower(message), "quokka") {
			t.Fatalf("unseen quokka announced in messages: %q", message)
		}
	}
}

func TestQuokkaMeleeDeathExperienceAndCorpse(t *testing.T) {
	g, err := NewScenario(corpseDropSeed(t, true), testCatalog(t), "WPN_RAPIER", "Tester")
	if err != nil {
		t.Fatal(err)
	}
	defer g.Close()
	quokka := quokkaID(t, g)
	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].MoveActor(quokka, 14, 7); err != nil {
		t.Fatal(err)
	}
	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}
	if err := g.levels[2].MoveActor(quokka, 4, 1); err != nil {
		t.Fatal(err)
	}
	health, _ := g.stores.Health.Get(quokka)
	health.Current = 1
	definition, _ := g.catalog.Monster("MONS_QUOKKA")
	wantXP, err := character.OrdinaryAnimalExperience(definition, health.Max)
	if err != nil {
		t.Fatal(err)
	}
	for attempt := 0; attempt < 100 && g.world.EntityExists(quokka); attempt++ {
		result, err := g.Step(Command{Kind: CommandMove, DX: 1})
		if err != nil {
			t.Fatal(err)
		}
		if result.View.PlayerDead {
			t.Fatal("player died before quokka test kill")
		}
	}
	if g.world.EntityExists(quokka) {
		t.Fatal("quokka survived 100 attacks")
	}
	progress, _ := g.stores.Progression.Get(g.player)
	if progress.TotalXP != wantXP {
		t.Fatalf("quokka awarded %d XP, want %d", progress.TotalXP, wantXP)
	}
	seenDeath := false
	for _, message := range g.View().Messages {
		seenDeath = seenDeath || strings.Contains(message, "quokka dies")
	}
	if !seenDeath {
		t.Fatal("quokka death message missing")
	}
	if len(g.stores.Corpses.Entities()) != 1 {
		t.Fatalf("quokka drop count = %d", len(g.stores.Corpses.Entities()))
	}
	for _, corpseID := range g.stores.Corpses.Entities() {
		corpse, _ := g.stores.Corpses.Get(corpseID)
		if corpse.MonsterID != "MONS_QUOKKA" {
			t.Fatalf("wrong corpse kind %+v", corpse)
		}
		seen := false
		for _, entity := range g.View().Entities {
			if entity.ID == uint64(corpseID) && entity.Name == "quokka corpse" {
				seen = true
			}
		}
		if !seen {
			t.Fatal("quokka corpse was not named in view")
		}
	}
	loaded, err := Restore(g.Snapshot(), testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("quokka kill did not survive save")
	}
}

func TestLegacyRatOnlySaveStillLoads(t *testing.T) {
	g := newStepGame(t)
	legacy := g.Snapshot()
	legacy.ScenarioID = ""
	for i := len(legacy.Entities) - 1; i >= 0; i-- {
		if legacy.Entities[i].Actor != nil && legacy.Entities[i].Actor.KindID != "MONS_RAT" && legacy.Entities[i].AI != nil {
			legacy.Entities = append(legacy.Entities[:i], legacy.Entities[i+1:]...)
		}
	}
	loaded, err := Restore(legacy, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()
	if !reflect.DeepEqual(legacy, loaded.Snapshot()) {
		t.Fatal("legacy rat-only version-6 save changed on load")
	}
}
