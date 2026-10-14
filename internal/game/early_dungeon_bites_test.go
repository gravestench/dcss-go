package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func seededPlainBiteMonster(
	t *testing.T,
	g *Game,
	kindID string,
	levelID int,
) akara.Entity {
	t.Helper()

	for _, entity := range g.stores.AI.Entities() {
		actor, found := g.stores.Actors.Get(entity)
		position, located := g.stores.Positions.Get(entity)

		if found &&
			located &&
			actor.KindID == kindID &&
			position.LevelID == levelID {
			return entity
		}
	}

	t.Fatalf("seeded D:%d has no %s", levelID, kindID)

	return 0
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
			g, err := NewDungeonGame(1, testCatalog(t), "SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester")

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()
			original := seededPlainBiteMonster(t, g, tc.kindID, tc.levelID)
			health, _ := g.stores.Health.Get(original)
			definition, err := g.catalog.Monster(tc.kindID)

			if err != nil {
				t.Fatal(err)
			}

			wantXP, err := character.OrdinaryAnimalExperience(definition, health.Max)

			if err != nil {
				t.Fatal(err)
			}

			snapshot := g.Snapshot()
			loaded, err := Restore(snapshot, testCatalog(t))

			if err != nil {
				t.Fatal(err)
			}

			defer loaded.Close()

			if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
				t.Fatal("seeded monster changed across save and restore")
			}

			target := seededPlainBiteMonster(t, loaded, tc.kindID, tc.levelID)
			dx, dy := placePlayerBesideMonster(t, loaded, target)
			health, _ = loaded.stores.Health.Get(target)
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

			if progress.TotalXP != wantXP {
				t.Fatalf("%s awarded %d XP, want %d", tc.kindID, progress.TotalXP, wantXP)
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
