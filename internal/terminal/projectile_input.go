package terminal

import (
	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

func (m *AppModel) startAim(kind game.CommandKind, itemID uint64) {
	view := m.game.View()

	m.aimKind = kind
	m.aimItemID = itemID
	m.aimX = view.PlayerX + 1
	m.aimY = view.PlayerY

	for _, entity := range view.Entities {
		if entity.Role == "monster" {
			m.aimX = entity.X
			m.aimY = entity.Y
			break
		}
	}

	m.openScreen(ScreenAim)
}

func (m *AppModel) handleThrowKey(key string) tea.Cmd {
	if key == "esc" {
		m.openScreen(ScreenPlay)

		return nil
	}

	if key == "?" {
		m.openReturnableScreen(ScreenHelp)

		return nil
	}

	for index, item := range m.game.View().Inventory {
		if key != string(menuLetter(index)) {
			continue
		}

		if item.Class != "OBJ_MISSILES" {
			m.notice = "That is not a missile."

			return nil
		}

		m.startAim(game.CommandThrow, item.ID)

		return nil
	}

	m.notice = "Select a missile by its inventory letter."

	return nil
}

func (m *AppModel) handleAimKey(key string) tea.Cmd {
	if key == "esc" {
		m.openScreen(ScreenPlay)

		return nil
	}

	if key == "enter" {
		view := m.game.View()
		command := game.Command{
			Kind:   m.aimKind,
			DX:     m.aimX - view.PlayerX,
			DY:     m.aimY - view.PlayerY,
			ItemID: m.aimItemID,
		}

		m.openScreen(ScreenPlay)

		return m.stepPlayCommand(command)
	}

	if key == "tab" {
		m.cycleAimTarget()

		return nil
	}

	command, found := CommandForKey(key)

	if !found || command.Kind != game.CommandMove {
		m.notice = "Move the target with direction keys; Enter fires, Esc cancels."

		return nil
	}

	view := m.game.View()
	x := m.aimX + command.DX
	y := m.aimY + command.DY

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

func (m *AppModel) cycleAimTarget() {
	view := m.game.View()
	first := -1
	next := -1

	for index, entity := range view.Entities {
		if entity.Role != "monster" {
			continue
		}

		if first == -1 {
			first = index
		}

		if entity.X == m.aimX && entity.Y == m.aimY {
			for later := index + 1; later < len(view.Entities); later++ {
				if view.Entities[later].Role == "monster" {
					next = later

					break
				}
			}

			break
		}
	}

	if next == -1 {
		next = first
	}

	if next != -1 {
		m.aimX = view.Entities[next].X
		m.aimY = view.Entities[next].Y
	}
}

func (m *AppModel) drawAim(canvas *Canvas, layout Layout) {
	view := m.game.View()
	x := layout.Dungeon.X + layout.Dungeon.W/2 + m.aimX - view.PlayerX
	y := layout.Dungeon.Y + layout.Dungeon.H/2 + m.aimY - view.PlayerY

	if x >= layout.Dungeon.X &&
		x < layout.Dungeon.X+layout.Dungeon.W &&
		y >= layout.Dungeon.Y &&
		y < layout.Dungeon.Y+layout.Dungeon.H {
		entry := canvas.cells[y*canvas.width+x]
		glyph := []rune(entry.text)

		if len(glyph) > 0 {
			canvas.Put(x, y, glyph[0], Black, Yellow)
		}
	}

	result := runPresentation(m.presentationPolicy, "presentation.aim", map[string]any{
		"throwing": m.aimKind == game.CommandThrow,
		"x":        m.aimX,
		"y":        m.aimY,
	})

	drawPresentation(canvas, layout.Messages, result)

	if m.notice != "" {
		canvas.Write(layout.Messages.X, layout.Messages.Y+1,
			m.notice, LightRed, Black)
	}
}
