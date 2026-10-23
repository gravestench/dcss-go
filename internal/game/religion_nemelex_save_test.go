package game

import (
	"reflect"
	"strings"
	"testing"
)

// A sampled card is a fact about the current run, not a future RNG request.
// Restore must retain deck counts, stack order, and an unresolved choice.
func TestNemelexDeckStateSurvivesRestore(t *testing.T) {
	g, err := NewDungeonGame(
		1007,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	store := g.scripts.Components()["religion.nemelex_decks"]

	if store == nil {
		t.Fatal("Nemelex deck component was not registered")
	}

	_, err = store.Set(g.player, map[string]any{
		"counts": map[string]any{
			"DECK_OF_ESCAPE":      int64(2),
			"DECK_OF_DESTRUCTION": int64(3),
		},
		"stack":                []any{"CARD_TOMB", "CARD_ELIXIR"},
		"pending_kind":         "triple_draw",
		"pending_phase":        "choose_card",
		"pending_deck":         "DECK_OF_ESCAPE",
		"pending_cards":        []any{"CARD_EXILE", "CARD_CLOUD"},
		"pending_target_count": int64(2),
		"pending_selected":     int64(0),
	})

	if err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("Nemelex deck state changed across restore")
	}
}

// A removed mod card cannot become another random card on restore. The
// error must name the lost stable ID so the player can restore that mod.
func TestNemelexRestoreRejectsUnknownCardID(t *testing.T) {
	g, err := NewDungeonGame(
		1009,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.nemelex_decks"].Set(
		g.player,
		map[string]any{
			"stack": []any{"CARD_UNKNOWN_MOD"},
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if loaded != nil {
		defer loaded.Close()
	}

	if err == nil || !strings.Contains(err.Error(), "CARD_UNKNOWN_MOD") {
		t.Fatalf("restore error = %v, want missing card ID", err)
	}
}
