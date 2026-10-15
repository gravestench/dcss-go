package game

import (
	"reflect"
	"strings"
	"testing"
)

func TestRestoreRejectsInvalidDecomposedStatLoss(t *testing.T) {
	g := newStepGame(t)

	statLoss := g.scripts.Components()["character.stat_loss"]

	if _, err := statLoss.Set(g.player, map[string]any{
		"strength":     int64(-1),
		"remaining_xp": int64(30),
	}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if loaded != nil {
		loaded.Close()
	}

	if err == nil {
		t.Fatal("invalid stat loss was accepted")
	}

	if !strings.Contains(err.Error(), "stat loss") {
		t.Fatalf("invalid stat loss was accepted: %v", err)
	}
}

func TestDecomposedStatLossRecoversFromKillExperienceAfterRestore(t *testing.T) {
	g := newStepGame(t)

	statLoss := g.scripts.Components()["character.stat_loss"]

	if _, err := statLoss.Set(g.player, map[string]any{
		"strength":     int64(1),
		"remaining_xp": int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("stat loss changed across restore")
	}

	for _, current := range []*Game{g, restored} {
		rat := ratID(t, current)

		if err := current.levels[1].MoveActor(current.player, 3, 1); err != nil {
			t.Fatal(err)
		}

		health, _ := current.stores.Health.Get(rat)

		health.Current = 1

		playerHealth, _ := current.stores.Health.Get(current.player)

		playerHealth.Current = 100
		playerHealth.Max = 100

		for attempt := 0; attempt < 100; attempt++ {
			if !current.world.EntityExists(rat) {
				break
			}

			if _, err := current.Step(Command{
				Kind: CommandMove,
				DX:   1,
			}); err != nil {
				t.Fatal(err)
			}
		}

		if current.world.EntityExists(rat) {
			t.Fatal("rat survived stat recovery fixture")
		}

		loss, found := current.scripts.Components()["character.stat_loss"].Get(current.player)

		if !found {
			t.Fatal("saved stat loss component disappeared")
		}

		strength, err := loss.Get("strength")

		if err != nil {
			t.Fatal(err)
		}

		if strength != int64(0) {
			t.Fatalf("strength loss after kill = %v", strength)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("stat recovery diverged after restore")
	}
}
