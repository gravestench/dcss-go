package game

import (
	"reflect"
	"testing"
)

// Free commands leave Xom idle. A completed player wait runs his source
// reaction and saves the resulting religion RNG state for restore.
func TestXomWorshipActionTimingAndRestore(t *testing.T) {
	g := newStepGame(t)
	worship, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("player lacks worship state")
	}

	for field, value := range map[string]any{
		"god_id":            "GOD_XOM",
		"piety":             int64(120),
		"gift_timeout":      int64(10),
		"next_god_time_aut": int64(200),
	} {
		if err := worship.Set(field, value); err != nil {
			t.Fatal(err)
		}
	}

	before := g.Snapshot()

	blocked, err := g.Step(Command{
		Kind: CommandMove,
		DX:   -1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if blocked.Spent != 0 {
		t.Fatalf("free move spent %d aut: %v", blocked.Spent, err)
	}

	afterFree := g.Snapshot()

	// A blocked move may append its explanation to the message history.
	// Its saved actors, world time, and Xom RNG must remain untouched.
	if before.CurrentAut != afterFree.CurrentAut ||
		!reflect.DeepEqual(before.RNG, afterFree.RNG) ||
		!reflect.DeepEqual(before.Entities, afterFree.Entities) ||
		!reflect.DeepEqual(before.Levels, afterFree.Levels) {
		t.Fatal("free command changed Xom state, time, or RNG")
	}

	waited, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if waited.Spent != 10 {
		t.Fatalf("player wait spent %d aut: %v", waited.Spent, err)
	}

	if before.RNG["religion"] == g.Snapshot().RNG["religion"] {
		t.Fatal("completed player action did not run Xom reaction")
	}

	committed := g.Snapshot()
	restored, err := Restore(committed)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(committed, restored.Snapshot()) {
		t.Fatal("Xom worship action changed across save and restore")
	}

	// The next commands form a small seeded transcript. Both copies must
	// announce and save exactly the same Xom and monster consequences.
	for turn := 0; turn < 3; turn++ {
		original, originalErr := g.Step(Command{Kind: CommandWait})
		replayed, replayErr := restored.Step(Command{Kind: CommandWait})

		if originalErr != nil {
			t.Fatal(originalErr)
		}

		if replayErr != nil {
			t.Fatal(replayErr)
		}

		if original.Spent != replayed.Spent ||
			!reflect.DeepEqual(original.Events, replayed.Events) ||
			!reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
			t.Fatalf("Xom transcript diverged on turn %d", turn)
		}
	}
}
