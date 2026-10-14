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
	actors := stores.Actors
	first, _ := world.CreateEntity()
	second, _ := world.CreateEntity()
	actors.Set(first, ecs.Actor{
		Speed:   10,
		NextAut: 0,
	})

	actors.Set(second, ecs.Actor{
		Speed:   10,
		NextAut: 0,
	})

	stores.Positions.Set(first, ecs.Position{LevelID: 1})
	stores.Positions.Set(second, ecs.Position{LevelID: 1})
	scheduler := TurnScheduler{
		actors:    actors,
		positions: stores.Positions,
	}

	entity, at, ok := scheduler.Next(1)

	if !ok || entity != first || at != 0 {
		t.Fatalf("next = (%d,%d,%t), want first actor at aut 0", entity, at, ok)
	}
}

func TestSchedulerSelectsOnlyCurrentFloor(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()
	stores := ecs.Register(world)
	active, _ := world.CreateEntity()
	inactive, _ := world.CreateEntity()
	stores.Actors.Set(active, ecs.Actor{
		Speed:   10,
		NextAut: 20,
	})

	stores.Actors.Set(inactive, ecs.Actor{
		Speed:   10,
		NextAut: 0,
	})

	stores.Positions.Set(active, ecs.Position{LevelID: 1})
	stores.Positions.Set(inactive, ecs.Position{LevelID: 2})
	scheduler := TurnScheduler{
		actors:    stores.Actors,
		positions: stores.Positions,
	}

	entity, at, found := scheduler.Next(1)

	if !found || entity != active || at != 20 {
		t.Fatalf("active floor actor = (%d, %d, %t), want %d at aut 20", entity, at, found, active)
	}
}

func TestScheduleAfter(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()
	actors := ecs.Register(world).Actors
	entity, _ := world.CreateEntity()
	actors.Set(entity, ecs.Actor{Speed: 10})
	scheduler := TurnScheduler{actors: actors}

	if err := scheduler.ScheduleAfter(entity, 10); err != nil {
		t.Fatal(err)
	}

	actor, _ := actors.Get(entity)

	if actor.NextAut != 10 {
		t.Fatalf("next aut = %d, want 10", actor.NextAut)
	}

	actor.Speed = 20

	if err := scheduler.ScheduleAfter(entity, 10); err != nil {
		t.Fatal(err)
	}

	if actor.NextAut != 15 {
		t.Fatalf("fast actor next aut = %d, want 15", actor.NextAut)
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

		if err != nil || got != want {
			t.Fatalf("stream %q after restore = %d, %v; want %d", name, got, err, want)
		}
	}

	if _, err := restored.Intn("combat", 0); err == nil {
		t.Fatal("accepted zero upper bound")
	}
}
