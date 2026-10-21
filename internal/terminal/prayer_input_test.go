package terminal

import (
	"testing"

	"crawl/internal/game"
)

// Input sees only presented altar positions. Prayer itself must still read
// and validate the underlying saved record before it spends a turn.
func TestAltarAtPlayerUsesExactVisiblePosition(t *testing.T) {
	view := game.View{
		PlayerX: 4,
		PlayerY: 7,
		Entities: []game.EntityView{
			{
				Role: "altar",
				X:    5,
				Y:    7,
			},
		},
	}

	if altarAtPlayer(view) {
		t.Fatal("neighboring altar was treated as the player's cell")
	}

	view.Entities = append(view.Entities, game.EntityView{
		Role: "altar",
		X:    4,
		Y:    7,
	})

	if !altarAtPlayer(view) {
		t.Fatal("altar at the player's cell was missed")
	}
}

// The Lua play route can request prayer without teaching the terminal a
// second command vocabulary or bypassing the normal command validator.
func TestPrayerCommandKindAllowedFromInputPolicy(t *testing.T) {
	command, err := playCommandFromDecision(map[string]any{
		"kind": int64(game.CommandPray),
	})

	if err != nil {
		t.Fatal(err)
	}

	if command.Kind != game.CommandPray {
		t.Fatalf("prayer input routed to command %d", command.Kind)
	}
}
