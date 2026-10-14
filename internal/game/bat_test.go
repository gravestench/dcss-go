package game

import (
	"reflect"
	"slices"
	"strings"
	"testing"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func newBatGame(t *testing.T) (*Game, akara.Entity) {
	t.Helper()
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGame(
		1,
		catalog,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_FLAIL",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	for _, entity := range g.stores.AI.Entities() {
		actor, found := g.stores.Actors.Get(entity)
		position, located := g.stores.Positions.Get(entity)

		if found &&
			located &&
			actor.KindID == "MONS_BAT" &&
			position.LevelID == 1 {
			return g, entity
		}
	}

	t.Fatal("seeded generated Dungeon has no bat")

	return nil, 0
}

func TestGeneratedDungeonSupportsSourceBatPopulation(t *testing.T) {
	ids, err := scenarioMonsterIDs(generatedDungeonScenarioID)

	if err != nil {
		t.Fatal(err)
	}

	if !slices.Contains(ids, "MONS_BAT") {
		t.Fatal("generated Dungeon excludes its source D:1 bat")
	}

	legacy, err := scenarioMonsterIDs(ordinaryMonsterScenarioID)

	if err != nil {
		t.Fatal(err)
	}

	if slices.Contains(legacy, "MONS_BAT") {
		t.Fatal("legacy fixed scenario changed its monster roster")
	}
}

func TestGeneratedBatUsesCatalogStateAndSurvivesSave(t *testing.T) {
	g, batID := newBatGame(t)
	actor, _ := g.stores.Actors.Get(batID)
	health, _ := g.stores.Health.Get(batID)
	definition, _ := g.catalog.Monster("MONS_BAT")

	if actor.Speed != 30 ||
		definition.Speed != 30 ||
		health.Max < 2 ||
		health.Max > 5 {
		t.Fatalf("bat actor %+v, health %+v", actor, health)
	}

	loaded, err := Restore(g.Snapshot(), g.catalog)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		loaded.Close()
	})

	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("generated bat changed across save and restore")
	}
}

func TestVisibleBatUsesCatalogGlyphInDungeonView(t *testing.T) {
	g, batID := newBatGame(t)
	placePlayerBesideMonster(t, g, batID)

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	definition, _ := g.catalog.Monster("MONS_BAT")

	for _, entity := range g.View().Entities {
		if entity.ID != uint64(batID) {
			continue
		}

		if entity.Glyph != definition.Glyph || entity.Name != definition.Name {
			t.Fatalf("bat view %+v differs from catalog %+v", entity, definition)
		}

		return
	}

	t.Fatal("visible bat is missing from the Dungeon view")
}

func TestGeneratedBatDeathAwardsSourceXPAndCanLeaveCorpse(t *testing.T) {
	g, batID := newBatGame(t)
	dx, dy := placePlayerBesideMonster(t, g, batID)
	health, _ := g.stores.Health.Get(batID)
	definition, _ := g.catalog.Monster("MONS_BAT")
	wantXP, err := character.OrdinaryNaturalExperience(definition, health.Max)

	if err != nil {
		t.Fatal(err)
	}

	if !definition.LeavesCorpse {
		t.Fatal("source bat is not corpse eligible")
	}

	health.Current = 1

	for attempt := 0; attempt < 100 && g.world.EntityExists(batID); attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind: ecs.IntentMelee,
			DX:   dx,
			DY:   dy,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}
	}

	if g.world.EntityExists(batID) {
		t.Fatal("bat survived 100 melee attacks")
	}

	progress, _ := g.stores.Progression.Get(g.player)

	if progress.TotalXP != wantXP {
		t.Fatalf("bat awarded %d XP, want %d", progress.TotalXP, wantXP)
	}

	for _, entity := range g.stores.Corpses.Entities() {
		corpse, _ := g.stores.Corpses.Get(entity)

		if corpse.MonsterID != "MONS_BAT" {
			t.Fatalf("bat death left corpse %+v", corpse)
		}
	}
}

func TestBatRetreatBeginsAfterMissedMelee(t *testing.T) {
	g, batID := newBatGame(t)
	batAI, _ := g.stores.AI.Get(batID)
	playerPosition, _ := g.stores.Positions.Get(g.player)

	batAI.Behavior = "seek"
	batAI.TargetX = playerPosition.X
	batAI.TargetY = playerPosition.Y
	batAI.MemoryUntilAut = 400
	g.turn.Actor = batID

	system := newCombatSystem(g)

	system.roller = zeroMeleeRoller{}

	playerHealth, _ := g.stores.Health.Get(g.player)

	if err := system.resolveMonsterMelee(playerHealth); err != nil {
		t.Fatal(err)
	}

	if batAI.Behavior != "wander" ||
		batAI.TargetX != 0 ||
		batAI.TargetY != 0 {
		t.Fatalf("bat did not retreat after miss: %+v", batAI)
	}
}

