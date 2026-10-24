package terminal

import (
	"charm.land/bubbletea/v2"
	"crawl/internal/game"
)

func selectionOptions(choices []game.SelectionOption) []any {
	options := make([]any, 0, len(choices))

	for _, option := range choices {
		options = append(options, map[string]any{
			"id":    option.ID,
			"label": option.Label,
		})
	}

	return options
}

// Reserve the title, a blank row, and the navigation footer. Letters are
// reused on each page, while the selection IDs remain stable across pages.
func (m *AppModel) selectionPageSize() int {
	size := m.height - 4

	if size < 1 {
		return 1
	}

	if size > 52 {
		return 52
	}

	return size
}

func (m *AppModel) selectionPageOptions() []game.SelectionOption {
	if m.pendingSelection == nil {
		return nil
	}

	start := m.selectionPage * m.selectionPageSize()

	// A terminal resize can change page size while a prompt is open.
	if start >= len(m.pendingSelection.Options) {
		m.selectionPage = (len(m.pendingSelection.Options) - 1) /
			m.selectionPageSize()
		start = m.selectionPage * m.selectionPageSize()
	}

	end := start + m.selectionPageSize()

	if end > len(m.pendingSelection.Options) {
		end = len(m.pendingSelection.Options)
	}

	return m.pendingSelection.Options[start:end]
}

func (m *AppModel) selectionHasNext() bool {
	return m.pendingSelection != nil &&
		(m.selectionPage+1)*m.selectionPageSize() <
			len(m.pendingSelection.Options)
}

func (m *AppModel) drawSelection(canvas *Canvas) {
	if m.pendingSelection == nil {
		return
	}

	result := runPresentation(m.presentationPolicy,
		"presentation.selection", map[string]any{
			"title":   m.pendingSelection.Title,
			"options": selectionOptions(m.selectionPageOptions()),
			"height":  canvas.height,
			"page":    m.selectionPage + 1,
			"pages": (len(m.pendingSelection.Options) +
				m.selectionPageSize() - 1) / m.selectionPageSize(),
		})

	drawPresentation(canvas, fullRegion(canvas), result)
}

// The selection protocol uses stable IDs for several kinds of thing. Spell
// IDs occupy the command's SpellID field; item and entity IDs keep TargetID.
func selectionCommand(command game.Command, kind, selected string) game.Command {
	command.Cancelled = false
	command.Forced = false

	if kind == "spell" {
		command.SpellID = selected
		command.TargetID = ""

		return command
	}

	command.TargetID = selected

	return command
}

func (m *AppModel) applySelectionDecision(
	action string,
	decision map[string]any,
) tea.Cmd {
	if m.screen != ScreenSelection || m.pendingSelection == nil {
		m.notice = "No selection is pending."

		return nil
	}

	if action == "selection_next" {
		if m.selectionHasNext() {
			m.selectionPage++
		}

		return nil
	}

	if action == "selection_previous" {
		if m.selectionPage > 0 {
			m.selectionPage--
		}

		return nil
	}

	command := m.pendingAction

	command.TargetID = ""
	command.Cancelled = false
	command.Forced = false

	if action == "selection_cancel" {
		command.Cancelled = true
	} else {
		selected, ok := decision["target_id"].(string)

		if !ok || selected == "" {
			m.notice = "Input policy returned an invalid selection."

			return nil
		}

		found := false

		for _, option := range m.selectionPageOptions() {
			if option.ID == selected {
				found = true
			}
		}

		if !found {
			m.notice = "Input policy returned an unknown selection."

			return nil
		}

		command = selectionCommand(command,
			m.pendingSelection.Kind, selected)
	}

	m.pendingSelection = nil
	m.pendingAction = game.Command{}
	m.openScreen(ScreenPlay)

	return m.stepPlayCommand(command)
}
