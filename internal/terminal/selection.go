package terminal

import (
	"charm.land/bubbletea/v2"
	"crawl/internal/game"
)

func selectionOptions(request *game.SelectionRequest) []any {
	if request == nil {
		return nil
	}

	options := make([]any, 0, len(request.Options))

	for _, option := range request.Options {
		options = append(options, map[string]any{
			"id":    option.ID,
			"label": option.Label,
		})
	}

	return options
}

func (m *AppModel) drawSelection(canvas *Canvas) {
	if m.pendingSelection == nil {
		return
	}

	result := runPresentation(m.presentationPolicy,
		"presentation.selection", map[string]any{
			"title":   m.pendingSelection.Title,
			"options": selectionOptions(m.pendingSelection),
			"height":  canvas.height,
		})

	drawPresentation(canvas, fullRegion(canvas), result)
}

func (m *AppModel) applySelectionDecision(
	action string,
	decision map[string]any,
) tea.Cmd {
	if m.screen != ScreenSelection || m.pendingSelection == nil {
		m.notice = "No selection is pending."

		return nil
	}

	command := m.pendingAction

	if action == "selection_cancel" {
		command.Cancelled = true
	} else {
		selected, ok := decision["target_id"].(string)

		if !ok || selected == "" {
			m.notice = "Input policy returned an invalid selection."

			return nil
		}

		found := false

		for _, option := range m.pendingSelection.Options {
			if option.ID == selected {
				found = true
			}
		}

		if !found {
			m.notice = "Input policy returned an unknown selection."

			return nil
		}

		command.TargetID = selected
	}

	m.pendingSelection = nil
	m.pendingAction = game.Command{}
	m.openScreen(ScreenPlay)

	return m.stepPlayCommand(command)
}