func TestBatPlainHitUsesSourceVerbAndBeginsRetreat(t *testing.T) {
	g, batID := newBatGame(t)

	g.turn.Actor = batID

	playerHealth, _ := g.stores.Health.Get(g.player)
	before := playerHealth.Current
	rolls := []combatRoll{
		{
			bound: 20,
			value: 19,
		},

		{
			bound: 10,
			value: 0,
		},

		{
			bound: 11,
			value: 0,
		},

		{
			bound: 100,
			value: 10,
		},

		{
			bound: 15,
			value: 14,
		},

		{
			bound: 18,
			value: 0,
		},

		{
			bound: 19,
			value: 0,
		},

		{
			bound: 7,
			value: 0,
		},
	}

	roller := &combatRoller{rolls: rolls}
	system := newCombatSystem(g)

	system.roller = roller

	if err := system.resolveMonsterMelee(playerHealth); err != nil {
		t.Fatal(err)
	}

	batAI, _ := g.stores.AI.Get(batID)

	if playerHealth.Current != before-1 ||
		len(roller.rolls) != 0 ||
		batAI.BatRetreatActions != 2 ||
		len(g.turn.Events) != 1 ||
		!strings.Contains(g.turn.Events[0].Text, "bat hits you for 1 damage") {
		t.Fatalf("bat hit: HP %d->%d, AI %+v, events %+v, rolls %+v",
			before, playerHealth.Current, batAI, g.turn.Events, roller.rolls)
	}
}

func TestBatWandersTwiceAfterAttack(t *testing.T) {
	g, batID := newBatGame(t)
	placePlayerBesideMonster(t, g, batID)
	batAI, _ := g.stores.AI.Get(batID)

	batAI.Behavior = "wander"
	batAI.TargetX = 0
	batAI.TargetY = 0
	batAI.BatRetreatActions = 2

	decision := newMonsterDecisionSystem(g)

	intent, err := decision.chooseIntent(batID)

	if err != nil {
		t.Fatal(err)
	}

	if intent.Kind == ecs.IntentMelee ||
		batAI.BatRetreatActions != 1 ||
		batAI.Behavior != "wander" {
		t.Fatalf("bat did not wander on first later action: %+v, %+v", intent, batAI)
	}

	intent, err = decision.chooseIntent(batID)

	if err != nil {
		t.Fatal(err)
	}

	if batAI.BatRetreatActions != 0 ||
		batAI.Behavior != "seek" ||
		intent.Kind == ecs.IntentMelee {
		t.Fatalf("bat did not finish its second wander: %+v, %+v", intent, batAI)
	}

	intent, err = decision.chooseIntent(batID)

	if err != nil {
		t.Fatal(err)
	}

	if intent.Kind != ecs.IntentMelee {
		t.Fatalf("bat failed to resume pursuit on third later action: %+v", intent)
	}
}

func TestRestoreRejectsImpossibleBatRetreatCounters(t *testing.T) {
	g, batID := newBatGame(t)
	batSnapshot := g.Snapshot()

	for index := range batSnapshot.Entities {
		if batSnapshot.Entities[index].ID == uint64(batID) {
			batSnapshot.Entities[index].AI.BatRetreatActions = 3
		}
	}

	if loaded, err := Restore(batSnapshot, g.catalog); err == nil {
		loaded.Close()
		t.Fatal("restored bat with impossible retreat counter")
	}

	nonBatSnapshot := g.Snapshot()
	changed := false

	for index := range nonBatSnapshot.Entities {
		record := &nonBatSnapshot.Entities[index]

		if record.AI == nil || record.Actor.KindID == "MONS_BAT" {
			continue
		}

		record.AI.BatRetreatActions = 1
		changed = true

		break
	}

	if !changed {
		t.Fatal("generated Dungeon has no non-bat comparison")
	}

	if loaded, err := Restore(nonBatSnapshot, g.catalog); err == nil {
		loaded.Close()
		t.Fatal("restored a non-bat retreat counter")
	}
}

func TestBatRetreatContinuesFromSavedAIAndRNG(t *testing.T) {
	g, batID := newBatGame(t)
	placePlayerBesideMonster(t, g, batID)
	batAI, _ := g.stores.AI.Get(batID)

	batAI.Behavior = "wander"
	batAI.TargetX = 0
	batAI.TargetY = 0
	batAI.MemoryUntilAut = 0
	batAI.BatRetreatActions = 2

	loaded, err := Restore(g.Snapshot(), g.catalog)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		loaded.Close()
	})

	want, err := newMonsterDecisionSystem(g).chooseIntent(batID)

	if err != nil {
		t.Fatal(err)
	}

	got, err := newMonsterDecisionSystem(loaded).chooseIntent(batID)

	if err != nil {
		t.Fatal(err)
	}

	loadedAI, _ := loaded.stores.AI.Get(batID)

	if want != got ||
		!reflect.DeepEqual(batAI, loadedAI) ||
		!reflect.DeepEqual(g.rng.States(), loaded.rng.States()) {
		t.Fatalf("bat retreat diverged after restore: %+v / %+v", want, got)
	}
}
