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

	if err == nil ||
		!strings.Contains(err.Error(), "CARD_UNKNOWN_MOD") {
		t.Fatalf("restore error = %v, want missing card ID", err)
	}
}

// An unresolved card choice remains the next input after restore. A move
// cannot consume time or silently abandon the already sampled cards.
func TestNemelexPendingChoiceBlocksUnrelatedCommand(t *testing.T) {
	g, err := NewDungeonGame(
		1013,
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
			"pending_kind":         "triple_draw",
			"pending_phase":        "choose_card",
			"pending_deck":         "DECK_OF_ESCAPE",
			"pending_cards":        []any{"CARD_CLOUD", "CARD_ELIXIR"},
			"pending_target_count": int64(2),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	result, err := loaded.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 ||
		len(result.Events) == 0 ||
		!strings.Contains(result.Events[0].Text, "pending card") {
		t.Fatalf("unrelated command spent %d with events %+v",
			result.Spent, result.Events)
	}
}

// Stack Five's sampled order is also a saved decision. A restored run must
// require that decision before movement, just like Triple Draw's card menu.
func TestNemelexStackOrderSurvivesRestore(t *testing.T) {
	g, err := NewDungeonGame(
		1017,
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
			"pending_kind":         "stack_five",
			"pending_phase":        "order_stack",
			"pending_cards":        []any{"CARD_CLOUD", "CARD_ELIXIR"},
			"pending_target_count": int64(2),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	result, err := loaded.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 ||
		len(result.Events) == 0 ||
		!strings.Contains(result.Events[0].Text, "pending card") {
		t.Fatalf("restored stack choice allowed move: %+v", result)
	}
}

// A normal draw crosses Go input, Lua deck selection, card effect, ability
// timing, and ECS save state. One owned card must be spent exactly once.
func TestNemelexDrawEscapeCompletesOneTurn(t *testing.T) {
	g, err := NewDungeonGame(
		1021,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_NEMELEX_XOBEH",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	decks := g.scripts.Components()["religion.nemelex_decks"]

	_, err = decks.Set(g.player, map[string]any{
		"counts": map[string]any{
			"DECK_OF_ESCAPE": int64(1),
		},
	})

	if err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_NEMELEX_DRAW_ESCAPE",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 {
		t.Fatalf("draw spent %d aut, want one turn", result.Spent)
	}

	announcedDraw := false
	announcedCard := false

	for _, event := range result.Events {
		announcedDraw = announcedDraw ||
			strings.Contains(event.Text, "You draw a card")
		announcedCard = announcedCard ||
			strings.Contains(event.Text, "You have drawn")
	}

	if !announcedDraw || !announcedCard {
		t.Fatalf("draw omitted card announcement: %+v", result.Events)
	}

	value, found := decks.Get(g.player)

	if !found {
		t.Fatal("deck state disappeared")
	}

	fields, err := value.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	counts := fields["counts"].(map[string]any)

	if counts["DECK_OF_ESCAPE"] != int64(0) {
		t.Fatalf("escape count after draw = %v", counts)
	}

	if fields["pending_kind"] != "" {
		t.Fatalf("draw left pending phase %+v", fields)
	}
}

// Declining a precommit Stack Five prompt returns through Lua so the saved
// phase is cleared without spending time or touching the previous stack.
func TestNemelexStackConfirmationCancelClearsPending(t *testing.T) {
	g, err := NewDungeonGame(
		1019,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_NEMELEX_XOBEH",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	decks := g.scripts.Components()["religion.nemelex_decks"]

	_, err = decks.Set(g.player, map[string]any{
		"counts": map[string]any{
			"DECK_OF_ESCAPE": int64(2),
		},
		"stack":         []any{"CARD_CLOUD"},
		"pending_kind":  "stack_five",
		"pending_phase": "replace_stack",
	})

	if err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_NEMELEX_STACK_FIVE",
		Cancelled: true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 {
		t.Fatalf("cancel spent %d aut", result.Spent)
	}

	value, found := decks.Get(g.player)

	if !found {
		t.Fatal("deck state disappeared")
	}

	fields, err := value.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	if fields["pending_kind"] != "" ||
		!reflect.DeepEqual(fields["stack"], []any{"CARD_CLOUD"}) {
		t.Fatalf("cancelled deck state = %+v", fields)
	}
}

// A targeted card is consumed before its aim prompt. Confirming an abort
// after restoring that prompt spends the normal turn and cannot refund it.
func TestNemelexTargetAbortAfterRestoreWastesCard(t *testing.T) {
	g, err := NewDungeonGame(
		1031,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_NEMELEX_XOBEH",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["religion.nemelex_decks"].Set(
		g.player,
		map[string]any{
			"counts": map[string]any{
				"DECK_OF_DESTRUCTION": int64(0),
			},
			"pending_kind":         "draw",
			"pending_phase":        "target_card",
			"pending_deck":         "DECK_OF_DESTRUCTION",
			"pending_cards":        []any{"CARD_PAIN"},
			"pending_target_count": int64(1),
			"pending_selected":     int64(1),
			"pending_tier":         int64(2),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_NEMELEX_DRAW_DESTRUCTION",
		Cancelled: true,
	}
	confirm, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if confirm.Spent != 0 ||
		!strings.Contains(confirm.Confirmation, "waste the card") {
		t.Fatalf("target abort confirmation = %+v", confirm)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	command.Cancelled = false
	command.Forced = true
	wasted, err := loaded.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if wasted.Spent != 10 {
		t.Fatalf("confirmed waste spent %d aut", wasted.Spent)
	}

	value, found := loaded.scripts.Components()["religion.nemelex_decks"].Get(loaded.player)

	if !found {
		t.Fatal("deck state disappeared after card waste")
	}

	fields, err := value.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	counts := fields["counts"].(map[string]any)

	if counts["DECK_OF_DESTRUCTION"] != int64(0) ||
		fields["pending_kind"] != "" {
		t.Fatalf("confirmed waste changed consumed card: %+v", fields)
	}
}

// A friendly-fire confirmation owns the chosen ray after the card has
// already been consumed. Restore must preserve the exact aim for a later
// yes answer rather than silently resampling or firing at another cell.
func TestNemelexFriendlyRaySurvivesRestore(t *testing.T) {
	g, err := NewDungeonGame(
		1033,
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
			"counts": map[string]any{
				"DECK_OF_DESTRUCTION": int64(0),
			},
			"pending_kind":         "draw",
			"pending_phase":        "confirm_friendly",
			"pending_deck":         "DECK_OF_DESTRUCTION",
			"pending_cards":        []any{"CARD_VITRIOL"},
			"pending_target_count": int64(1),
			"pending_selected":     int64(1),
			"pending_tier":         int64(0),
			"pending_dx":           int64(2),
			"pending_dy":           int64(-1),
		},
	)

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
		t.Fatal("friendly-fire confirmation ray changed across restore")
	}

	value, found := loaded.scripts.Components()["religion.nemelex_decks"].Get(loaded.player)

	if !found {
		t.Fatal("restored card confirmation is missing")
	}

	fields, err := value.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	if fields["pending_phase"] != "confirm_friendly" ||
		fields["pending_dx"] != int64(2) ||
		fields["pending_dy"] != int64(-1) {
		t.Fatalf("restored friendly-fire ray = %+v", fields)
	}

	// A declined confirmation resumes the saved card's aim without charging
	// another turn or losing the already consumed card.
	result, err := loaded.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_NEMELEX_DRAW_DESTRUCTION",
		Cancelled: true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || result.Selection == nil ||
		result.Selection.Kind != "cell" {
		t.Fatalf("declined friendly-fire confirmation = %+v", result)
	}
}
