package game

import (
	"reflect"
	"strings"
	"testing"
)

// A real player command must run the Lua opportunity policy before changing
// position. Restoring the same pre-move state must replay its chance and
// attack identically, including monster energy and emitted combat messages.
func TestLeavingReachCanTriggerOpportunityAttack(t *testing.T) {
	for seed := uint64(1); seed <= 32; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			g.Close()
			t.Fatal(err)
		}

		if err := g.refreshVisibility(); err != nil {
			g.Close()
			t.Fatal(err)
		}

		restored, err := Restore(g.Snapshot())

		if err != nil {
			g.Close()
			t.Fatal(err)
		}

		command := Command{
			Kind: CommandMove,
			DX:   -1,
		}

		first, firstErr := g.Step(command)
		second, secondErr := restored.Step(command)

		if firstErr != nil {
			g.Close()
			restored.Close()
			t.Fatalf("seed %d opportunity step: %v", seed, firstErr)
		}

		if secondErr != nil {
			g.Close()
			restored.Close()
			t.Fatalf("seed %d restored opportunity step: %v", seed, secondErr)
		}

		if !reflect.DeepEqual(first, second) {
			viewType := reflect.TypeOf(first.View)
			viewFirst := reflect.ValueOf(first.View)
			viewSecond := reflect.ValueOf(second.View)
			different := make([]string, 0)

			for index := 0; index < viewType.NumField(); index++ {
				if !reflect.DeepEqual(viewFirst.Field(index).Interface(),
					viewSecond.Field(index).Interface()) {
					different = append(different, viewType.Field(index).Name)
				}
			}

			g.Close()
			restored.Close()
			t.Fatalf("seed %d opportunity view differs: %v", seed, different)
		}

		if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
			g.Close()
			restored.Close()
			t.Fatalf("seed %d opportunity save state differs after replay", seed)
		}

		struck := false

		for _, event := range first.Events {
			struck = struck || strings.Contains(event.Text,
				"attacks as you move away!")
		}

		if struck {
			position, found := g.stores.Positions.Get(g.player)

			if !found ||
				position.X != 2 ||
				position.Y != 1 {
				g.Close()
				restored.Close()
				t.Fatalf("opportunity strike changed legal move: %+v", position)
			}
		}

		g.Close()
		restored.Close()

		if struck {
			return
		}
	}

	t.Fatal("no seeded departure from the rat provoked an opportunity attack")
}
