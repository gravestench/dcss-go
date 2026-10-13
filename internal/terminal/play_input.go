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
		m.previous, m.screen, m.notice = m.screen, ScreenInventory, ""
		return nil
	case "m":
		m.previous, m.screen, m.notice = m.screen, ScreenSkills, ""
		return nil
	case "?":
		m.previous, m.screen, m.notice = m.screen, ScreenHelp, ""
		return nil
	case "S":
		m.confirm, m.screen, m.notice = confirmSave, ScreenConfirm, ""
		return nil
	case "ctrl+s":
		return m.saveAndExit()
	case "ctrl+q":
		m.confirm, m.screen, m.notice = confirmAbandon, ScreenConfirm, ""
		return nil
	case "q":
		m.notice = "Quaffing is unavailable in the Go port."
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

func (m *AppModel) afterStep(result game.StepResult) {
	if result.View.PlayerDead {
		m.screen = ScreenDeath
	}
}

func (m *AppModel) handleConfirmKey(key string) tea.Cmd {
	if key == "esc" || key == "n" || key == "N" {
		m.confirm, m.screen, m.notice = confirmNone, ScreenPlay, ""
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
		m.screen, m.notice = ScreenPlay, fmt.Sprintf("Save failed: %v", err)
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
