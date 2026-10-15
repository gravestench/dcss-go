package game

import "testing"

func TestOrdinaryHostileMonsterDoesNotDetectInvisiblePlayer(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	ai, _ := g.stores.AI.Get(rat)

	if ai.Behavior != "wander" {
		t.Fatalf("fixture rat starts in %q state", ai.Behavior)
	}

	_, err := g.scripts.Components()["character.potion_invisibility"].Set(
		g.player,
		map[string]any{
			"remaining_aut": int64(100),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if ai.Behavior != "wander" {
		t.Fatalf("rat detected an invisible player: %+v", ai)
	}
}
