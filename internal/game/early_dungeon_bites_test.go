package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

func seededPlainBiteMonster(
	t *testing.T,
	g *Game,
	kindID string,
	levelID int,
) akara.Entity {
	t.Helper()

	entity, found := findPlainBiteMonster(g, kindID, levelID)

	if !found {
		t.Fatalf("seeded D:%d has no %s", levelID, kindID)
	}

	return entity
}

func findPlainBiteMonster(g *Game, kindID string, levelID int) (
	akara.Entity, bool,
) {
	for _, entity := range g.stores.AI.Entities() {
		actor, found := g.stores.Actors.Get(entity)
		position, located := g.stores.Positions.Get(entity)

		if found &&
			located &&
			actor.KindID == kindID &&
			position.LevelID == levelID {
			return entity, true
		}
	}

	return 0, false
}

// The catalog picker is deterministic for a given seed, but adding a monster
// can change which seed contains a particular target. Find a suitable fixed
// scenario so this combat test measures save, XP, and corpse behavior.
func newSeededPlainBiteGame(
	t *testing.T,
	kindID string,
	levelID int,
) *Game {
	t.Helper()

	for seed := uint64(1); seed <= 64; seed++ {
		g, err := NewPopulatedScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if _, found := findPlainBiteMonster(g, kindID, levelID); found {
			return g
		}

		_ = g.Close()
	}

	t.Fatalf("no seeded D:%d has %s in 64 populations", levelID, kindID)

	return nil
}

func placePlayerBesideMonster(t *testing.T, g *Game, target akara.Entity) (int, int) {
	t.Helper()
	playerPosition, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	if err := g.levels[playerPosition.LevelID].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}

	targetPosition, found := g.stores.Positions.Get(target)

	if !found {
		t.Fatal("monster has no position")
	}

	level := g.levels[targetPosition.LevelID]

	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue
			}

			x := targetPosition.X - dx
			y := targetPosition.Y - dy

			if !level.Walkable(x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if err := level.PlaceActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			return dx, dy
		}
	}

	t.Fatal("monster has no free adjacent player cell")

	return 0, 0
}

func TestSeededEarlyDungeonBitesSurviveSaveAndAwardXP(t *testing.T) {
	for _, tc := range []struct {
		name    string
		kindID  string
		levelID int
	}{
		{
			name:    "giant cockroach on D:1",
			kindID:  "MONS_GIANT_COCKROACH",
			levelID: 1,
		},

		{
			name:    "worm on D:2",
			kindID:  "MONS_WORM",
			levelID: 2,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newSeededPlainBiteGame(t, tc.kindID, tc.levelID)

			defer g.Close()

			snapshot := g.Snapshot()
			loaded, err := Restore(snapshot)

			if err != nil {
				t.Fatal(err)
			}

			defer loaded.Close()

			if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
				t.Fatal("seeded monster changed across save and restore")
			}

			target := seededPlainBiteMonster(t, loaded, tc.kindID, tc.levelID)
			dx, dy := placePlayerBesideMonster(t, loaded, target)
			health, _ := loaded.stores.Health.Get(target)

			health.Current = 1

			for attempt := 0; attempt < 100 &&
				loaded.world.EntityExists(target); attempt++ {
				if _, err := loaded.runAction(loaded.player, ecs.Intent{
					Kind: ecs.IntentMelee,
					DX:   dx,
					DY:   dy,
				}, 10, "player"); err != nil {
					t.Fatal(err)
				}
			}

			if loaded.world.EntityExists(target) {
				t.Fatalf("%s survived 100 melee attacks", tc.kindID)
			}

			progress, _ := loaded.stores.Progression.Get(loaded.player)

			if progress.TotalXP <= 0 {
				t.Fatalf("%s awarded %d XP", tc.kindID, progress.TotalXP)
			}

			corpses := loaded.stores.Corpses.Entities()

			if len(corpses) != 1 {
				t.Fatalf("%s left %d corpses, want one", tc.kindID, len(corpses))
			}

			corpse, _ := loaded.stores.Corpses.Get(corpses[0])

			if corpse.MonsterID != tc.kindID {
				t.Fatalf("%s left corpse %+v", tc.kindID, corpse)
			}
		})
	}
}
