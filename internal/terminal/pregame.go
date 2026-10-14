package terminal

import (
	"fmt"
	"strings"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/script"
	"github.com/mattn/go-runewidth"
)

func (m *AppModel) handleStartupKey(key string) tea.Cmd {
	count := len(m.presentation.StartupModes)

	if m.savedRunExists() {
		count++
	}

	switch key {
	case "esc":
		return tea.Quit

	case "up":
		m.focus = (m.focus - 1 + count) % count

	case "down":
		m.focus = (m.focus + 1) % count

	case "enter":
		if m.focus == len(m.presentation.StartupModes) && m.savedRunExists() {
			m.loadSavedRun()

			if m.game != nil && m.game.View().EquipmentDelay != nil {
				return m.nextEquipmentTick()
			}

			return nil
		}

		if m.focus == 0 {
			m.startNewCharacter()
		} else {
			m.notice = "This game mode is unavailable in the Go port."
		}

	case "backspace":
		if len(m.name) > 0 {
			runes := []rune(m.name)

			m.name = string(runes[:len(runes)-1])
		}

	case "ctrl+u":
		m.name = ""

	case "ctrl+p":
		m.notice = "RC file information is unavailable in the Go port."

	case "?":
		m.previous = m.screen
		m.screen = ScreenHelp

	default:
		m.appendNameKey(key)
	}

	return nil
}

func (m *AppModel) startNewCharacter() {
	if m.name != "" {
		if err := character.ValidateName(m.name); err != nil {
			m.notice = err.Error()

			return
		}
	}

	m.screen = ScreenSpecies
	m.focus = 0
	m.notice = ""
}

func (m *AppModel) appendNameKey(key string) {
	if key == "space" {
		key = " "
	}

	if len([]rune(key)) != 1 {
		return
	}

	if key == " " && m.name == "" {
		return
	}

	candidate := m.name + key

	if runewidth.StringWidth(candidate) > 30 {
		m.notice = "Name exceeds 30 display columns"

		return
	}

	// A partial name may have trailing space, but it must still be source-valid.
	if err := character.ValidateName(candidate); err != nil {
		m.notice = "invalid name character"

		return
	}

	m.name = candidate
	m.notice = ""
}

func (m *AppModel) handleCharacterChoiceKey(key string) {
	groups := m.presentation.SpeciesGroups

	if m.screen == ScreenBackground {
		groups = m.presentation.JobGroups
	}

	ids := flattenGroups(groups)

	if len(ids) == 0 {
		m.notice = "No character choices are available in this ruleset."

		return
	}

	switch key {
	case "esc":
		m.screen = ScreenStartup
		m.focus = 0
		m.notice = ""

		return

	case "backspace":
		if m.screen == ScreenBackground {
			m.jobID = ""
			m.screen = ScreenSpecies
		} else {
			m.speciesID = ""
			m.screen = ScreenBackground
		}

		m.focus = 0
		m.notice = ""

		return

	case "space":
		if m.screen == ScreenSpecies {
			m.screen = ScreenBackground
		} else {
			m.screen = ScreenSpecies
		}

		m.focus = 0
		m.notice = ""

		return

	case "up":
		m.focus = (m.focus - 1 + len(ids)) % len(ids)

		return

	case "down":
		m.focus = (m.focus + 1) % len(ids)

		return

	case "left":
		m.focus = (m.focus - 9 + len(ids)) % len(ids)

		return

	case "right":
		m.focus = (m.focus + 9) % len(ids)

		return

	case "?":
		m.previous = m.screen
		m.screen = ScreenHelp

		return

	case "enter":
		start, _, _ := characterChoicePage(groups, m.focus, m.screen)
		key = string(menuLetter(m.focus - start))

	case "+", "#", "%", "*", "!":
		m.notice = "This character option is unavailable in the Go port."

		return
	}

	m.selectCharacterChoice(key, ids)
}

func (m *AppModel) selectCharacterChoice(key string, ids []string) {
	groups := m.presentation.SpeciesGroups

	if m.screen == ScreenBackground {
		groups = m.presentation.JobGroups
	}

	start, end, _ := characterChoicePage(groups, m.focus, m.screen)

	for index := start; index < end; index++ {
		if key != string(menuLetter(index-start)) {
			continue
		}

		id := ids[index]

		m.focus = index

		if m.screen == ScreenSpecies {
			m.selectSpecies(id)
		} else {
			m.selectBackground(id)
		}

		return
	}
}

