package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
)

func (m *AppModel) handlePlayKey(key string) tea.Cmd {
	if m.game == nil {
		m.notice = "No game is running."

		return nil
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

	case "L":
		m.notice = "Running is unavailable in the Go port."

		return nil
	}

	command, ok := CommandForKey(key)

	if !ok {
		m.notice = fmt.Sprintf("Command %q is unavailable in the Go port.", key)

		return nil
	}

	result, err := m.game.Step(command)

	if err != nil {
		m.notice = fmt.Sprintf("Action failed: %v", err)

		return nil
	}

	m.notice = ""
	m.afterStep(result)

	return nil
}

func (m *AppModel) handleQuaffKey(key string) tea.Cmd {
	if key == "esc" {
		m.screen = ScreenPlay
		m.notice = ""

		return nil
	}

	if key == "?" {
		m.previous = ScreenQuaff
		m.screen = ScreenHelp
		m.notice = ""

		return nil
	}

	for index, item := range m.game.View().Inventory {
		if item.Class != "OBJ_POTIONS" || key != string(menuLetter(index)) {
			continue
		}

		result, err := m.game.Step(game.Command{
			Kind:   game.CommandQuaff,
			ItemID: item.ID,
		})
		m.screen = ScreenPlay

		if err != nil {
			m.notice = fmt.Sprintf("Quaff failed: %v", err)

			return nil
		}

		if result.Spent == 0 {
			m.notice = result.Events[0].Text

			return nil
		}

		m.notice = ""
		m.afterStep(result)

		return nil
	}

	m.notice = "Select a potion by its inventory letter."

	return nil
}

func (m *AppModel) afterStep(result game.StepResult) {
	if result.View.PlayerDead {
		m.screen = ScreenDeath
	} else if result.View.PendingStatLevel != 0 {
		m.screen = ScreenStatChoice
	}
}

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
	if key == "esc" || key == "n" || key == "N" {
		m.confirm = confirmNone
		m.screen = ScreenPlay
		m.notice = ""

		return nil
	}

	if key != "y" && key != "Y" && !(key == "S" && m.confirm == confirmSave) {
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

		return nil
	}

	return tea.Quit
}

func (m *AppModel) drawConfirm(canvas *Canvas) {
	prompt := "Save game and exit? (Y/n)"

	if m.confirm == confirmAbandon {
		prompt = "Are you sure you want to abandon this character? (y/N)"
	}

	canvas.Write(0, 0, prompt, LightGrey, Black)
}
