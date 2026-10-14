package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func TestSchedulerTieBreak(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()
	actors := ecs.Register(world).Actors
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
	scheduler := TurnScheduler{actors: actors}
	entity, at, ok := scheduler.Next()
	if !ok || entity != first || at != 0 {
		t.Fatalf("next = (%d,%d,%t), want first actor at aut 0", entity, at, ok)
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
