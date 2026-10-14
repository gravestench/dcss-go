package terminal

import (
	"fmt"
	"strconv"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
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

			if x >= 0 && x < view.Width && y >= 0 && y < view.Height &&
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

		if m.game != nil && m.game.View().EquipmentDelay != nil {
			return m.nextEquipmentTick()
		}

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

		if m.game.View().EquipmentDelay != nil {
			return m.nextEquipmentTick()
		}

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
