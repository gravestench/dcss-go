package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func spawnWormForTest(t *testing.T, g *Game, levelID int) akara.Entity {
	t.Helper()
	level := g.levels[levelID]
	definition, err := testCatalog(t).Monster("MONS_WORM")

	if err != nil {
		t.Fatal(err)
	}

	for y, row := range level.terrain {
		for x := range row {
			if fixtureGlyph(row[x]) != '.' {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			worm, err := g.world.CreateEntity()

			if err != nil {
				t.Fatal(err)
			}

			if _, err := g.stores.Actors.Set(worm, ecs.Actor{
				KindID: "MONS_WORM",
				Speed:  definition.Speed,
			}); err != nil {
				t.Fatal(err)
			}

			if _, err := g.stores.Health.Set(worm, ecs.Health{
				Current: 10,
				Max:     10,
			}); err != nil {
				t.Fatal(err)
			}

			if _, err := g.stores.AI.Set(worm, ecs.MonsterAI{Behavior: "wander"}); err != nil {
				t.Fatal(err)
			}

			if _, err := g.stores.MonsterEnergy.Set(worm, ecs.MonsterEnergy{Points: 0}); err != nil {
				t.Fatal(err)
			}

			if _, err := g.stores.Combat.Set(worm, ecs.Combatant{}); err != nil {
				t.Fatal(err)
			}

			if err := level.PlaceActor(worm, x, y); err != nil {
				t.Fatal(err)
			}

			return worm
		}
	}

	t.Fatalf("D:%d has no free worm spawn cell", levelID)

	return 0
}
