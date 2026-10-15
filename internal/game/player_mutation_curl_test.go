package game

import (
	"reflect"
	"testing"
)

func TestCurlActivatesAfterRatHitAndClearsBeforeNextMonsterPhase(t *testing.T) {
	g := newStepGame(t)
	baseline := g.View().PlayerAC
	addPlayerMutation(t, g, "MUT_CURL")

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	curled := false

	for attempt := 0; attempt < 40; attempt++ {
		health, _ := g.stores.Health.Get(g.player)

		health.Current = health.Max

		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		if g.View().PlayerAC == baseline+7 {
			curled = true
			break
		}
	}

	if !curled {
		t.Fatal("rat never triggered the source Curl reaction")
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) ||
		restored.View().PlayerAC != baseline+7 {
		t.Fatal("active Curl changed across save restore")
	}

	moveRatToOtherFloor(t, restored)

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if got := restored.View().PlayerAC; got != baseline {
		t.Fatalf("Curl AC after the next player action = %d, want %d",
			got, baseline)
	}
}
