package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

func corpseDropSeed(t *testing.T, drop bool) uint64 {
	t.Helper()

	for seed := uint64(1); seed < 100; seed++ {
		coin, err := NewRNGStreams(seed).Intn("corpse", 2)

		if err != nil {
			t.Fatal(err)
		}

		if (coin == 0) == drop {
			return seed
		}
	}

	t.Fatal("no corpse seed")

	return 0
}

func testCorpseAt(t *testing.T, g *Game, kind string, position ecs.Position) akara.Entity {
	t.Helper()
	id, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(id, ecs.Item{
		KindID:   kind,
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Corpses.Set(id, ecs.Corpse{
		MonsterID:  "MONS_RAT",
		Freshness:  110,
		Appearance: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Positions.Set(id, position); err != nil {
		t.Fatal(err)
	}

	return id
}

func TestCockroachCorpseCannotBecomeSkeleton(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	defer g.Close()

	id := testCorpseAt(t, g, "CORPSE_BODY", ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       1,
	})

	corpse, _ := g.stores.Corpses.Get(id)

	corpse.MonsterID = "MONS_GIANT_COCKROACH"

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if err := loaded.runWorldPolicy("world.age_corpses", map[string]any{
		"level_id": 1,
		"elapsed":  2200,
	}); err != nil {
		t.Fatal(err)
	}

	if loaded.world.EntityExists(id) {
		t.Fatal("cockroach corpse survived as a skeleton")
	}

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID == uint64(id) {
			snapshot.Entities[index].Item.KindID = "CORPSE_SKELETON"
		}
	}

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("accepted impossible cockroach skeleton save")
	}
}

func TestRatDeathCorpseDropAndNoDrop(t *testing.T) {
	for _, drop := range []bool{false, true} {
		seed := corpseDropSeed(t, drop)
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		rat := ratID(t, g)

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			t.Fatal(err)
		}

		ratHP, _ := g.stores.Health.Get(rat)

		ratHP.Current = 1

		playerHP, _ := g.stores.Health.Get(g.player)

		playerHP.Current = 100
		playerHP.Max = 100

		for attempt := 0; attempt < 100 && g.world.EntityExists(rat); attempt++ {
			if _, err := g.Step(Command{
				Kind: CommandMove,
				DX:   1,
			}); err != nil {
				t.Fatal(err)
			}
		}

		if g.world.EntityExists(rat) {
			t.Fatal("rat survived")
		}

		corpses := g.stores.Corpses.Entities()

		if (len(corpses) == 1) != drop {
			t.Fatalf("seed %d drop=%v corpses=%v", seed, drop, corpses)
		}

		if drop {
			id := corpses[0]
			item, _ := g.stores.Items.Get(id)
			position, _ := g.stores.Positions.Get(id)
			corpse, _ := g.stores.Corpses.Get(id)

			if item.KindID != "CORPSE_BODY" || *position != (ecs.Position{
				LevelID: 1,
				X:       4,
				Y:       1,
			}) ||
				corpse.MonsterID != "MONS_RAT" ||
				corpse.Appearance < 1 ||
				corpse.Appearance > 255 {
				t.Fatalf("corpse %+v %+v %+v", item, position, corpse)
			}

			seen := false

			for _, entity := range g.View().Entities {
				if entity.ID == uint64(id) &&
					entity.Name == "rat corpse" &&
					entity.Glyph == '%' {
					seen = true
				}
			}

			if !seen {
				t.Fatal("rat corpse not named and displayed")
			}
		}

		g.Close()
	}
}

func TestPreDeadRatLeavesNoCorpse(t *testing.T) {
	g, err := NewScenario(corpseDropSeed(t, true), "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	hp, _ := g.stores.Health.Get(ratID(t, g))

	hp.Current = 0

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if len(g.stores.Corpses.Entities()) != 0 {
		t.Fatal("pre-dead cleanup spawned a corpse")
	}
}

func TestCorpseIsStationaryButPortableItemSharesTile(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 4, 2); err != nil {
		t.Fatal(err)
	}

	id := testCorpseAt(t, g, "CORPSE_BODY", ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       2,
	})

	result, err := g.Step(Command{Kind: CommandPickup})

	if err != nil ||
		result.Spent != 10 ||
		!g.stores.Positions.Has(id) ||
		!g.stores.CarriedBy.Has(potionID(t, g)) {
		t.Fatalf("mixed pickup %+v %v", result, err)
	}

	result, err = g.Step(Command{Kind: CommandPickup})

	if err != nil ||
		result.Spent != 0 ||
		!strings.Contains(result.Events[0].Text, "can't pick") ||
		!g.stores.Positions.Has(id) {
		t.Fatalf("corpse pickup %+v %v", result, err)
	}
}

