package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

func newPopulatedTestGame(t *testing.T, seed uint64) *Game {
	t.Helper()
	g, err := NewPopulatedScenario(seed, testCatalog(t), "WPN_RAPIER", "Tester")
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
		if !found || !isOrdinaryAnimal(actor.KindID) {
			t.Fatalf("unsupported populated actor %+v", actor)
		}

		position, found := g.stores.Positions.Get(entity)
		if !found {
			t.Fatalf("monster %d has no position", entity)
		}

		level := g.levels[position.LevelID]
		if level == nil || level.terrain[position.Y][position.X] != '.' ||
			!farEnoughFromEntry(position.X, position.Y, entry, spawnDistanceFromEntry) {
			t.Fatalf("monster %d spawned at %+v", entity, position)
		}

		counts[position.LevelID]++
	}

	if counts[1] != populationMonstersPerLevel || counts[2] != populationMonstersPerLevel {
		t.Fatalf("population by level = %+v", counts)
	}

	states := g.rng.States()
	if states["population"] == 0 || states["placement"] == 0 {
		t.Fatalf("population RNG streams were not drawn: %+v", states)
	}
}

func TestPopulationSaveAndTurnContinuation(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	sameSeed := newPopulatedTestGame(t, 41)
	if !reflect.DeepEqual(g.Snapshot(), sameSeed.Snapshot()) {
		t.Fatal("same seed produced different population")
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))
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

func TestRestoreRejectsOverfullPopulationLevel(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	snapshot := g.Snapshot()
	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]
		if record.AI == nil || record.Position == nil || record.Position.LevelID != 2 {
			continue
		}

		record.Position = &ecs.Position{
			LevelID: 1,
			X:       12,
			Y:       2,
		}
		break
	}

	if _, err := Restore(snapshot, testCatalog(t)); err == nil ||
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
		break
	}

	if _, err := Restore(snapshot, testCatalog(t)); err == nil ||
		!strings.Contains(err.Error(), "exceeds possible Dungeon kills") {
		t.Fatalf("unearned experience error = %v", err)
	}
}
