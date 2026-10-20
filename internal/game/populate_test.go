package game

import (
	"crawl/internal/ecs"
	"crawl/internal/save"
	"github.com/gravestench/akara"
	"reflect"
	"strings"
	"testing"
)

func newPopulatedTestGame(t *testing.T, seed uint64) *Game {
	t.Helper()
	g, err := NewPopulatedScenario(seed, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		_ = g.Close()
	})

	return g
}

func TestPopulationPlacesSupportedMonstersOnFixedDungeon(t *testing.T) {
	g := newPopulatedTestGame(t, 41)

	if g.scenarioID != populationScenarioID {
		t.Fatalf("scenario ID = %q", g.scenarioID)
	}

	if got := len(g.stores.AI.Entities()); got != 4 {
		t.Fatalf("monster count = %d, want 4", got)
	}

	counts := map[int]int{}
	entry := point{
		x: 1,
		y: 1,
	}

	for _, entity := range g.stores.AI.Entities() {
		actor, found := g.stores.Actors.Get(entity)

		if !found {
			t.Fatalf("unsupported populated actor %+v", actor)
		}

		if _, err := testCatalog(t).Monster(actor.KindID); err != nil {
			t.Fatalf("unsupported populated actor %+v: %v", actor, err)
		}

		position, found := g.stores.Positions.Get(entity)

		if !found {
			t.Fatalf("monster %d has no position", entity)
		}

		level := g.levels[position.LevelID]

		if level == nil ||
			fixtureGlyph(level.terrain[position.Y][position.X]) != '.' ||
			max(
				position.X-entry.x,
				entry.x-position.X,
				position.Y-entry.y,
				entry.y-position.Y,
			) < 5 {
			t.Fatalf("monster %d spawned at %+v", entity, position)
		}

		counts[position.LevelID]++
	}

	if counts[1] != populationMonstersPerLevel ||
		counts[2] != populationMonstersPerLevel {
		t.Fatalf("population by level = %+v", counts)
	}

	states := g.rng.States()

	if states["population"] == 0 || states["placement"] == 0 {
		t.Fatalf("population RNG streams were not drawn: %+v", states)
	}
}

func newJackalBandTestGame(t *testing.T) *Game {
	t.Helper()

	var g *Game

	for seed := uint64(1); seed <= 64; seed++ {
		candidate, err := NewPopulatedScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if len(candidate.stores.Followers.Entities()) > 0 {
			g = candidate

			break
		}

		_ = candidate.Close()
	}

	if g == nil {
		t.Fatal("no jackal band appeared in 64 seeded populations")
	}

	t.Cleanup(func() {
		_ = g.Close()
	})

	return g
}

func TestRestoreRejectsInvalidJackalBandState(t *testing.T) {
	g := newJackalBandTestGame(t)

	for _, testCase := range []struct {
		name   string
		change func(*save.Snapshot)
	}{
		{
			name: "self leader",
			change: func(snapshot *save.Snapshot) {
				for index := range snapshot.Entities {
					record := &snapshot.Entities[index]

					if record.BandFollower != nil {
						record.BandFollower.Leader = akara.Entity(record.ID)

						return
					}
				}
			},
		},

		{
			name: "understated initial actors",
			change: func(snapshot *save.Snapshot) {
				for index := range snapshot.Levels {
					snapshot.Levels[index].InitialActors = 1
				}
			},
		},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			snapshot := g.Snapshot()
			testCase.change(&snapshot)

			if _, err := Restore(snapshot); err == nil {
				t.Fatal("accepted invalid jackal band save")
			}
		})
	}
}

func TestPopulationSaveAndTurnContinuation(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	sameSeed := newPopulatedTestGame(t, 41)

	if !reflect.DeepEqual(g.Snapshot(), sameSeed.Snapshot()) {
		t.Fatal("same seed produced different population")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("population or RNG changed across restore")
	}

	for _, run := range []*Game{g, restored} {
		if _, err := run.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("populated games diverged after one turn")
	}
}

func TestRestoreRejectsFixedPopulationSaveWithoutBudgets(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	snapshot := g.Snapshot()

	for index := range snapshot.Levels {
		snapshot.Levels[index].InitialMonsters = 0
		snapshot.Levels[index].InitialActors = 0
	}

	restored, err := Restore(snapshot)

	if err == nil {
		restored.Close()
		t.Fatal("restored fixed population without level budgets")
	}
}

func TestRestoreRejectsOverfullPopulationLevel(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]

		if record.AI == nil ||
			record.Position == nil ||
			record.Position.LevelID != 2 {
			continue
		}

		record.Position = &ecs.Position{
			LevelID: 1,
			X:       12,
			Y:       2,
		}

		break
	}

	if _, err := Restore(snapshot); err == nil ||
		!strings.Contains(err.Error(), "too many live monsters") {
		t.Fatalf("overfull population error = %v", err)
	}
}

func TestRestoreRejectsExperienceWithoutPopulationKill(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]

		if record.Player == nil {
			continue
		}

		record.Progression.TotalXP = 1
		record.SkillTraining.AvailableXP = 10
		break
	}

	if _, err := Restore(snapshot); err == nil ||
		!strings.Contains(err.Error(), "exceeds possible Dungeon kills") {
		t.Fatalf("unearned experience error = %v", err)
	}
}
