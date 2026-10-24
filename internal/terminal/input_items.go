package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"crawl/internal/game"
)

func (m *AppModel) applyItemDecision(action string, decision map[string]any) tea.Cmd {
	switch action {
	case "drop_quantity":
		value, ok := decision["value"].(string)

		if !ok || !validDropQuantity(value) {
			m.notice = "Input policy returned an invalid drop quantity."

			return nil
		}

		m.dropQuantity = value

	case "item_step":
		return m.applyItemStep(decision)

	}

	return nil
}

func validDropQuantity(value string) bool {
	if len(value) > 8 {
		return false
	}

	for _, digit := range value {
		if digit < '0' || digit > '9' {
			return false
		}
	}

	return true
}

func inputItemID(decision map[string]any, required bool) (uint64, error) {
	value, found := decision["item_id"]

	if !found {
		if required {
			return 0, fmt.Errorf("input policy omitted an item ID")
		}

		return 0, nil
	}

	id, ok := value.(int64)

	if !ok ||
		id < 0 {
		return 0, fmt.Errorf("input policy returned an invalid item ID")
	}

	return uint64(id), nil
}

func (m *AppModel) applyItemStep(decision map[string]any) tea.Cmd {
	kind, ok := inputCommandKind(decision,
		game.CommandQuaff,
		game.CommandDrop,
		game.CommandWield,
		game.CommandWear,
		game.CommandTakeOff,
		game.CommandRead,
		game.CommandEvokeItem,
	)

	if !ok {
		m.notice = "Input policy returned an invalid item command."

		return nil
	}

	itemID, err := inputItemID(decision, true)

	if err != nil {
		m.notice = err.Error()

		return nil
	}

	if itemID == 0 && kind != game.CommandWield {
		m.notice = "Input policy returned an invalid item ID."

		return nil
	}

	quantity, ok := decision["quantity"].(int64)

	if !ok ||
		quantity < 0 ||
		quantity > 99999999 {
		m.notice = "Input policy returned an invalid item quantity."

		return nil
	}

	command := game.Command{
		Kind:     kind,
		ItemID:   itemID,
		Quantity: int(quantity),
	}

	m.openScreen(ScreenPlay)
	m.dropQuantity = ""

	return m.stepPlayCommand(command)
}
