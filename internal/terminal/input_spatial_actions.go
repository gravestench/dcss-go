package terminal

import (
	"charm.land/bubbletea/v2"
)

func (m *AppModel) applySpatialDecision(action string, decision map[string]any) tea.Cmd {
	if action == "fire_aim" ||
		action == "cycle_aim" ||
		action == "move_aim" {
		if m.screen != ScreenAim {
			m.notice = "Input policy requested aiming outside the aim screen."

			return nil
		}
	}

	if action == "finish_door" && m.pendingDoor == 0 {
		m.notice = "Input policy requested a door action without a prompt."

		return nil
	}

	switch action {
	case "fire_aim":
		return m.fireAim()

	case "cycle_aim":
		m.cycleAimTarget()

	case "move_aim":
		return m.moveAim(decision)

	case "cancel_door":
		m.pendingDoor = 0
		m.notice = ""

	case "finish_door":
		return m.finishDoor(decision)

	}

	return nil
}
