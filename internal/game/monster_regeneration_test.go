package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestWormRegeneratesBeforeItsActionWithoutRandomDraw(t *testing.T) {
	g := newStepGame(t)
	cells := g.levels[1].spawnCellsAwayFrom(point{
		x: 1,
		y: 1,
	}, 5)

	if len(cells) == 0 {
		t.Fatal("fixture has no worm spawn cell")
	}

	cell := cells[0]
	worm, err := newOrdinaryMonsterFactory(g).Spawn(
		"MONS_WORM", 1, cell.x, cell.y,
	)

	if err != nil {
		t.Fatal(err)
	}

	health, found := g.stores.Health.Get(worm)

	if !found {
		t.Fatal("worm has no health")
	}

	health.Current = health.Max - 2

	before := g.rng.States()["monster_regen"]

	if _, err := g.runAction(worm, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if health.Current != health.Max-1 {
		t.Fatalf("worm HP after action = %d, want %d", health.Current, health.Max-1)
	}

	if g.rng.States()["monster_regen"] != before {
		t.Fatal("fast regeneration consumed a random draw")
	}
}

func TestInjuredRatUsesNaturalRegenerationRollOnItsTurn(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	health, found := g.stores.Health.Get(rat)

	if !found {
		t.Fatal("rat has no health")
	}

	health.Current = health.Max - 1

	expectedRNG := RestoreRNGStreams(g.seed, g.rng.States())
	roll, err := expectedRNG.Intn("monster_regen", 25)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.runAction(rat, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	wantHP := health.Max - 1

	if roll == 0 {
		wantHP++
	}

	if health.Current != wantHP {
		t.Fatalf("rat HP after regeneration = %d, want %d", health.Current, wantHP)
	}

	if g.rng.States()["monster_regen"] != expectedRNG.States()["monster_regen"] {
		t.Fatal("rat consumed the wrong natural regeneration draw")
	}

	health.Current = health.Max

	before := g.rng.States()["monster_regen"]

	if _, err := g.runAction(rat, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.rng.States()["monster_regen"] != before {
		t.Fatal("healthy rat consumed a regeneration draw")
	}
}

func TestInjuredAdderUsesNaturalRegenerationOnItsTurn(t *testing.T) {
	g := newStepGame(t)
	cells := g.levels[1].spawnCellsAwayFrom(point{
		x: 1,
		y: 1,
	}, 5)

	if len(cells) == 0 {
		t.Fatal("fixture has no adder spawn cell")
	}

	cell := cells[0]
	adder, err := newOrdinaryMonsterFactory(g).Spawn(
		"MONS_ADDER", 1, cell.x, cell.y,
	)

	if err != nil {
		t.Fatal(err)
	}

	health, found := g.stores.Health.Get(adder)

	if !found {
		t.Fatal("adder has no health")
	}

	health.Current = health.Max - 1

	expectedRNG := RestoreRNGStreams(g.seed, g.rng.States())
	roll, err := expectedRNG.Intn("monster_regen", 25)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.runAction(adder, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	wantHP := health.Max - 1

	if roll == 0 {
		wantHP++
	}

	if health.Current != wantHP {
		t.Fatalf("adder HP after regeneration = %d, want %d", health.Current, wantHP)
	}

	if g.rng.States()["monster_regen"] != expectedRNG.States()["monster_regen"] {
		t.Fatal("adder consumed the wrong natural regeneration draw")
	}
}

func TestRestoreRejectsZeroHPWorm(t *testing.T) {
	g, err := NewDungeonGame(1, testCatalog(t), "SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	spawnWormForTest(t, g, 2)

	snapshot := g.Snapshot()
	found := false

	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]

		if record.Actor == nil || record.Actor.KindID != "MONS_WORM" {
			continue
		}

		record.Health.Current = 0
		found = true
		break
	}

	if !found {
		t.Fatal("seed 1 has no worm")
	}

	if _, err := Restore(snapshot, testCatalog(t)); err == nil {
		t.Fatal("accepted a dead worm as a live saved actor")
	}
}
