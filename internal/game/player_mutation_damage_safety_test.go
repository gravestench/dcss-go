package game

import (
	"reflect"
	"testing"
)

func safetyDurations(t *testing.T, g *Game) (int64, int64) {
	t.Helper()

	store := g.scripts.Components()["character.damage_safety"]
	state, found := store.Get(g.player)

	if !found {
		t.Fatal("player lacks damage safety durations")
	}

	potions, err := state.Get("no_potions_aut")

	if err != nil {
		t.Fatal(err)
	}

	scrolls, err := state.Get("no_scrolls_aut")

	if err != nil {
		t.Fatal(err)
	}

	return potions.(int64), scrolls.(int64)
}

func TestDamageSafetyDurationsContinueThroughTurnAndSave(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	moveRatToOtherFloor(t, g)

	store := g.scripts.Components()["character.damage_safety"]

	if _, err := store.Set(g.player, map[string]any{
		"no_potions_aut": int64(20),
		"no_scrolls_aut": int64(30),
	}); err != nil {
		t.Fatal(err)
	}

	first, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	wantPotions := int64(20 - first.Spent)
	wantScrolls := int64(30 - first.Spent)
	potions, scrolls := safetyDurations(t, g)

	if potions != wantPotions || scrolls != wantScrolls {
		t.Fatalf("damage safety after turn = %d/%d, want %d/%d",
			potions, scrolls, wantPotions, wantScrolls)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("damage safety state changed across restore")
	}

	second, err := restored.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	potions, scrolls = safetyDurations(t, restored)
	wantPotions = max(0, wantPotions-int64(second.Spent))
	wantScrolls = max(0, wantScrolls-int64(second.Spent))

	if potions != wantPotions || scrolls != wantScrolls {
		t.Fatalf("restored damage safety = %d/%d, want %d/%d",
			potions, scrolls, wantPotions, wantScrolls)
	}
}
