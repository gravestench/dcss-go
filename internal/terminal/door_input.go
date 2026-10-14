package terminal

import (
	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

func (m *AppModel) startDoorCommand(kind game.CommandKind) tea.Cmd {
	view := m.game.View()
	glyph := rune('+')
	verb := "Open"

	if kind == game.CommandCloseDoor {
		glyph = '\''
		verb = "Close"
	}

	choices := 0

	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue
			}

			x := view.PlayerX + dx
			y := view.PlayerY + dy

			if x >= 0 &&
				x < view.Width &&
				y >= 0 &&
				y < view.Height &&
				view.Cells[y*view.Width+x].Glyph == glyph {
				choices++
			}
		}
	}

	if choices > 1 {
		m.pendingDoor = kind
		m.notice = verb + " which direction? (movement key, Esc cancels)"

		return nil
	}

	return m.stepPlayCommand(game.Command{Kind: kind})
}

func (m *AppModel) handleDoorDirectionKey(key string) tea.Cmd {
	if key == "esc" {
		m.pendingDoor = 0
		m.notice = ""

		return nil
	}

	direction, ok := CommandForKey(key)

	if !ok || direction.Kind != game.CommandMove {
		m.notice = "Choose a movement direction or Esc to cancel."

		return nil
	}

	command := game.Command{
		Kind: m.pendingDoor,
		DX:   direction.DX,
		DY:   direction.DY,
	}

	m.pendingDoor = 0

	return m.stepPlayCommand(command)
}
