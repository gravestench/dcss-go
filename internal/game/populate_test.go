package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
	"dcrawl-go/internal/visibility"
	"github.com/gravestench/akara"
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

func TestEarlyDungeonPopulationPoolIncludesPlainBiteKinds(t *testing.T) {
	catalog := testCatalog(t)

	for _, depth := range []int{1, 2} {
		pool := catalog.DungeonMonsterPool(depth, func(id string) bool {
			return !isOrdinaryAnimal(id)
		})

		seen := make(map[string]bool)

		for roll := range pool.TotalWeight() {
			id, err := pool.Pick(roll)

			if err != nil {
				t.Fatal(err)
			}

			seen[id] = true
		}

		if !seen["MONS_GIANT_COCKROACH"] {
			t.Fatalf("D:%d excludes giant cockroach", depth)
		}

		if seen["MONS_WORM"] != (depth == 2) {
			t.Fatalf("D:%d worm eligibility = %v", depth, seen["MONS_WORM"])
		}

		if !seen["MONS_JACKAL"] {
			t.Fatalf("D:%d excludes jackal", depth)
		}
	}
}

func TestJackalPopulationCreatesAndSavesBands(t *testing.T) {
	g := newJackalBandTestGame(t)

	followersByLeader := make(map[akara.Entity]int)

	for _, entity := range g.stores.Followers.Entities() {
		follower, _ := g.stores.Followers.Get(entity)
		actor, _ := g.stores.Actors.Get(entity)
		position, _ := g.stores.Positions.Get(entity)

		leader, _ := g.stores.Positions.Get(follower.Leader)
		level := g.levels[position.LevelID]

		if actor.KindID != "MONS_JACKAL" || leader == nil ||
			leader.LevelID != position.LevelID ||
			chebyshevDistance(position.X, position.Y, leader.X, leader.Y) > 3 {
			t.Fatalf("invalid jackal follower %d at %+v with leader %+v", entity, position, leader)
		}

		visible, err := visibility.Compute(level.terrain, leader.X, leader.Y, 7)

		if err != nil {
			t.Fatal(err)
		}

		if !visible[position.Y*level.width+position.X] {
			t.Fatalf("jackal follower %d spawned outside leader sight", entity)
		}

		followersByLeader[follower.Leader]++
	}

	for leader, count := range followersByLeader {
		if count < 1 || count > 3 {
			t.Fatalf("jackal leader %d has %d followers", leader, count)
		}
	}

	for _, level := range g.levels {
		if level.initialActors < level.initialMonsters {
			t.Fatalf("level %d lost population actors", level.ID)
		}
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("jackal bands changed across save and restore")
	}

	followerEntity := g.stores.Followers.Entities()[0]
	follower, _ := g.stores.Followers.Get(followerEntity)
	position, _ := g.stores.Positions.Get(followerEntity)
	leaderPosition, _ := g.stores.Positions.Get(follower.Leader)

	level := g.levels[position.LevelID]
	visible, err := visibility.Compute(level.terrain, position.X, position.Y, 7)

	if err != nil {
		t.Fatal(err)
	}

	ai, _ := g.stores.AI.Get(followerEntity)
	decision := newMonsterDecisionSystem(g)

	if err := decision.chooseWanderTarget(
		followerEntity,
		ai,
		level,
		position.X,
		position.Y,
		visible,
	); err != nil {
		t.Fatal(err)
	}

	if chebyshevDistance(ai.TargetX, ai.TargetY, leaderPosition.X, leaderPosition.Y) >= 6 {
		t.Fatalf("jackal wandered away from leader: %+v", ai)
	}

	if err := level.RemoveActor(follower.Leader); err != nil {
		t.Fatal(err)
	}

	if !g.world.DestroyEntity(follower.Leader) {
		t.Fatal("failed to remove jackal leader")
	}

	if _, found := decision.bandLeaderPosition(followerEntity, level.ID); found {
		t.Fatal("follower still tracks a dead leader")
	}

	afterLoss, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer afterLoss.Close()
}

func newJackalBandTestGame(t *testing.T) *Game {
	t.Helper()

	var g *Game

	for seed := uint64(1); seed <= 64; seed++ {
		candidate, err := NewPopulatedScenario(seed, testCatalog(t), "WPN_RAPIER", "Tester")

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

			if _, err := Restore(snapshot, testCatalog(t)); err == nil {
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

func TestOlderFixedPopulationSaveWithoutBudgetsStillLoads(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	snapshot := g.Snapshot()

	for index := range snapshot.Levels {
		snapshot.Levels[index].InitialMonsters = 0
		snapshot.Levels[index].InitialActors = 0
	}

	restored, err := Restore(snapshot, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
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
		record.SkillTraining.AvailableXP = 10
		break
	}

	if _, err := Restore(snapshot, testCatalog(t)); err == nil ||
		!strings.Contains(err.Error(), "exceeds possible Dungeon kills") {
		t.Fatalf("unearned experience error = %v", err)
	}
}
