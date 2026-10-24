package terminal

import (
	"fmt"
	"strings"
	"testing"

	"crawl/internal/game"
)

// A generic spell choice belongs in SpellID, while item and entity menus
// continue to return TargetID to their existing ability policies.
func TestSpellSelectionRoutesToAbilitySpellID(t *testing.T) {
	command := game.Command{
		Kind:      game.CommandAbility,
		AbilityID: "ABIL_SIF_MUNA_FORGET_SPELL",
	}

	selected := selectionCommand(command, "spell", "SPELL_MAGIC_DART")

	if selected.SpellID != "SPELL_MAGIC_DART" ||
		selected.TargetID != "" {
		t.Fatalf("spell selection routed as %+v", selected)
	}

	item := selectionCommand(command, "item", "42")

	if item.TargetID != "42" || item.SpellID != "" {
		t.Fatalf("item selection routed as %+v", item)
	}
}

// A long spell library uses the same stable IDs on every page. The
// terminal only exposes the visible page to the Lua letter decoder.
func TestSelectionPagesBeyondTerminalLetters(t *testing.T) {
	m := playingModel(t)

	m.pendingSelection = &game.SelectionRequest{
		Kind:  "spell",
		Title: "Cast which spell?",
	}

	for index := 0; index < 60; index++ {
		m.pendingSelection.Options = append(m.pendingSelection.Options,
			game.SelectionOption{
				ID:    fmt.Sprintf("SPELL_%02d", index),
				Label: fmt.Sprintf("Spell %02d", index),
			})
	}

	m.openScreen(ScreenSelection)
	first := strings.Join(m.renderCanvas().PlainRows(), "\n")

	if !strings.Contains(first, "Spell 00") ||
		strings.Contains(first, "Spell 20") {
		t.Fatalf("first selection page: %s", first)
	}

	m.handleKey(">")
	second := strings.Join(m.renderCanvas().PlainRows(), "\n")

	if m.selectionPage != 1 ||
		!strings.Contains(second, "Spell 20") ||
		strings.Contains(second, "Spell 00") {
		t.Fatalf("second selection page: %s", second)
	}

	if options := m.selectionPageOptions(); options[0].ID != "SPELL_20" {
		t.Fatalf("page starts at %s", options[0].ID)
	}

	m.handleKey("<")

	if m.selectionPage != 0 {
		t.Fatal("previous page did not return to the first page")
	}
}
