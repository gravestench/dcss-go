package terminal

import (
	tea "charm.land/bubbletea/v2"
	"crawl/internal/game"
)

func (m *AppModel) acceptActionConfirmation() tea.Cmd {
	if m.pendingActionPrompt == "" {
		m.notice = "No action is awaiting confirmation."

		return nil
	}

	command := m.pendingAction

	command.Cancelled = false
	command.Forced = true
	m.pendingAction = game.Command{}
	m.pendingActionPrompt = ""
	m.openScreen(ScreenPlay)

	return m.stepPlayCommand(command)
}

func DrawActionConfirmation(
	canvas *Canvas,
	policy presentationPolicy,
	message string,
) {
	result := runPresentation(policy,
		"presentation.action_confirmation", map[string]any{
			"message": message,
		})

	drawPresentation(canvas, fullRegion(canvas), result)
}
