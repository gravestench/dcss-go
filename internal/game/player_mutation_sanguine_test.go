package game

import (
	"reflect"
	"strings"
	"testing"
)

func TestSanguineArmourActivatesSavesAndExpires(t *testing.T) {
	g := newStepGame(t)
	moveRatToOtherFloor(t, g)
	baselineAC := g.View().PlayerAC
	mutation, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.mutation"].Set(
		mutation,
		map[string]any{
			"owner":       g.player,
			"mutation_id": "MUT_SANGUINE_ARMOUR",
			"acquired":    int64(1),
		},
	); err != nil {
		t.Fatal(err)
	}

	health, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("player lacks health")
	}

	health.Current = health.Max * 2 / 3

	if got := g.View().PlayerAC; got != baselineAC {
		t.Fatalf("Sanguine Armour activated before a player reaction: AC %d", got)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if got := g.View().PlayerAC; got != baselineAC+6 {
		t.Fatalf("low-HP Sanguine Armour AC = %d, want %d", got, baselineAC+6)
	}

	timerStore := g.scripts.Components()["character.sanguine_armour"]
	timer, found := timerStore.Get(g.player)

	if !found {
		t.Fatal("player lacks Sanguine Armour timer")
	}

	duration, err := timer.Get("remaining_aut")

	if err != nil {
		t.Fatal(err)
	}

	if got := duration.(int64); got < 60 || got > 100 {
		t.Fatalf("Sanguine Armour duration %d outside 60..100", got)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Sanguine Armour changed across restore")
	}

	restoredHealth, found := restored.stores.Health.Get(restored.player)

	if !found {
		t.Fatal("restored player lacks health")
	}

	restoredHealth.Current = restoredHealth.Max

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if got := restored.View().PlayerAC; got != baselineAC+6 {
		t.Fatalf("Sanguine Armour expired before its one-aut grace: AC %d", got)
	}

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if got := restored.View().PlayerAC; got != baselineAC {
		t.Fatalf("Sanguine Armour persisted after healing: AC %d", got)
	}
}

func TestRestoreRejectsInvalidSanguineArmourDuration(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.scripts.Components()["character.sanguine_armour"].Set(
		g.player,
		map[string]any{
			"remaining_aut": int64(101),
		},
	); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if restored != nil {
		restored.Close()
	}

	if err == nil {
		t.Fatal("invalid Sanguine Armour duration was accepted")
	}

	if !strings.Contains(err.Error(), "sanguine armour") {
		t.Fatalf("invalid duration error lacked Sanguine Armour: %v", err)
	}
}
