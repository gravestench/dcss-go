package terminal

import (
	"fmt"
	"strings"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
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

			return nil
		}

		if m.focus == 0 {
			if m.name != "" {
				if err := character.ValidateName(m.name); err != nil {
					m.notice = err.Error()

					return nil
				}
			}

			m.screen = ScreenSpecies
			m.focus = 0
			m.notice = ""
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
		key = string(menuLetter(m.focus))
	case "+", "#", "%", "*", "!":
		m.notice = "This character option is unavailable in the Go port."

		return
	}

	for i, id := range ids {
		if key != string(menuLetter(i)) {
			continue
		}

		m.focus = i

		if m.screen == ScreenSpecies {
			if id != "SP_HUMAN" {
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
		} else {
			if id != "JOB_FIGHTER" {
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
		}

		m.enterWeaponChoice()

		return
	}
}

func (m *AppModel) enterWeaponChoice() {
	options, err := character.WeaponOptions(m.catalog, m.speciesID, m.jobID)

	if err != nil {
		m.notice = fmt.Sprintf("Weapon choices failed: %v", err)

		return
	}

	m.weaponReturn = m.screen
	m.screen = ScreenWeapon
	m.focus = 0
	m.options = options
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
	started, err := game.NewDungeonGame(m.seed, m.catalog, m.weaponID, strings.TrimSpace(m.name))

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

func (m *AppModel) drawStartup(canvas *Canvas) {
	canvas.Write(0, 0, "Hello, welcome to Dungeon Crawl Stone Soup "+m.presentation.SourceVersion+"!", Yellow, Black)
	canvas.Write(0, 1, "(c) Copyright 1997-2002 Linley Henzell, 2002-2022 Crawl DevTeam", Brown, Black)
	canvas.Write(1, 3, "Enter your name: "+m.name, LightGrey, Black)
	canvas.Write(1, 5, "Choices:", LightGrey, Black)

	for i, mode := range m.presentation.StartupModes {
		color := LightGrey

		if i == m.focus {
			color = White
		}

		canvas.Write(2, 6+i, mode.Label, color, Black)
	}

	if m.savedRunExists() {
		canvas.Write(1, 15, "Saved games:", LightGrey, Black)
		canvas.Write(2, 16, "Continue saved game", White, Black)
	}

	canvas.Write(1, 18, "[ctrl-p] view rc file information and log", LightGrey, Black)

	if m.focus < len(m.presentation.StartupModes) {
		writeClipped(canvas, 1, 20, m.width-2, m.presentation.StartupModes[m.focus].Description, Brown)
	}

	if m.notice != "" {
		writeClipped(canvas, 1, 23, m.width-2, m.notice, LightRed)
	}
}

func (m *AppModel) drawCharacterChoice(canvas *Canvas) {
	groups := m.presentation.SpeciesGroups
	descriptions := m.presentation.SpeciesDescriptions
	choice := "species"

	if m.screen == ScreenBackground {
		groups = m.presentation.JobGroups
		descriptions = m.presentation.JobDescriptions
		choice = "background"
	}

	canvas.Write(0, 0, m.welcomeText(), Brown, Black)
	canvas.Write(1, 1, "Please select your "+choice+".", LightGrey, Black)
	index := 0

	for column, group := range groups {
		col, row := groupPosition(m.screen, column)
		canvas.Write(col, row, group.Label, LightBlue, Black)

		for i, id := range group.IDs {
			name := id

			if m.screen == ScreenSpecies {
				if definition, err := m.catalog.Species(id); err == nil {
					name = definition.Name
				}
			} else {
				if definition, err := m.catalog.Job(id); err == nil {
					name = definition.Name
				}
			}

			color, background := LightGrey, Black
			status := character.Restricted

			if m.screen == ScreenSpecies && m.jobID != "" {
				status, _ = character.SpeciesForJob(m.catalog, id, m.jobID)
			} else if m.screen == ScreenBackground && m.speciesID != "" {
				status, _ = character.JobForSpecies(m.catalog, m.speciesID, id)
			}

			hasOtherChoice := (m.screen == ScreenSpecies && m.jobID != "") ||
				(m.screen == ScreenBackground && m.speciesID != "")

			if hasOtherChoice {
				if status == character.Recommended {
					color = White
				} else {
					color = DarkGrey
				}
			}

			if index == m.focus {
				color = White

				if status == character.Recommended && hasOtherChoice {
					background = Green
				} else if hasOtherChoice {
					background = LightGrey
				} else {
					background = Blue
				}
			}

			canvas.Write(col, row+i+1, fmt.Sprintf("%c - %s", menuLetter(index), name), color, background)
			index++
		}
	}

	choiceTitle, otherTitle := "species", "background"
	otherSelected := m.jobID != ""

	if m.screen == ScreenBackground {
		choiceTitle, otherTitle = "background", "species"
		otherSelected = m.speciesID != ""
	}

	for row, label := range []string{
		"+ - Recommended " + choiceTitle,
		"# - Recommended character",
		"% - List aptitudes",
		"? - Help",
	} {
		canvas.Write(1, 14+row, label, LightGrey, Black)
	}

	change := "Space - Pick " + otherTitle + " first"

	if otherSelected {
		change = "Space - Change " + otherTitle
	}

	for row, label := range []string{
		"    * - Random " + choiceTitle,
		"    ! - Random character",
		change,
	} {
		canvas.Write(40, 14+row, label, LightGrey, Black)
	}

	ids := flattenGroups(groups)

	if m.focus < len(ids) {
		writeWrapped(canvas, 1, 19, m.width-2, 4, strings.Join(strings.Fields(descriptions[ids[m.focus]]), " "), Brown)
	}

	if m.notice != "" {
		writeClipped(canvas, 1, 23, m.width-2, m.notice, LightRed)
	}
}

func groupPosition(screen ScreenID, group int) (int, int) {
	if screen == ScreenSpecies {
		return 1 + group*26, 3
	}

	switch group {
	case 0:
		return 1, 3
	case 1:
		return 1, 9
	case 2:
		return 27, 3
	case 3:
		return 27, 8
	default:
		return 53, 3
	}
}

func writeWrapped(canvas *Canvas, x, y, width, height int, value string, color Color) {
	words := strings.Fields(value)
	line, row := "", 0

	for _, word := range words {
		candidate := word

		if line != "" {
			candidate = line + " " + word
		}

		if runewidth.StringWidth(candidate) > width && line != "" {
			if row >= height {
				return
			}

			writeClipped(canvas, x, y+row, width, line, color)
			row++
			line = word
		} else {
			line = candidate
		}
	}

	if row < height {
		writeClipped(canvas, x, y+row, width, line, color)
	}
}

func (m *AppModel) drawWeapon(canvas *Canvas) {
	canvas.Write(0, 0, m.welcomeText(), Brown, Black)
	canvas.Write(1, 1, "Please select your starting weapon.", LightGrey, Black)

	species, _ := m.catalog.Species("SP_HUMAN")

	for i, option := range m.options {
		aptitude := species.Aptitudes["SK_UNARMED_COMBAT"].Value

		if option.ID != "WPN_UNARMED" {
			if item, err := m.catalog.Item(option.ID); err == nil {
				aptitude = species.Aptitudes[item.WeaponSkill].Value
			}
		}

		color, background := DarkGrey, Black

		if option.Restriction == character.Recommended {
			color = White
		}

		if i == m.focus {
			color = White

			if option.Restriction == character.Recommended {
				background = Green
			} else {
				background = LightGrey
			}
		}

		canvas.Write(2, 3+i, fmt.Sprintf("%c - %-18s (%+d apt)", menuLetter(i), option.Name, aptitude), color, background)
	}

	canvas.Write(1, 11, "+ - Recommended random choice     * - Random weapon", LightGrey, Black)
	canvas.Write(1, 12, "% - List aptitudes               ? - Help", LightGrey, Black)
	canvas.Write(1, 13, "Bksp - Return to character menu", LightGrey, Black)

	if m.notice != "" {
		writeClipped(canvas, 1, 23, m.width-2, m.notice, LightRed)
	}
}

func (m *AppModel) drawName(canvas *Canvas) {
	canvas.Write(0, 0, m.welcomeText(), Brown, Black)
	canvas.Write(1, 2, "Enter your name: "+m.name, LightGrey, Black)

	if m.notice != "" {
		writeClipped(canvas, 1, 23, m.width-2, m.notice, LightRed)
	}
}

func (m *AppModel) welcomeText() string {
	who := m.name
	named := who != ""

	if who == "" {
		if m.speciesID == "" && m.jobID == "" {
			return "Welcome."
		}

		who = "unnamed"
	}

	if m.speciesID == "SP_HUMAN" {
		if named {
			who += " the"
		}

		who += " Human"
	}

	if m.jobID == "JOB_FIGHTER" {
		who += " Fighter"
	}

	return "Welcome, " + who + "."
}
