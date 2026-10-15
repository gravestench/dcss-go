package game

import (
	"reflect"
	"testing"
)

func agilityRemaining(t *testing.T, g *Game) int {
	t.Helper()

	store := g.scripts.Components()["character.agility"]
	state, found := store.Get(g.player)

	if !found {
		t.Fatal("player lacks Agility duration")
	}

	value, err := state.Get("remaining_aut")

	if err != nil {
		t.Fatal(err)
	}

	return int(value.(int64))
}

func TestAgilityDurationContinuesThroughTurnAndSave(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	moveRatToOtherFloor(t, g)

	baselineEV := g.View().PlayerEV
	store := g.scripts.Components()["character.agility"]

	if _, err := store.Set(g.player, map[string]any{
		"remaining_aut": int64(350),
	}); err != nil {
		t.Fatal(err)
	}

	if got := g.View().PlayerEV; got != baselineEV+5 {
		t.Fatalf("Agility EV = %d, want %d", got, baselineEV+5)
	}

	first, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	firstRemaining := 350 - int(first.Spent)

	if got := agilityRemaining(t, g); got != firstRemaining {
		t.Fatalf("Agility after turn = %d, want %d", got, firstRemaining)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Agility state changed across restore")
	}

	if got := restored.View().PlayerEV; got != baselineEV+5 {
		t.Fatalf("restored Agility EV = %d, want %d", got, baselineEV+5)
	}

	second, err := restored.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	want := firstRemaining - int(second.Spent)

	if got := agilityRemaining(t, restored); got != want {
		t.Fatalf("restored Agility after turn = %d, want %d", got, want)
	}
}
