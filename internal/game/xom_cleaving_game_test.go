package game

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
)

// Xom's gift remains saved on the player and reaches another adjacent
// hostile through the ordinary player melee command, without another turn.
func TestXomCleavingAttacksSecondHostileAfterRestore(t *testing.T) {
	g := newStepGame(t)
	state := g.scripts.Components()["religion.xom_cleaving"]

	if _, err := state.Set(g.player, map[string]any{
		"remaining_aut": int64(100),
	}); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	level := restored.levels[1]
	worm := spawnWormForTest(t, restored, 1)

	if err := level.MoveActor(restored.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	if err := level.MoveActor(worm, 3, 2); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.stores.Health.Set(worm, ecs.Health{
		Current: 1000,
		Max:     1000,
	}); err != nil {
		t.Fatal(err)
	}

	result, err := restored.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("primary melee was not attempted")
	}

	var cleaved bool

	for _, event := range result.Events {
		if strings.Contains(event.Text, "worm") {
			cleaved = true
			break
		}
	}

	if !cleaved {
		t.Fatalf("adjacent worm was not cleaved: %+v", result.Events)
	}

	if !restored.scripts.Components()["religion.xom_cleaving"].Has(
		restored.player,
	) {
		t.Fatal("cleaving expired before its remaining duration")
	}
}