func (m *AppModel) selectSpecies(id string) {
	if !m.hasPlayableChoice(id, m.jobID, false) {
		m.notice = "This species is unavailable in the Go port."

		return
	}

	m.speciesID = id
	m.notice = ""

	if m.jobID == "" {
		m.screen = ScreenBackground
		m.focus = 0

		return
	}

	m.enterWeaponChoice()
}

func (m *AppModel) selectBackground(id string) {
	if !m.hasPlayableChoice(m.speciesID, id, true) {
		m.notice = "This background is unavailable in the Go port."

		return
	}

	m.jobID = id
	m.notice = ""

	if m.speciesID == "" {
		m.screen = ScreenSpecies
		m.focus = 0

		return
	}

	m.enterWeaponChoice()
}

func (m *AppModel) hasPlayableChoice(
	speciesID, jobID string,
	speciesFirst bool,
) bool {
	if speciesID != "" && jobID != "" {
		choice := m.choices[script.ChoiceKey{
			SpeciesID:    speciesID,
			JobID:        jobID,
			SpeciesFirst: speciesFirst,
		}]

		return choice.Playable && character.SupportedFighterStart(
			speciesID, jobID,
		)
	}

	if speciesID == "" {
		for _, candidate := range m.catalog.SpeciesIDs() {
			if m.hasPlayableChoice(candidate, jobID, speciesFirst) {
				return true
			}
		}

		return false
	}

	for _, candidate := range m.catalog.JobIDs() {
		if m.hasPlayableChoice(speciesID, candidate, speciesFirst) {
			return true
		}
	}

	return false
}

func (m *AppModel) enterWeaponChoice() {
	options, err := character.WeaponOptions(m.catalog, m.speciesID, m.jobID)

	if err != nil {
		m.notice = fmt.Sprintf("Weapon choices failed: %v", err)

		return
	}

	m.weaponReturn = m.screen
	m.options = options

	m.screen = ScreenWeapon
	m.focus = 0
}

func (m *AppModel) handleWeaponKey(key string) {
	switch key {
	case "esc", "backspace":
		m.screen = m.weaponReturn
		m.focus = 0
		m.notice = ""

		return

	case "up":
		m.focus = (m.focus - 1 + len(m.options)) % len(m.options)

		return

	case "down":
		m.focus = (m.focus + 1) % len(m.options)

		return

	case "?":
		m.previous = m.screen
		m.screen = ScreenHelp

		return

	case "enter":
		key = string(menuLetter(m.focus))

	case "+", "*", "%":
		m.notice = "This weapon option is unavailable in the Go port."

		return
	}

	for i, option := range m.options {
		if key != string(menuLetter(i)) {
			continue
		}

		m.weaponID = option.ID
		m.focus = i

		m.notice = ""

		if m.name == "" {
			m.screen = ScreenName

			return
		}

		m.startGame()

		return
	}
}

func (m *AppModel) handleNameKey(key string) {
	switch key {
	case "esc":
		m.screen = ScreenWeapon
		m.notice = ""

		return

	case "backspace":
		if len(m.name) > 0 {
			runes := []rune(m.name)

			m.name = string(runes[:len(runes)-1])
		}

	case "enter":
		if err := character.ValidateName(m.name); err != nil {
			m.notice = err.Error()

			return
		}

		m.startGame()

	default:
		m.appendNameKey(key)
	}
}

func (m *AppModel) startGame() {
	started, err := game.NewDungeonGameWithRules(
		m.seed,
		m.catalog,
		m.speciesID,
		m.jobID,
		m.weaponID,
		strings.TrimSpace(m.name),
		m.rules,
	)

	if err != nil {
		m.notice = fmt.Sprintf("Start failed: %v", err)

		return
	}

	m.game = started

	m.screen = ScreenPlay
	m.notice = ""
}

func flattenGroups(groups []content.MenuGroup) []string {
	var ids []string

	for _, group := range groups {
		ids = append(ids, group.IDs...)
	}

	return ids
}

func menuLetter(index int) rune {
	if index < 26 {
		return rune('a' + index)
	}

	return rune('A' + index - 26)
}
