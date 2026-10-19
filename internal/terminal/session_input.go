package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"crawl/internal/save"
)

func (m *AppModel) routeConfirmationInput(key string) tea.Cmd {
	confirmation := "abandon"

	if m.confirm == confirmSave {
		confirmation = "save"
	}

	return m.routeInput("confirm", key, map[string]any{
		"confirmation": confirmation,
	})
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
