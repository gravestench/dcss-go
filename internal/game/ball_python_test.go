package game

import (
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
	"reflect"
	"testing"
)

func newBallPythonGame(t *testing.T) (*Game, akara.Entity) {
	return newBallPythonGameForSpecies(t, "SP_HUMAN")
}

func newBallPythonGameForSpecies(
	t *testing.T,
	speciesID string,
) (*Game, akara.Entity) {
	t.Helper()
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGame(
		1,
		catalog,
		speciesID,
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

		if found && actor.KindID == "MONS_BALL_PYTHON" {
			return g, entity
		}
	}

	t.Fatal("seeded generated Dungeon has no ball python")

	return nil, 0
}

func TestGeneratedBallPythonSpawnsFromSourcePopulation(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	actor, _ := g.stores.Actors.Get(pythonID)
	health, _ := g.stores.Health.Get(pythonID)

	if actor.Speed != 12 ||
		health.Max < 2 ||
		health.Max > 5 {
		t.Fatalf("ball python actor %+v, health %+v", actor, health)
	}
}

func TestBallPythonDeathAwardsSourceXP(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	dx, dy := placePlayerBesideMonster(t, g, pythonID)
	health, _ := g.stores.Health.Get(pythonID)
	definition, _ := g.catalog.Monster("MONS_BALL_PYTHON")

	if !definition.LeavesCorpse {
		t.Fatal("source ball python is not corpse eligible")
	}

	health.Current = 1

	for attempt := 0; attempt < 100 && g.world.EntityExists(pythonID); attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind: ecs.IntentMelee,
			DX:   dx,
			DY:   dy,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}
	}

	if g.world.EntityExists(pythonID) {
		t.Fatal("ball python survived 100 melee attacks")
	}

	progress, _ := g.stores.Progression.Get(g.player)

	if progress.TotalXP <= 0 {
		t.Fatalf("ball python awarded %d XP", progress.TotalXP)
	}

	for _, entity := range g.stores.Corpses.Entities() {
		corpse, _ := g.stores.Corpses.Get(entity)

		if corpse.MonsterID != "MONS_BALL_PYTHON" {
			t.Fatalf("ball python death left corpse %+v", corpse)
		}
	}
}

func TestConstrictedPlayerLosesThreeEVAndShowsStatus(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)
	before := g.View()

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By: pythonID,
	}); err != nil {
		t.Fatal(err)
	}

	after := g.View()

	if after.PlayerEV != before.PlayerEV-3 || !after.Constricted {
		t.Fatalf("constricted EV %d -> %d, view %+v", before.PlayerEV, after.PlayerEV, after)
	}
}

func TestConstrictedPlayerSaveRoundTrip(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By:             pythonID,
		EscapeAttempts: 2,
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot, g.catalog)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		loaded.Close()
	})

	grip, found := loaded.stores.Constricted.Get(loaded.player)

	if !found ||
		grip.By != pythonID ||
		grip.EscapeAttempts != 2 {
		t.Fatalf("restored grip %+v, found %v", grip, found)
	}

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("constricted player save changed on restore")
	}
}

func TestRestoreRejectsNegativePythonEnergy(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]

		if record.ID == uint64(pythonID) {
			record.MonsterEnergy.Points = -1

			break
		}
	}

	if loaded, err := Restore(snapshot, g.catalog); err == nil {
		loaded.Close()
		t.Fatal("restored impossible negative python energy")
	}
}

func TestRestoreRejectsInvalidBallPythonGripLinks(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By: pythonID,
	}); err != nil {
		t.Fatal(err)
	}

	for _, name := range []string{
		"missing constrictor",
		"self constrictor",
		"negative attempts",
		"excessive attempts",
	} {
		t.Run(name, func(t *testing.T) {
			snapshot := g.Snapshot()

			for index := range snapshot.Entities {
				record := &snapshot.Entities[index]

				if record.ID != uint64(g.player) {
					continue
				}

				switch name {
				case "missing constrictor":
					record.Constricted.By = akara.Entity(999999)

				case "self constrictor":
					record.Constricted.By = g.player

				case "negative attempts":
					record.Constricted.EscapeAttempts = -1

				case "excessive attempts":
					record.Constricted.EscapeAttempts = 1001
				}
			}

			if loaded, err := Restore(snapshot, g.catalog); err == nil {
				loaded.Close()
				t.Fatal("restored invalid constriction link")
			}
		})
	}
}

func freeAdjacentPlayerMove(t *testing.T, g *Game) (int, int) {
	t.Helper()
	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]

	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue
			}

			x, y := position.X+dx, position.Y+dy

			if !level.Walkable(x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); !occupied {
				return dx, dy
			}
		}
	}

	t.Fatal("constricted player has no free adjacent tile")

	return 0, 0
}
