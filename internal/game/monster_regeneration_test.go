package game

import (
	"crawl/internal/ecs"
	"testing"
)

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

func TestRestoreRejectsZeroHPWorm(t *testing.T) {
	g, err := NewDungeonGame(1, "SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	// Generated D:2 is lazy; create it before the save fixture adds its worm.
	descendGeneratedTo(t, g, 2)
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

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("accepted a dead worm as a live saved actor")
	}
}
