package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/save"
)

func (m *AppModel) handleStatChoiceKey(key string) {
	id := ""

	switch key {
	case "S":
		id = "str"

	case "I":
		id = "int"

	case "D":
		id = "dex"

	default:
		m.notice = "Choose S, I, or D."

		return
	}

	result, err := m.game.ChooseStat(id)

	if err != nil {
		m.notice = fmt.Sprintf("Stat choice failed: %v", err)

		return
	}

	m.notice = ""
	m.screen = ScreenPlay
	m.afterStep(result)
}

func (m *AppModel) handleConfirmKey(key string) tea.Cmd {
	if key == "esc" ||
		key == "n" || key == "N" {
		m.confirm = confirmNone
		m.screen = ScreenPlay
		m.notice = ""

		if m.game != nil && m.game.View().EquipmentDelay != nil {
			return m.nextEquipmentTick()
		}

		return nil
	}

	if key != "y" &&
		key != "Y" &&
		!(key == "S" &&
			m.confirm == confirmSave) {
		return nil
	}

	action := m.confirm

	m.confirm = confirmNone

	switch action {
	case confirmSave:
		return m.saveAndExit()

	case confirmAbandon:
		m.screen = ScreenDeath

		return nil
	}

	return nil
}

func (m *AppModel) saveAndExit() tea.Cmd {
	if err := save.Write(m.savePath, m.game.Snapshot()); err != nil {
		m.screen = ScreenPlay
		m.notice = fmt.Sprintf("Save failed: %v", err)

		if m.game.View().EquipmentDelay != nil {
			return m.nextEquipmentTick()
		}

		return nil
	}

	return tea.Quit
}
