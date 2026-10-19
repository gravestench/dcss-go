package game

import (
	"crawl/internal/content"
	"crawl/internal/ecs"
	"github.com/gravestench/akara"
	"reflect"
	"strings"
	"testing"
)

func newEndoplasmGame(
	t *testing.T,
	wantCast bool,
) (*Game, akara.Entity) {
	t.Helper()

	for seed := uint64(1); seed <= 200; seed++ {
		probe := NewRNGStreams(seed)
		roll, err := probe.Intn("monster_spell", 200)

		if err != nil {
			t.Fatal(err)
		}

		if (roll <= 70) != wantCast {
			continue
		}

		g, err := NewDungeonGame(
			seed,
			"SP_HUMAN",
			"JOB_FIGHTER",
			"WPN_FLAIL",
			"Tester",
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

				return g, entity
			}
		}

		g.Close()
	}

	t.Fatal("could not generate D:1 endoplasm with desired spell draw")

	return nil, 0
}

func TestEndoplasmUsesSourcePopulationProfile(t *testing.T) {
	g, entity := newEndoplasmGame(t, true)
	definition, err := testCatalog(t).Monster("MONS_ENDOPLASM")

	if err != nil {
		t.Fatal(err)
	}

	actor, _ := g.stores.Actors.Get(entity)
	health, _ := g.stores.Health.Get(entity)

	if actor.Speed != 10 ||
		health.Max < 4 ||
		health.Max > 8 ||
		definition.LeavesCorpse {
		t.Fatalf("endoplasm source profile %+v %+v %+v: %v",
			actor, health, definition, err)
	}

}

func TestEndoplasmFreezeUsesSpellIntentAndEnergy(t *testing.T) {
	g, entity := newEndoplasmGame(t, true)
	placePlayerBesideMonster(t, g, entity)

	expected := RestoreRNGStreams(g.seed, g.rng.States())
	choice, _ := expected.Intn("monster_spell", 200)
	damageRoll, _ := expected.Intn("monster_spell", 5)

	if choice > 70 {
		t.Fatalf("seed %d did not select Freeze: %d", g.seed, choice)
	}

	playerHealth, _ := g.stores.Health.Get(g.player)
	energy, _ := g.stores.MonsterEnergy.Get(entity)
	before := playerHealth.Current

	energy.Points = 80

	events, err := g.runAction(entity, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell ||
		playerHealth.Current != before-(damageRoll+1) ||
		len(events) == 0 ||
		!strings.Contains(events[0].Text, "frozen") {
		t.Fatalf("Freeze action %+v, HP %d -> %d, intent %d",
			events, before, playerHealth.Current, g.turn.ResolvedIntent)
	}

	if err := g.scheduler.Spend(entity, ecs.Intent{
		Kind:   g.turn.ResolvedIntent,
		ItemID: g.turn.ResolvedItemID,
	}); err != nil {
		t.Fatal(err)
	}

	if energy.Points != 70 ||
		g.rng.States()["monster_spell"] != expected.States()["monster_spell"] {
		t.Fatalf("Freeze energy %d, RNG %+v", energy.Points, g.rng.States())
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	beforeSave := g.Snapshot()
	loaded, err := Restore(beforeSave)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		loaded.Close()
	})

	if !reflect.DeepEqual(beforeSave, loaded.Snapshot()) {
		t.Fatal("Freeze action changed on save restore")
	}

	for _, current := range []*Game{g, loaded} {
		current.scheduler.Grant(1, 10)
	}

	liveEvents, err := g.runAction(entity, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	loadedEvents, err := loaded.runAction(entity, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(liveEvents, loadedEvents) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("Freeze continuation differs: live %+v, loaded %+v",
			liveEvents, loadedEvents)
	}
}

func TestEndoplasmCanUseOrdinaryMeleeWhenNoSpellChosen(t *testing.T) {
	g, entity := newEndoplasmGame(t, false)
	placePlayerBesideMonster(t, g, entity)

	if _, err := g.runAction(entity, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentMelee {
		t.Fatalf("endoplasm fallback intent %d", g.turn.ResolvedIntent)
	}
}

func seedForSpellRoll(t *testing.T, target int) uint64 {
	t.Helper()

	for seed := uint64(1); seed < 10000; seed++ {
		roll, err := NewRNGStreams(seed).Intn("monster_spell", 200)

		if err != nil {
			t.Fatal(err)
		}

		if roll == target {
			return seed
		}
	}

	t.Fatalf("no seed yields spell roll %d", target)

	return 0
}

func TestEndoplasmSourceSpellbookMatchesCatalog(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	definition, _ := catalog.Monster("MONS_ENDOPLASM")
	slots, err := catalog.MonsterSpellbook(definition.SpellbookID)

	if err != nil ||
		len(slots) != 1 ||
		slots[0].SpellID != "SPELL_FREEZE" {
		t.Fatalf("endoplasm book %+v, %v", slots, err)
	}
}

func TestRestoreRejectsEndoplasmCorpse(t *testing.T) {
	g, entity := newEndoplasmGame(t, true)
	position, _ := g.stores.Positions.Get(entity)
	corpseID := testCorpseAt(t, g, "CORPSE_BODY", *position)
	corpse, _ := g.stores.Corpses.Get(corpseID)

	corpse.MonsterID = "MONS_ENDOPLASM"

	if loaded, err := Restore(g.Snapshot()); err == nil {
		loaded.Close()
		t.Fatal("accepted impossible endoplasm corpse")
	}
}
