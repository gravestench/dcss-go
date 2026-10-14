package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

func (m *AppModel) handlePlayKey(key string) tea.Cmd {
	if m.game == nil {
		m.notice = "No game is running."

		return nil
	}

	if m.game.View().EquipmentDelay != nil {
		return m.handleEquipmentDelayKey(key)
	}

	if m.pendingDoor != 0 {
		return m.handleDoorDirectionKey(key)
	}

	switch key {
	case "i":
		m.openReturnableScreen(ScreenInventory)

		return nil

	case "m":
		m.openReturnableScreen(ScreenSkills)

		return nil

	case "?":
		m.openReturnableScreen(ScreenHelp)

		return nil

	case "S":
		m.openConfirmation(confirmSave)

		return nil

	case "ctrl+s":
		return m.saveAndExit()

	case "ctrl+q":
		m.openConfirmation(confirmAbandon)

		return nil

	case "q":
		m.openReturnableScreen(ScreenQuaff)

		return nil

	case "d":
		m.openScreen(ScreenDrop)
		m.dropQuantity = ""

		return nil

	case "w":
		m.openScreen(ScreenWield)

		return nil

	case "W":
		m.openScreen(ScreenWear)

		return nil

	case "T":
		m.openScreen(ScreenTakeOff)

		return nil

	case "O":
		return m.startDoorCommand(game.CommandOpenDoor)

	case "C":
		return m.startDoorCommand(game.CommandCloseDoor)

	case "L":
		m.notice = "Running is unavailable in the Go port."

		return nil
	}

	command, ok := CommandForKey(key)

	if !ok {
		m.notice = fmt.Sprintf("Command %q is unavailable in the Go port.", key)

		return nil
	}

	return m.stepPlayCommand(command)
}

func (m *AppModel) handleEquipmentDelayKey(key string) tea.Cmd {
	switch key {
	case "esc":
		m.equipmentTickID++

		return m.stepPlayCommand(game.Command{
			Kind: game.CommandCancelEquipment,
		})

	case "S":
		m.equipmentTickID++
		m.openConfirmation(confirmSave)

		return nil

	case "ctrl+s":
		m.equipmentTickID++

		return m.saveAndExit()
	}

	m.notice = "You are changing your equipment. Esc interrupts."

	return nil
}

func (m *AppModel) openScreen(screen ScreenID) {
	m.screen = screen
	m.notice = ""
}

func (m *AppModel) openReturnableScreen(screen ScreenID) {
	m.previous = m.screen
	m.openScreen(screen)
}

func (m *AppModel) openConfirmation(action confirmation) {
	m.confirm = action
	m.openScreen(ScreenConfirm)
}

func (m *AppModel) stepPlayCommand(command game.Command) tea.Cmd {
	result, err := m.game.Step(command)

	if err != nil {
		m.notice = fmt.Sprintf("Action failed: %v", err)

		return nil
	}

	m.notice = ""
	m.afterStep(result)

	if result.View.EquipmentDelay != nil && m.screen == ScreenPlay {
		return m.nextEquipmentTick()
	}

	return nil
}

func (m *AppModel) afterStep(result game.StepResult) {
	if result.View.PlayerDead {
		m.screen = ScreenDeath
	} else if result.View.PendingStatLevel != 0 {
		m.screen = ScreenStatChoice
	}
}
