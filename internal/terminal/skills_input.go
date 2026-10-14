package terminal

import "fmt"

func (m *AppModel) handleSkillsKey(key string) {
	switch key {
	case "esc":
		m.screen = ScreenPlay
		m.notice = ""

		return

	case "?":
		m.previous = ScreenSkills
		m.screen = ScreenHelp
		m.notice = ""

		return

	case "/":
		manual := !m.game.View().SkillTraining.Manual

		if err := m.game.SetSkillTrainingMode(manual); err != nil {
			m.notice = err.Error()

			return
		}

		m.notice = ""

		return

	case "|":
		m.skillFocusAction = !m.skillFocusAction
		m.notice = ""

		return
	}

	letter := 0

	for _, column := range m.presentation.SkillColumns {
		for _, id := range column {
			if id == "" {
				continue
			}

			if key == string(menuLetter(letter)) {
				if err := m.game.ChangeSkillTraining(id, m.skillFocusAction); err != nil {
					m.notice = fmt.Sprintf("Training choice failed: %v", err)
				} else {
					m.notice = ""
				}

				return
			}

			letter++
		}
	}

	m.notice = "This training control is unavailable in the Go port."
}
