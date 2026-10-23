package terminal

import (
	"strings"
	"testing"

	"crawl/internal/game"
)

// The generic menu must display saved card slots separately. Two copies
// of one card still have distinct slot IDs for Triple Draw and Stack Five.
func TestNemelexCardMenuShowsDistinctSavedSlots(t *testing.T) {
	m := playingModel(t)

	m.pendingAction = game.Command{
		Kind:      game.CommandAbility,
		AbilityID: "ABIL_NEMELEX_TRIPLE_DRAW",
	}

	m.pendingSelection = &game.SelectionRequest{
		Kind:  "card",
		Title: "Choose a card to play",
		Options: []game.SelectionOption{
			{
				ID:    "1",
				Label: "the Cloud",
			},

			{
				ID:    "2",
				Label: "the Cloud",
			},
		},
	}

	m.openScreen(ScreenSelection)

	rows := strings.Join(m.renderCanvas().PlainRows(), "\n")

	if !strings.Contains(rows, "Choose a card to play") ||
		strings.Count(rows, "the Cloud") != 2 {
		t.Fatalf("card choice screen omitted saved slots:\n%s", rows)
	}
}
