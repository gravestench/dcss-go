package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

func (m *AppModel) handleArmourKey(key string) tea.Cmd {
	if key == "esc" {
		m.screen = ScreenPlay
		m.notice = ""

		return nil
	}

	if key == "?" {
		m.previous = m.screen
		m.screen = ScreenHelp
		m.notice = ""

		return nil
	}

	kind := game.CommandWear
	remove := m.screen == ScreenTakeOff

	if remove {
		kind = game.CommandTakeOff
	}

	for index, item := range m.game.View().Inventory {
		if key != string(menuLetter(index)) || item.Class != "OBJ_ARMOUR" {
			continue
		}

		if remove && item.Slot == "" || !remove && item.Slot != "" {
			break
		}

		m.screen = ScreenPlay

		return m.stepPlayCommand(game.Command{
			Kind:   kind,
			ItemID: item.ID,
		})
	}

	m.notice = "Choose armour by its inventory letter, or Esc to cancel."

	return nil
}

func (m *AppModel) handleWieldKey(key string) tea.Cmd {
	if key == "esc" {
		m.screen = ScreenPlay
		m.notice = ""

		return nil
	}

	if key == "?" {
		m.previous = ScreenWield
		m.screen = ScreenHelp
		m.notice = ""

		return nil
	}

	itemID := uint64(0)
	selected := key == "-"

	if !selected {
		for index, item := range m.game.View().Inventory {
			if item.Class == "OBJ_WEAPONS" && key == string(menuLetter(index)) {
				itemID = item.ID
				selected = true

				break
			}
		}
	}

	if !selected {
		m.notice = "Select a weapon by its inventory letter, or - for bare hands."

		return nil
	}

	result, err := m.game.Step(game.Command{
		Kind:   game.CommandWield,
		ItemID: itemID,
	})

	m.screen = ScreenPlay

	if err != nil {
		m.notice = fmt.Sprintf("Wield failed: %v", err)

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
