package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func TestSchedulerTieBreak(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()
	stores := ecs.Register(world)

	first, _ := world.CreateEntity()
	second, _ := world.CreateEntity()
	stores.MonsterEnergy.Set(first, ecs.MonsterEnergy{Points: 80})
	stores.MonsterEnergy.Set(second, ecs.MonsterEnergy{Points: 80})
	stores.Positions.Set(first, ecs.Position{LevelID: 1})
	stores.Positions.Set(second, ecs.Position{LevelID: 1})
	scheduler := TurnScheduler{
		positions: stores.Positions,
		energies:  stores.MonsterEnergy,
	}

	entity, ok := scheduler.NextReady(1)

	if !ok || entity != first {
		t.Fatalf("next = (%d,%t), want first actor", entity, ok)
	}
}

func TestSchedulerSelectsOnlyCurrentFloor(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()
	stores := ecs.Register(world)

	active, _ := world.CreateEntity()
	inactive, _ := world.CreateEntity()
	stores.MonsterEnergy.Set(active, ecs.MonsterEnergy{Points: 80})
	stores.MonsterEnergy.Set(inactive, ecs.MonsterEnergy{Points: 100})
	stores.Positions.Set(active, ecs.Position{LevelID: 1})
	stores.Positions.Set(inactive, ecs.Position{LevelID: 2})
	scheduler := TurnScheduler{
		positions: stores.Positions,
		energies:  stores.MonsterEnergy,
	}

	entity, found := scheduler.NextReady(1)

	if !found || entity != active {
		t.Fatalf("active floor actor = (%d, %t), want %d", entity, found, active)
	}
}

func TestRNGRestore(t *testing.T) {
	original := NewRNGStreams(42)

	if _, err := original.Intn("combat", 100); err != nil {
		t.Fatal(err)
	}

	restored := RestoreRNGStreams(42, original.States())

	for _, name := range []string{"combat", "world"} {
		want, err := original.Intn(name, 100)

		if err != nil {
			t.Fatal(err)
		}

		got, err := restored.Intn(name, 100)

		if err != nil ||
			got != want {
			t.Fatalf("stream %q after restore = %d, %v; want %d", name, got, err, want)
		}
	}

	if _, err := restored.Intn("combat", 0); err == nil {
		t.Fatal("accepted zero upper bound")
	}
}
