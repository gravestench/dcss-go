package terminal

import (
	tea "charm.land/bubbletea/v2"
	"crawl/internal/game"
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
