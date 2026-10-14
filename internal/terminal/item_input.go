package terminal

import (
	"fmt"
	"strconv"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

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

func (m *AppModel) handleDropKey(key string) tea.Cmd {
	if key == "esc" {
		m.screen = ScreenPlay
		m.dropQuantity = ""
		m.notice = ""

		return nil
	}

	if key == "?" {
		m.previous = ScreenDrop
		m.screen = ScreenHelp
		m.notice = ""

		return nil
	}

	if key == "backspace" {
		if len(m.dropQuantity) > 0 {
			m.dropQuantity = m.dropQuantity[:len(m.dropQuantity)-1]
		}

		return nil
	}

	if len(key) == 1 && key[0] >= '0' && key[0] <= '9' {
		if len(m.dropQuantity) < 8 {
			m.dropQuantity += key
		}

		return nil
	}

	for index, item := range m.game.View().Inventory {
		if key != string(menuLetter(index)) {
			continue
		}

		quantity := 0

		if m.dropQuantity != "" {
			parsed, err := strconv.Atoi(m.dropQuantity)

			if err != nil {
				m.notice = "Invalid drop quantity."

				return nil
			}

			quantity = parsed

			if quantity == 0 {
				m.screen = ScreenPlay
				m.dropQuantity = ""
				m.notice = "Okay."

				return nil
			}
		}

		result, err := m.game.Step(game.Command{
			Kind:     game.CommandDrop,
			ItemID:   item.ID,
			Quantity: quantity,
		})

		m.screen = ScreenPlay
		m.dropQuantity = ""

		if err != nil {
			m.notice = fmt.Sprintf("Drop failed: %v", err)

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

	m.notice = "Select an item by its inventory letter."

	return nil
}
