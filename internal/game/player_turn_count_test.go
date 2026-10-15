package game

import "testing"

func TestPlayerActionCountSurvivesVariableCostsAndRestore(t *testing.T) {
	g := newStepGame(t)

	before, found := g.stores.PlayerTurn.Get(g.player)

	if !found || before.Count != 0 {
		t.Fatalf("initial player turn = %+v, found %t", before, found)
	}

	for _, command := range []Command{
		{
			Kind: CommandWait,
		},

		{
			Kind: CommandMove,
			DX:   1,
		},
	} {
		result, err := g.Step(command)

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent <= 0 {
			t.Fatalf("action spent %d aut", result.Spent)
		}
	}

	turn, found := g.stores.PlayerTurn.Get(g.player)

	if !found || turn.Count != 2 {
		t.Fatalf("player turn count = %+v, found %t", turn, found)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	reloaded, found := restored.stores.PlayerTurn.Get(restored.player)

	if !found ||
		reloaded.Count != turn.Count ||
		reloaded.NextAut != turn.NextAut {
		t.Fatalf("restored turn = %+v, want %+v", reloaded, turn)
	}
}
