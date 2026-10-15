package game

import (
	"reflect"
	"testing"
)

func TestTemporaryMutationWanesOnKillExperienceAndSurvivesSave(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	mutation, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	mutationStore := g.scripts.Components()["character.mutation"]

	if _, err := mutationStore.Set(mutation, map[string]any{
		"owner":       g.player,
		"mutation_id": "MUT_FAST",
		"temporary":   int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	timerStore := g.scripts.Components()["character.mutation_timer"]

	if _, err := timerStore.Set(g.player, map[string]any{
		"remaining_xp": int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("temporary mutation changed on restore")
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	if err := restored.levels[1].MoveActor(restored.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for _, game := range []*Game{g, restored} {
		currentRat := rat

		if game == restored {
			currentRat = ratID(t, restored)
		}

		health, _ := game.stores.Health.Get(currentRat)

		health.Current = 1

		playerHealth, _ := game.stores.Health.Get(game.player)

		playerHealth.Current = 100
		playerHealth.Max = 100

		for attempt := 0; attempt < 100; attempt++ {
			if !game.world.EntityExists(currentRat) {
				break
			}

			if _, err := game.Step(Command{
				Kind: CommandMove,
				DX:   1,
			}); err != nil {
				t.Fatal(err)
			}
		}

		if game.world.EntityExists(currentRat) {
			t.Fatal("rat survived temporary mutation XP fixture")
		}

		if _, found := mutationStore.Get(mutation); found && game == g {
			t.Fatal("temporary mutation survived its XP threshold")
		}

		timer, found := game.scripts.Components()["character.mutation_timer"].Get(game.player)

		if !found {
			t.Fatal("shared temporary mutation timer disappeared")
		}

		remaining, err := timer.Get("remaining_xp")

		if err != nil {
			t.Fatal(err)
		}

		if remaining != int64(0) {
			t.Fatalf("temporary mutation timer = %v", remaining)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("temporary mutation continuation diverged after restore")
	}

}
