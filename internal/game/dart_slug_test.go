package game

import (
	"github.com/gravestench/akara"
	"testing"
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

	if actor.Speed != 7 ||
		health.Max < 6 ||
		health.Max > 14 ||
		definition.SpellbookID != "MST_DART_SLUG" ||
		!definition.LeavesCorpse {
		t.Fatalf("dart slug profile %+v %+v %+v: %v",
			actor, health, definition, err)
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
