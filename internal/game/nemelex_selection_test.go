package game

import "testing"

// A Lua card menu uses the same terminal selection bridge as items and
// spells. Its option IDs identify saved slots, even for duplicate cards.
func TestCardSelectionAcceptsDistinctSlots(t *testing.T) {
	request, err := selectionFromDecision(map[string]any{
		"kind":  "card",
		"title": "Choose a card to play",
		"options": []any{
			map[string]any{
				"id":    "1",
				"label": "the Cloud",
			},

			map[string]any{
				"id":    "2",
				"label": "the Cloud",
			},
		},
	})

	if err != nil {
		t.Fatal(err)
	}

	if request.Kind != "card" || len(request.Options) != 2 {
		t.Fatalf("card selection = %+v", request)
	}
}
