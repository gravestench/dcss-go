package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

func inputDirection(decision map[string]any) (int, int, error) {
	dx, xOK := decision["dx"].(int64)
	dy, yOK := decision["dy"].(int64)

	if !xOK ||
		!yOK ||
		dx < -1 ||
		dx > 1 ||
		dy < -1 ||
		dy > 1 ||
		(dx == 0 && dy == 0) {
		return 0, 0, fmt.Errorf("input policy returned an invalid direction")
	}

	return int(dx), int(dy), nil
}

func (m *AppModel) fireAim() tea.Cmd {
	view := m.game.View()
	command := game.Command{
		Kind:      m.aimKind,
		DX:        m.aimX - view.PlayerX,
		DY:        m.aimY - view.PlayerY,
		ItemID:    m.aimItemID,
		SpellID:   m.aimSpellID,
		AbilityID: m.aimAbilityID,
	}

	if m.pendingSelection != nil &&
		m.pendingSelection.Kind == "cell" {
		command = m.pendingAction
		command.DX = m.aimX - view.PlayerX
		command.DY = m.aimY - view.PlayerY
		m.pendingAction = game.Command{}
		m.pendingSelection = nil
	}

	m.openScreen(ScreenPlay)

	return m.stepPlayCommand(command)
}

func (m *AppModel) moveAim(decision map[string]any) tea.Cmd {
	dx, dy, err := inputDirection(decision)

	if err != nil {
		m.notice = err.Error()

		return nil
	}

	view := m.game.View()
	x := m.aimX + dx
	y := m.aimY + dy

	if x < 0 ||
		y < 0 ||
		x >= view.Width ||
		y >= view.Height ||
		view.Cells[y*view.Width+x].State != game.Visible {
		m.notice = "You cannot aim there."

		return nil
	}

	m.aimX = x
	m.aimY = y
	m.notice = ""

	return nil
}

func (m *AppModel) finishDoor(decision map[string]any) tea.Cmd {
	dx, dy, err := inputDirection(decision)

	if err != nil {
		m.notice = err.Error()

		return nil
	}

	command := game.Command{
		Kind: m.pendingDoor,
		DX:   dx,
		DY:   dy,
	}

	m.pendingDoor = 0

	return m.stepPlayCommand(command)
}
