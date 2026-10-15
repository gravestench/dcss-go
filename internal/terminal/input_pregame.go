package terminal

import (
	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/character"
)

func (m *AppModel) routePregameInput(screen, key string) tea.Cmd {
	input := map[string]any{
		"focus": m.focus,
		"name":  m.name,
	}

	switch screen {
	case "startup":
		count := len(m.presentation.StartupModes)
		saved := m.savedRunExists()

		if saved {
			count++
		}

		input["mode_count"] = count
		input["saved_run"] = saved

	case "species", "background":
		groups := m.presentation.SpeciesGroups

		if screen == "background" {
			groups = m.presentation.JobGroups
		}

		ids := flattenGroups(groups)
		values := make([]any, 0, len(ids))

		for _, id := range ids {
			values = append(values, id)
		}

		start, end, _ := characterChoicePage(groups, m.focus, m.screen)

		input["ids"] = values
		input["page_start"] = start
		input["page_end"] = end

	case "weapon":
		optionCount := len(m.options)
		options := make([]any, 0, optionCount)

		for _, option := range m.options {
			options = append(options, map[string]any{
				"id": option.ID,
			})
		}

		input["options"] = options
	}

	return m.routeInput(screen, key, input)
}

func (m *AppModel) applyPregameDecision(action string, decision map[string]any) tea.Cmd {
	if m.game != nil {
		m.notice = "Input policy requested a character action during play."

		return nil
	}

	switch action {
	case "focus":
		index, ok := decision["index"].(int64)

		if !ok ||
			index < 0 ||
			index >= int64(m.focusCountFor(m.screen)) {
			m.notice = "Input policy returned invalid focus."

			return nil
		}

		m.focus = int(index)

	case "quit":
		return tea.Quit

	case "load_saved":
		m.loadSavedRun()

		if m.game != nil && m.game.View().EquipmentDelay != nil {
			return m.nextEquipmentTick()
		}

	case "start_new":
		m.startNewCharacter()

	case "name_edit":
		m.applyNameEdit(decision)

	case "select_choice":
		m.applyChoiceSelection(decision)

	case "select_weapon":
		m.applyWeaponSelection(decision)

	case "return_weapon":
		m.screen = m.weaponReturn
		m.focus = 0
		m.notice = ""

	case "start_game":
		if err := character.ValidateName(m.name); err != nil {
			m.notice = err.Error()

			return nil
		}

		m.startGame()
	}

	return nil
}

func (m *AppModel) focusCountFor(screen ScreenID) int {
	switch screen {
	case ScreenStartup:
		count := len(m.presentation.StartupModes)

		if m.savedRunExists() {
			count++
		}

		return count

	case ScreenSpecies:
		return len(flattenGroups(m.presentation.SpeciesGroups))

	case ScreenBackground:
		return len(flattenGroups(m.presentation.JobGroups))

	case ScreenWeapon:
		return len(m.options)
	}

	return 0
}

func (m *AppModel) applyNameEdit(decision map[string]any) {
	operation, ok := decision["operation"].(string)

	if !ok {
		m.notice = "Input policy returned an invalid name edit."

		return
	}

	switch operation {
	case "backspace":
		if len(m.name) > 0 {
			runes := []rune(m.name)

			m.name = string(runes[:len(runes)-1])
		}

	case "clear":
		m.name = ""

	case "append":
		value, ok := decision["value"].(string)

		if !ok {
			m.notice = "Input policy returned an invalid name character."

			return
		}

		m.appendNameCharacter(value)

	default:
		m.notice = "Input policy returned an unsupported name edit."
	}
}

func (m *AppModel) applyChoiceSelection(decision map[string]any) {
	id, named := decision["id"].(string)
	index, indexed := decision["index"].(int64)
	groups := m.presentation.SpeciesGroups

	if m.screen == ScreenBackground {
		groups = m.presentation.JobGroups
	}

	ids := flattenGroups(groups)

	if !named ||
		!indexed ||
		index < 0 ||
		index >= int64(len(ids)) ||
		ids[index] != id {
		m.notice = "Input policy returned an invalid character choice."

		return
	}

	m.focus = int(index)

	if m.screen == ScreenSpecies {
		m.selectSpecies(id)
	} else {
		m.selectBackground(id)
	}
}

func (m *AppModel) applyWeaponSelection(decision map[string]any) {
	id, named := decision["id"].(string)
	index, indexed := decision["index"].(int64)

	if !named ||
		!indexed ||
		index < 0 ||
		index >= int64(len(m.options)) ||
		m.options[index].ID != id {
		m.notice = "Input policy returned an invalid weapon choice."

		return
	}

	m.weaponID = id
	m.focus = int(index)
	m.notice = ""

	if m.name == "" {
		m.screen = ScreenName

		return
	}

	m.startGame()
}
