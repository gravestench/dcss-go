package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
)

func (m *AppModel) applyNavigationDecision(action string, decision map[string]any) tea.Cmd {
	switch action {
	case "none":
		return nil

	case "return_screen":
		if !m.canEnterInputScreen(m.previous) {
			m.notice = "Input policy returned an invalid previous screen."

			return nil
		}

		m.openScreen(m.previous)

	case "return_to_startup":
		m.returnToStartup()

	case "notice":
		message, ok := decision["text"].(string)

		if !ok {
			m.notice = "Input policy returned an invalid notice."

			return nil
		}

		m.notice = message

	case "screen":
		name, named := decision["screen"].(string)
		screen, found := inputScreens[name]
		returnable, typed := decision["returnable"].(bool)

		if !named ||
			!found ||
			!typed ||
			!m.canEnterInputScreen(screen) {
			m.notice = "Input policy returned an invalid screen."

			return nil
		}

		quantity, hasQuantity := decision["drop_quantity"].(string)
		message, hasNotice := decision["notice"].(string)

		if value, present := decision["drop_quantity"]; present &&
			(!hasQuantity || !validDropQuantity(quantity)) {
			m.notice = fmt.Sprintf("Input policy returned invalid drop quantity %T.", value)

			return nil
		}

		if value, present := decision["notice"]; present && !hasNotice {
			m.notice = fmt.Sprintf("Input policy returned invalid screen notice %T.", value)

			return nil
		}

		focus, hasFocus := decision["focus"].(int64)

		if value, present := decision["focus"]; present &&
			(!hasFocus ||
				focus < 0 ||
				focus >= int64(m.focusCountFor(screen))) {
			m.notice = fmt.Sprintf("Input policy returned invalid focus %v.", value)

			return nil
		}

		clearChoice, hasClear := decision["clear_choice"].(string)

		if value, present := decision["clear_choice"]; present &&
			(!hasClear ||
				(clearChoice != "species" && clearChoice != "job")) {
			m.notice = fmt.Sprintf("Input policy returned invalid choice clear %v.", value)

			return nil
		}

		if returnable {
			m.openReturnableScreen(screen)
		} else {
			m.openScreen(screen)
		}

		if screen == ScreenDrop {
			m.dropQuantity = ""
		}

		if hasQuantity {
			m.dropQuantity = quantity
		}

		if hasNotice {
			m.notice = message
		}

		if hasFocus {
			m.focus = int(focus)
		}

		if hasClear {
			if clearChoice == "species" {
				m.speciesID = ""
			} else {
				m.jobID = ""
			}
		}

	}

	return nil
}

func (m *AppModel) canEnterInputScreen(screen ScreenID) bool {
	switch screen {
	case ScreenStartup, ScreenSpecies, ScreenBackground, ScreenWeapon,
		ScreenName:
		return m.game == nil

	case ScreenHelp:
		return true

	default:
		return m.game != nil
	}
}
