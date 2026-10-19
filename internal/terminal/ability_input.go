package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"crawl/internal/game"
)

func (m *AppModel) routeAbilityInput(key string) tea.Cmd {
	result, err := m.game.PresentationPolicy("presentation.abilities", map[string]any{
		"height": m.height,
	})

	if err != nil {
		m.notice = fmt.Sprintf("Ability menu failed: %v", err)

		return nil
	}

	return m.routeInput("abilities", key, map[string]any{
		"options": result["options"],
	})
}

func (m *AppModel) applyAbilityStep(decision map[string]any) tea.Cmd {
	abilityID, ok := decision["ability_id"].(string)

	if !ok || abilityID == "" {
		m.notice = "Input policy returned an invalid ability."

		return nil
	}

	m.openScreen(ScreenPlay)

	return m.stepPlayCommand(game.Command{
		Kind:      game.CommandAbility,
		AbilityID: abilityID,
	})
}

func DrawAbilities(canvas *Canvas, policy presentationPolicy) {
	result := runPresentation(policy, "presentation.abilities", map[string]any{
		"height": canvas.height,
	})

	drawPresentation(canvas, fullRegion(canvas), result)
}

func (m *AppModel) beginAbilityConfirmation(decision map[string]any) tea.Cmd {
	abilityID, ok := decision["ability_id"].(string)

	if !ok || abilityID == "" {
		m.notice = "Input policy returned an invalid ability."

		return nil
	}

	m.pendingAbilityID = abilityID
	m.openScreen(ScreenAbilityConfirm)

	return nil
}

func (m *AppModel) acceptAbilityConfirmation() tea.Cmd {
	if m.pendingAbilityID == "" {
		m.notice = "No ability is awaiting confirmation."

		return nil
	}

	abilityID := m.pendingAbilityID

	m.pendingAbilityID = ""
	m.openScreen(ScreenPlay)

	return m.stepPlayCommand(game.Command{
		Kind:      game.CommandAbility,
		AbilityID: abilityID,
		Forced:    true,
	})
}

func DrawAbilityConfirmation(canvas *Canvas, policy presentationPolicy, abilityID string) {
	result := runPresentation(policy,
		"presentation.ability_confirmation", map[string]any{
			"ability_id": abilityID,
		})

	drawPresentation(canvas, fullRegion(canvas), result)
}
