package game

import "testing"

// Starting religion is stored in the live ECS owner and must reach the
// human-facing view without a second hard-coded god table in Go.
func TestStartingWorshipAppearsInPlayerView(t *testing.T) {
	g, err := NewDungeonGame(
		619,
		"SP_HUMAN",
		"JOB_BERSERKER",
		"WPN_HAND_AXE",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	view := g.View()

	if view.GodName != "Trog" ||
		view.PietyStars != "*....." ||
		view.Penance != 0 {
		t.Fatalf("starting worship view: god=%q stars=%q penance=%d",
			view.GodName, view.PietyStars, view.Penance)
	}
}
