package game

import (
	"reflect"
	"slices"
	"strings"
	"testing"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

func newDartSlugGame(t *testing.T) (*Game, akara.Entity) {
	t.Helper()

	for seed := uint64(1); seed <= 100; seed++ {
		g, err := NewDungeonGame(
			seed,
			testCatalog(t),
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
				actor.KindID == "MONS_DART_SLUG" &&
				position.LevelID == 1 {
				t.Cleanup(func() {
					g.Close()
				})

				return g, entity
			}
		}

		g.Close()
	}

	t.Fatal("could not generate a Dungeon:1 dart slug")

	return nil, 0
}

func placePlayerInSlugLine(t *testing.T, g *Game, slug akara.Entity) {
	t.Helper()

	position, _ := g.stores.Positions.Get(slug)
	level := g.levels[position.LevelID]

	for _, delta := range []point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	} {
		for distance := 3; distance <= 5; distance++ {
			x := position.X + delta.x*distance
			y := position.Y + delta.y*distance

			if !level.ClearProjectilePath(position.X, position.Y, x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if err := level.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			if err := g.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			return
		}
	}

	t.Fatal("could not put player in a clear slug shot")
}

func TestDartSlugSourceProfileAndExperience(t *testing.T) {
	g, entity := newDartSlugGame(t)
	definition, err := g.catalog.Monster("MONS_DART_SLUG")

	if err != nil {
		t.Fatal(err)
	}

	actor, _ := g.stores.Actors.Get(entity)
	health, _ := g.stores.Health.Get(entity)
	roster, err := scenarioMonsterIDs(generatedDungeonScenarioID)

	if err != nil ||
		!slices.Contains(roster, definition.ID) ||
		actor.Speed != 7 ||
		health.Max < 6 ||
		health.Max > 14 ||
		definition.SpellbookID != "MST_DART_SLUG" ||
		!definition.LeavesCorpse {
		t.Fatalf("dart slug profile %+v %+v %+v: %v",
			actor, health, definition, err)
	}

	if _, err := character.OrdinaryNaturalExperience(definition, health.Max); err != nil {
		t.Fatal(err)
	}

	xp, err := character.OrdinaryNaturalExperience(definition, 10)

	if err != nil {
		t.Fatal(err)
	}

	if xp != 4 {
		t.Fatalf("dart slug at 10 HP awards %d XP: %v", xp, err)
	}

	fixed, _ := scenarioMonsterIDs(populationScenarioID)

	if slices.Contains(fixed, definition.ID) {
		t.Fatal("fixed population fixture changed")
	}
}

func TestDartSlugSpellFrequencyPathAndSaveContinuation(t *testing.T) {
	g, slug := newDartSlugGame(t)
	placePlayerInSlugLine(t, g, slug)
	position, _ := g.stores.Positions.Get(slug)
	player, _ := g.stores.Positions.Get(g.player)
	decision := newMonsterDecisionSystem(g)
	runtimeRNG := g.rng

	for _, roll := range []int{
		59,
		60,
		61,
	} {
		g.rng = NewRNGStreams(seedForSpellRoll(t, roll))

		decision.rng = g.rng

		spell, cast, err := decision.chooseMonsterSpell(slug, *position, *player)

		if err != nil ||
			spell != "SPELL_SLUG_DART" ||
			cast != (roll <= 60) {
			t.Fatalf("roll %d: %s, %v, %v", roll, spell, cast, err)
		}
	}

	g.rng = runtimeRNG

	for attempts := 0; attempts < 200; attempts++ {
		probe := RestoreRNGStreams(g.seed, g.rng.States())
		roll, err := probe.Intn("monster_spell", 200)

		if err != nil {
			t.Fatal(err)
		}

		if roll <= 60 {
			break
		}

		if _, err := g.rng.Intn("monster_spell", 200); err != nil {
			t.Fatal(err)
		}
	}

	before := g.Snapshot()
	loaded, err := Restore(before, g.catalog)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		loaded.Close()
	})

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("dart slug save changed on restore")
	}

	for _, current := range []*Game{g, loaded} {
		energy, _ := current.stores.MonsterEnergy.Get(slug)

		energy.Points = monster.ActionEnergyThreshold
	}

	liveEvents, err := g.runAction(slug, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	loadedEvents, err := loaded.runAction(slug, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	for _, current := range []*Game{g, loaded} {
		if err := current.scheduler.Spend(slug, current.turn.ResolvedIntent); err != nil {
			t.Fatal(err)
		}
	}

	liveEnergy, _ := g.stores.MonsterEnergy.Get(slug)
	loadedEnergy, _ := loaded.stores.MonsterEnergy.Get(slug)

	if g.turn.ResolvedIntent != ecs.IntentSpell ||
		liveEnergy.Points != 70 ||
		loadedEnergy.Points != 70 ||
		len(liveEvents) == 0 ||
		!strings.Contains(liveEvents[0].Text, "slug dart") ||
		!reflect.DeepEqual(liveEvents, loadedEvents) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("dart slug continuation differs: intents %d/%d, live %+v, loaded %+v",
			g.turn.ResolvedIntent,
			loaded.turn.ResolvedIntent,
			liveEvents,
			loadedEvents)
	}
}

func TestProjectilePathStopsAtTerrainAndActors(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]

	if !level.ClearProjectilePath(4, 1, 1, 1) {
		t.Fatal("open corridor did not admit shot")
	}

	row := []byte(level.terrain[1])

	row[3] = '#'
	level.terrain[1] = string(row)

	if level.ClearProjectilePath(4, 1, 1, 1) {
		t.Fatal("wall did not stop shot")
	}

	row[3] = '.'
	level.terrain[1] = string(row)

	blocker, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if err := level.PlaceActor(blocker, 3, 1); err != nil {
		t.Fatal(err)
	}

	if level.ClearProjectilePath(4, 1, 1, 1) {
		t.Fatal("actor did not stop shot")
	}

	slope, err := NewLevel(3, []string{
		"#####",
		"#...#",
		"#...#",
		"#####",
	}, g.stores.Positions)

	if err != nil {
		t.Fatal(err)
	}

	if !slope.ClearProjectilePath(1, 1, 3, 2) {
		t.Fatal("open shallow ray did not admit shot")
	}

	slope.terrain[2] = "#.#.#"

	if slope.ClearProjectilePath(1, 1, 3, 2) {
		t.Fatal("shallow ray skipped the crossed wall")
	}
}
