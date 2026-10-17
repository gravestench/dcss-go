package game

import (
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestIcyDefenseMeltsInFireCloudAndRestoresAfterSave(t *testing.T) {
	g := newZapGame(t)
	baseline := g.View()
	mutationStore := g.scripts.Components()["character.mutation"]

	for _, record := range []struct {
		id    string
		level int64
	}{
		{
			id:    "MUT_ICEMAIL",
			level: 2,
		},

		{
			id:    "MUT_CONDENSATION_SHIELD",
			level: 1,
		},
	} {
		entity, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		if _, err := mutationStore.Set(entity, map[string]any{
			"owner":       g.player,
			"mutation_id": record.id,
			"acquired":    record.level,
		}); err != nil {
			t.Fatal(err)
		}
	}

	protected := g.View()

	if protected.PlayerAC != baseline.PlayerAC+8 ||
		protected.PlayerSH != baseline.PlayerSH+4 {
		t.Fatalf("icy defense bonuses AC %d SH %d, baseline AC %d SH %d",
			protected.PlayerAC, protected.PlayerSH,
			baseline.PlayerAC, baseline.PlayerSH)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player lacks position")
	}

	health, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("player lacks health")
	}

	originalMaxHP := health.Max

	health.Current = 100
	health.Max = 100

	cloud, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["world.cloud"].Set(cloud, map[string]any{
		"kind_id":         "CLOUD_FIRE",
		"source_actor_id": uint64(g.player),
		"kill_category":   "KC_YOU",
		"killer_type":     "KILL_YOU_MISSILE",
		"level_id":        int64(position.LevelID),
		"x":               int64(position.X),
		"y":               int64(position.Y),
		"decay_aut":       int64(1000),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	health.Max = originalMaxHP
	health.Current = min(health.Current, originalMaxHP)

	depleted := g.View()

	if depleted.PlayerAC != baseline.PlayerAC ||
		depleted.PlayerSH != baseline.PlayerSH {
		t.Fatalf("fire cloud left icy defenses active: AC %d SH %d",
			depleted.PlayerAC, depleted.PlayerSH)
	}

	timerStore := g.scripts.Components()["character.icy_defense"]
	state, found := timerStore.Get(g.player)

	if !found {
		t.Fatal("player lacks icy defense timer")
	}

	value, err := state.Get("remaining_aut")

	if err != nil {
		t.Fatal(err)
	}

	remaining := value.(int64)

	if remaining <= 0 || remaining > 300 {
		t.Fatalf("icy defense timer = %d, want positive at most 300", remaining)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("icy defense state changed across restore")
	}

	restored.turn.Actor = restored.player
	updateLuaSystem(t, restored, "status.icy_defense", time.Duration(remaining))

	recovered := restored.View()

	if recovered.PlayerAC != protected.PlayerAC ||
		recovered.PlayerSH != protected.PlayerSH {
		t.Fatalf("icy defenses did not recover: AC %d SH %d",
			recovered.PlayerAC, recovered.PlayerSH)
	}
}

func TestRestoreRejectsInvalidIcyDefenseDuration(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.scripts.Components()["character.icy_defense"].Set(
		g.player,
		map[string]any{
			"remaining_aut": int64(301),
		},
	); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if restored != nil {
		restored.Close()
	}

	if err == nil {
		t.Fatal("invalid icy defense duration was accepted")
	}

	if !strings.Contains(err.Error(), "icy defense") {
		t.Fatalf("invalid icy defense duration was accepted: %v", err)
	}
}
