package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

func spellInput(spells []game.SpellView) []any {
	result := make([]any, 0, len(spells))

	for _, spell := range spells {
		result = append(result, map[string]any{
			"id":          spell.ID,
			"in_library":  spell.InLibrary,
			"known_slot":  spell.KnownSlot,
			"letter_slot": spell.LetterSlot,
		})
	}

	return result
}

func (m *AppModel) routeSpellInput(key string) tea.Cmd {
	view := m.game.View()

	return m.routeInput("spells", key, map[string]any{
		"mode":          m.spellMode,
		"spells":        spellInput(view.Spells),
		"last_spell_id": view.LastSpellID,
	})
}

func (m *AppModel) applySpellStep(decision map[string]any) tea.Cmd {
	kind, ok := inputCommandKind(decision,
		game.CommandCast,
		game.CommandForceCast,
		game.CommandMemorise,
	)

	if !ok {
		m.notice = "Input policy returned an invalid spell command."

		return nil
	}

	spellID, ok := decision["spell_id"].(string)

	if !ok || spellID == "" {
		m.notice = fmt.Sprintf("Input policy returned an invalid spell %v.",
			decision["spell_id"])

		return nil
	}

	m.openScreen(ScreenPlay)

	return m.stepPlayCommand(game.Command{
		Kind:    kind,
		SpellID: spellID,
	})
}

func DrawSpells(
	canvas *Canvas,
	view game.View,
	mode string,
	policy presentationPolicy,
) {
	result := runPresentation(policy, "presentation.spells", map[string]any{
		"mode":   mode,
		"spells": spellInput(view.Spells),
		"height": canvas.height,
	})

	drawPresentation(canvas, fullRegion(canvas), result)
}

func (m *AppModel) acceptSpellConfirmation() tea.Cmd {
	if m.pendingSpellPrompt == "" {
		m.notice = "No spell is awaiting confirmation."

		return nil
	}

	command := m.pendingSpell

	command.Forced = true
	m.pendingSpell = game.Command{}
	m.pendingSpellPrompt = ""
	m.openScreen(ScreenPlay)

	return m.stepPlayCommand(command)
}

func DrawSpellConfirmation(
	canvas *Canvas,
	policy presentationPolicy,
	message string,
) {
	result := runPresentation(policy,
		"presentation.spell_confirmation", map[string]any{
			"message": message,
		})

	drawPresentation(canvas, fullRegion(canvas), result)
}
