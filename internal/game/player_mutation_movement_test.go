package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestFastAndSlowMutationsChangeMoveTiming(t *testing.T) {
	for _, vector := range []struct {
		id   string
		want int64
	}{
		{
			id:   "MUT_FAST",
			want: 8,
		},

		{
			id:   "MUT_SLOW",
			want: 12,
		},
	} {
		t.Run(vector.id, func(t *testing.T) {
			g := newStepGame(t)
			entity, err := g.world.CreateEntity()

			if err != nil {
				t.Fatal(err)
			}

			store := g.scripts.Components()["character.mutation"]

			if _, err := store.Set(entity, map[string]any{
				"owner":       g.player,
				"mutation_id": vector.id,
				"acquired":    int64(1),
			}); err != nil {
				t.Fatal(err)
			}

			decision, err := g.scripts.Policy("command.timing", map[string]any{
				"attack_target": false,
				"intent_kind":   int(ecs.IntentMove),
				"item_id":       uint64(0),
			})

			if err != nil {
				t.Fatal(err)
			}

			if got := decision["cost"].(int64); got != vector.want {
				t.Fatalf("move cost = %d, want %d", got, vector.want)
			}
		})
	}
}
