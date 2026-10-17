package game

import "testing"

func TestCloudFieldAgesOncePerSpentPlayerAction(t *testing.T) {
	g := newStepGame(t)
	cloud, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.cloud"]

	if _, err := store.Set(cloud, map[string]any{
		"kind_id":         "CLOUD_DUST",
		"level_id":        int64(1),
		"x":               int64(2),
		"y":               int64(1),
		"decay_aut":       int64(100),
		"spread_rate":     int64(0),
		"source_actor_id": uint64(0),
		"kill_category":   "KC_OTHER",
		"killer_type":     "KILL_MISC",
		"opaque":          false,
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	state, found := store.Get(cloud)

	if !found {
		t.Fatal("cloud expired before its duration")
	}

	remaining, _ := state.Get("decay_aut")

	if remaining != int64(100-result.Spent) {
		t.Fatalf("remaining cloud AUT = %v, want %d",
			remaining, 100-result.Spent)
	}
}
