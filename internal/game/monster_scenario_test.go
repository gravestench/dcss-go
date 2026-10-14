package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/monster"
)

func TestRatScenarioRollsSourceHPAndKeepsCatalogedBite(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	health, ok := g.stores.Health.Get(rat)
	expected := NewRNGStreams(g.seed)
	want, err := monster.RollHP(expected, 25)
	if err != nil {
		t.Fatal(err)
	}

	if _, err := monster.RollHP(expected, 55); err != nil {
		t.Fatal(err)
	}

	if _, err := monster.RollHP(expected, 20); err != nil {
		t.Fatal(err)
	}

	if !ok || health.Current != want || health.Max != want || !reflect.DeepEqual(expected.States(), g.rng.States()) {
		t.Fatalf("rat health = %+v, found %v", health, ok)
	}

	combat, ok := g.stores.Combat.Get(rat)
	definition, err := g.catalog.Monster("MONS_RAT")
	if !ok || combat.ShieldBlocks != 0 || err != nil || definition.HD != 1 ||
		definition.AverageHP10x != 25 || definition.Attacks[0].Damage != 3 {
		t.Fatalf("rat combat/source = %+v/%+v, found %v, error %v", combat, definition, ok, err)
	}
}

func TestRatRolledHPSurvivesSaveWithoutReroll(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	loaded, err := Restore(before, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("loading rerolled the rat or monster HP stream")
	}

	for i := range before.Entities {
		if before.Entities[i].Actor != nil && before.Entities[i].Actor.KindID == "MONS_RAT" {
			before.Entities[i].Health.Max = 4
			before.Entities[i].Health.Current = 4
		}
	}

	legacy, err := Restore(before, testCatalog(t))
	if err != nil {
		t.Fatalf("old 4-HP rat save rejected: %v", err)
	}

	legacy.Close()
}

func TestRatRestoreRejectsImpossibleMaxHP(t *testing.T) {
	g := newStepGame(t)
	for _, hp := range []int{0, 5} {
		bad := g.Snapshot()
		for i := range bad.Entities {
			if bad.Entities[i].AI != nil {
				bad.Entities[i].Health.Max = hp
				bad.Entities[i].Health.Current = max(0, hp)
			}
		}

		if loaded, err := Restore(bad, testCatalog(t)); err == nil {
			loaded.Close()
			t.Fatalf("impossible rat max HP %d accepted", hp)
		}
	}
}
