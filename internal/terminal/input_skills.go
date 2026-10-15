package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
)

func (m *AppModel) routeSkillInput(key string) tea.Cmd {
	ids := make([]any, 0)

	for _, column := range m.presentation.SkillColumns {
		for _, id := range column {
			if id != "" {
				ids = append(ids, id)
			}
		}
	}

	return m.routeInput("skills", key, map[string]any{
		"skill_ids": ids,
	})
}

func (m *AppModel) applySkillDecision(action string, decision map[string]any) tea.Cmd {
	switch action {
	case "toggle_skill_mode":
		manual := !m.game.View().SkillTraining.Manual

		if err := m.game.SetSkillTrainingMode(manual); err != nil {
			m.notice = err.Error()

			return nil
		}

		m.notice = ""

	case "toggle_skill_focus":
		m.skillFocusAction = !m.skillFocusAction
		m.notice = ""

	case "change_skill":
		id, ok := decision["id"].(string)

		if !ok || !m.hasSkillID(id) {
			m.notice = "Input policy returned an invalid skill."

			return nil
		}

		if err := m.game.ChangeSkillTraining(id, m.skillFocusAction); err != nil {
			m.notice = fmt.Sprintf("Training choice failed: %v", err)
		} else {
			m.notice = ""
		}
	}

	return nil
}

func (m *AppModel) hasSkillID(wanted string) bool {
	for _, column := range m.presentation.SkillColumns {
		for _, id := range column {
			if id == wanted {
				return true
			}
		}
	}

	return false
}
