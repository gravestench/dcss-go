package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestAcidCloudAppliesSavedPlayerCorrosion(t *testing.T) {
	g := newZapGame(t)
	position, _ := g.stores.Positions.Get(g.player)
	health, _ := g.stores.Health.Get(g.player)

	health.Current = 1000
	health.Max = 1000

	cloud, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["world.cloud"].Set(cloud,
		map[string]any{
			"kind_id":         "CLOUD_ACID",
			"level_id":        int64(position.LevelID),
			"x":               int64(position.X),
			"y":               int64(position.Y),
			"decay_aut":       int64(1000),
			"source_actor_id": uint64(0),
			"kill_category":   "KC_OTHER",
			"killer_type":     "KILL_MISC",
		}); err != nil {
		t.Fatal(err)
	}

	corrosion := g.scripts.Components()["character.corrosion"]

	for range 20 {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind: ecs.IntentWait,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}

		if corrosion.Has(g.player) {
			state, _ := corrosion.Get(g.player)
			stacks, _ := state.Get("stacks")
			remaining, _ := state.Get("remaining_aut")

			if stacks.(int64) < 1 || remaining.(int64) < 1 {
				t.Fatalf("acid left invalid corrosion: %v", state)
			}

			return
		}
	}

	t.Fatal("acid cloud never corroded the player")
}
