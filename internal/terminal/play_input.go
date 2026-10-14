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
		switch key {
		case "esc":
			m.equipmentTickID++

			return m.stepPlayCommand(game.Command{
				Kind: game.CommandCancelEquipment,
			})

		case "S":
			m.equipmentTickID++
			m.confirm = confirmSave
			m.screen = ScreenConfirm
			m.notice = ""

			return nil

		case "ctrl+s":
			m.equipmentTickID++

			return m.saveAndExit()
		}

		m.notice = "You are changing your equipment. Esc interrupts."

		return nil
	}

	if m.pendingDoor != 0 {
		return m.handleDoorDirectionKey(key)
	}

	switch key {
	case "i":
		m.previous = m.screen
		m.screen = ScreenInventory
		m.notice = ""

		return nil

	case "m":
		m.previous = m.screen
		m.screen = ScreenSkills
		m.notice = ""

		return nil

	case "?":
		m.previous = m.screen
		m.screen = ScreenHelp
		m.notice = ""

		return nil

	case "S":
		m.confirm = confirmSave
		m.screen = ScreenConfirm
		m.notice = ""

		return nil

	case "ctrl+s":
		return m.saveAndExit()

	case "ctrl+q":
		m.confirm = confirmAbandon
		m.screen = ScreenConfirm
		m.notice = ""

		return nil

	case "q":
		m.previous = m.screen
		m.screen = ScreenQuaff
		m.notice = ""

		return nil

	case "d":
		m.screen = ScreenDrop
		m.dropQuantity = ""
		m.notice = ""

		return nil

	case "w":
		m.screen = ScreenWield
		m.notice = ""

		return nil

	case "W":
		m.screen = ScreenWear
		m.notice = ""

		return nil

	case "T":
		m.screen = ScreenTakeOff
		m.notice = ""

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
