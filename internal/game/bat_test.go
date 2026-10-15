package game

import (
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
	"reflect"
	"testing"
)

func newBatGame(t *testing.T) (*Game, akara.Entity) {
	t.Helper()
	g, err := NewDungeonGame(
		1,
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

func TestGeneratedBatUsesCatalogStateAndSurvivesSave(t *testing.T) {
	g, batID := newBatGame(t)
	actor, _ := g.stores.Actors.Get(batID)
	health, _ := g.stores.Health.Get(batID)
	definition, _ := testCatalog(t).Monster("MONS_BAT")

	if actor.Speed != 30 ||
		definition.Speed != 30 ||
		health.Max < 2 ||
		health.Max > 5 {
		t.Fatalf("bat actor %+v, health %+v", actor, health)
	}

	loaded, err := Restore(g.Snapshot())

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

	definition, _ := testCatalog(t).Monster("MONS_BAT")

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
	definition, _ := testCatalog(t).Monster("MONS_BAT")

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

	if progress.TotalXP <= 0 {
		t.Fatalf("bat awarded %d XP", progress.TotalXP)
	}

	for _, entity := range g.stores.Corpses.Entities() {
		corpse, _ := g.stores.Corpses.Get(entity)

		if corpse.MonsterID != "MONS_BAT" {
			t.Fatalf("bat death left corpse %+v", corpse)
		}
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

	if loaded, err := Restore(batSnapshot); err == nil {
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

	if loaded, err := Restore(nonBatSnapshot); err == nil {
		loaded.Close()
		t.Fatal("restored a non-bat retreat counter")
	}
}