func TestCorpseDecaysAtTwoHundredAutAndSurvivesSave(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	if !g.world.DestroyEntity(rat) {
		t.Fatal("rat removal")
	}

	id := testCorpseAt(t, g, "CORPSE_BODY", ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       1,
	})

	for range 19 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	corpse, _ := g.stores.Corpses.Get(id)

	if corpse.Freshness != 110 {
		t.Fatalf("decay before boundary = %d", corpse.Freshness)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if corpse.Freshness != 100 {
		t.Fatalf("decay at boundary = %d", corpse.Freshness)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("corpse save changed on restore")
	}

	for range 200 {
		if _, err := loaded.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	item, _ := loaded.stores.Items.Get(id)
	corpse, _ = loaded.stores.Corpses.Get(id)

	if item.KindID != "CORPSE_SKELETON" || corpse.Freshness != 110 {
		t.Fatalf("skeleton %+v %+v", item, corpse)
	}

	seenSkeleton := false

	for _, entity := range loaded.View().Entities {
		if entity.ID == uint64(id) &&
			entity.Name == "rat skeleton" &&
			entity.Glyph == '%' {
			seenSkeleton = true
		}
	}

	if !seenSkeleton {
		t.Fatal("rat skeleton not named and displayed")
	}

	for range 220 {
		if _, err := loaded.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if loaded.world.EntityExists(id) {
		t.Fatal("skeleton did not decay away")
	}
}

// A source never_decay specimen keeps its body and freshness across timer
// boundaries and save/restore; the flag belongs to this item, not the kind.
func TestNeverDecayingCorpseSurvivesTimeAndRestore(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	if !g.world.DestroyEntity(rat) {
		t.Fatal("rat removal")
	}

	id := testCorpseAt(t, g, "CORPSE_BODY", ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       1,
	})

	corpse, _ := g.stores.Corpses.Get(id)

	corpse.NeverDecays = true

	if _, err := g.stores.Corpses.Set(id, *corpse); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	for range 60 {
		if _, err := loaded.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	item, found := loaded.stores.Items.Get(id)
	corpse, corpseFound := loaded.stores.Corpses.Get(id)

	if !found ||
		!corpseFound ||
		item.KindID != "CORPSE_BODY" ||
		corpse.Freshness != 110 ||
		!corpse.NeverDecays {
		t.Fatalf("never-decay corpse changed: item %+v, corpse %+v",
			item, corpse)
	}
}

func TestInactiveCorpseGetsOneCatchUpOnReturn(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	if !g.world.DestroyEntity(rat) {
		t.Fatal("rat removal")
	}

	quokka := quokkaID(t, g)

	if err := g.levels[2].RemoveActor(quokka); err != nil ||
		!g.world.DestroyEntity(quokka) {
		t.Fatalf("quokka removal: %v", err)
	}

	lizard := frilledLizardID(t, g)

	if err := g.levels[2].RemoveActor(lizard); err != nil ||
		!g.world.DestroyEntity(lizard) {
		t.Fatalf("frilled lizard removal: %v", err)
	}

	id := testCorpseAt(t, g, "CORPSE_BODY", ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       1,
	})

	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	for range 220 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	corpse, _ := g.stores.Corpses.Get(id)

	if corpse.Freshness != 110 {
		t.Fatalf("inactive corpse aged before return: %d", corpse.Freshness)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("away clock changed on restore")
	}

	for range 220 {
		if _, err := loaded.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if _, err := loaded.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	item, present := loaded.stores.Items.Get(id)
	corpse, _ = loaded.stores.Corpses.Get(id)

	if !present ||
		item.KindID != "CORPSE_SKELETON" || corpse.Freshness != 110 {
		t.Fatalf("source return catch-up should reset one skeleton: %+v %+v", item, corpse)
	}
}

func TestRestoreRejectsMalformedCorpseState(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()

	for _, mutate := range []func(*ecs.Item, *ecs.Corpse, *ecs.Position){
		func(_ *ecs.Item, corpse *ecs.Corpse, _ *ecs.Position) {
			corpse.MonsterID = "MONS_ORC"
		},

		func(_ *ecs.Item, corpse *ecs.Corpse, _ *ecs.Position) {
			corpse.Freshness = 0
		},

		func(_ *ecs.Item, corpse *ecs.Corpse, _ *ecs.Position) {
			corpse.Appearance = 256
		},

		func(item *ecs.Item, _ *ecs.Corpse, _ *ecs.Position) {
			item.KindID = "POT_CURING"
		},
	} {
		id := testCorpseAt(t, g, "CORPSE_BODY", ecs.Position{
			LevelID: 1,
			X:       4,
			Y:       1,
		})

		bad := g.Snapshot()

		for i := range bad.Entities {
			if bad.Entities[i].ID == uint64(id) {
				mutate(bad.Entities[i].Item, bad.Entities[i].Corpse, bad.Entities[i].Position)
			}
		}

		if loaded, err := Restore(bad); err == nil {
			loaded.Close()
			t.Fatal("accepted malformed corpse")
		}

		g.world.DestroyEntity(id)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("test corruptions changed live game")
	}
}

func TestRestoreRejectsInvalidCorpseFloorClock(t *testing.T) {
	g := newStepGame(t)
	id := testCorpseAt(t, g, "CORPSE_BODY", ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       1,
	})

	active := g.Snapshot()
	zero := int64(0)

	active.Levels[0].AwaySinceAut = &zero

	if loaded, err := Restore(active); err == nil {
		loaded.Close()
		t.Fatal("accepted active floor marked away")
	}

	inactive := g.Snapshot()

	for i := range inactive.Entities {
		if inactive.Entities[i].ID == uint64(id) {
			inactive.Entities[i].Position.LevelID = 2
		}
	}

	if loaded, err := Restore(inactive); err == nil {
		loaded.Close()
		t.Fatal("accepted inactive corpse without away clock")
	}
}
