package terminal

import (
	"fmt"
	"strings"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/script"
	"github.com/mattn/go-runewidth"
)

func (m *AppModel) drawStartup(canvas *Canvas) {
	welcome := "Hello, welcome to Dungeon Crawl Stone Soup " +
		m.presentation.SourceVersion + "!"
	canvas.Write(0, 0, welcome, Yellow, Black)

	copyright := "(c) Copyright 1997-2002 Linley Henzell, 2002-2022 Crawl DevTeam"
	canvas.Write(0, 1, copyright, Brown, Black)
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
		description := m.presentation.StartupModes[m.focus].Description

		writeClipped(canvas, 1, 20, m.width-2, description, Brown)
	}

	status := "Rules: bundled "
	changes := m.rules.Changes()

	if !m.rules.Vanilla() {
		status = "Rules: modified "

		if len(changes) > 0 {
			changed := "Changed Lua: " + changes[0]

			if len(changes) > 1 {
				changed += fmt.Sprintf(" (+%d more)", len(changes)-1)
			}

			writeClipped(canvas, 1, 21, m.width-2, changed, Brown)
		}
	}

	writeClipped(
		canvas,
		1,
		22,
		m.width-2,
		status+m.rules.Hash()[:12],
		LightGrey,
	)

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
	m.drawCharacterGroups(canvas, groups)
	m.drawCharacterChoiceHints(canvas)

	ids := flattenGroups(groups)

	if m.focus < len(ids) {
		description := descriptions[ids[m.focus]]
		wrapped := strings.Join(strings.Fields(description), " ")

		writeWrapped(canvas, 1, 19, m.width-2, 4, wrapped, Brown)
	}

	if m.notice != "" {
		writeClipped(canvas, 1, 23, m.width-2, m.notice, LightRed)
	}
}

func (m *AppModel) drawCharacterGroups(canvas *Canvas, groups []content.MenuGroup) {
	pageStart, _, visible := characterChoicePage(groups, m.focus, m.screen)
	index := pageStart

	for column, group := range visible {
		col, row := groupPosition(m.screen, column)
		canvas.Write(col, row, group.Label, LightBlue, Black)

		for offset, id := range group.IDs {
			name := m.characterChoiceName(id)
			color, background := m.characterChoiceColors(id, index)
			label := fmt.Sprintf("%c - %s", menuLetter(index-pageStart), name)

			canvas.Write(col, row+offset+1, label, color, background)
			index++
		}
	}
}

// Source groups keep their DCSS positions. Added choices use subsequent pages
// with the same column geometry so the 79x24 minimum remains usable.
func characterChoicePage(
	groups []content.MenuGroup,
	focus int,
	screen ScreenID,
) (int, int, []content.MenuGroup) {
	baseGroups := 3
	pageSize := 27
	columnCapacity := []int{
		9,
		9,
		9,
	}

	if screen == ScreenBackground {
		baseGroups = 5
		pageSize = 25
		columnCapacity = []int{
			5,
			4,
			4,
			5,
			7,
		}
	}

	if len(groups) <= baseGroups {
		return 0, len(flattenGroups(groups)), groups
	}

	base := groups[:baseGroups]
	baseCount := len(flattenGroups(base))

	if focus < baseCount {
		return 0, baseCount, base
	}

	added := flattenGroups(groups[baseGroups:])
	page := (focus - baseCount) / pageSize
	first := page * pageSize
	last := min(first+pageSize, len(added))
	visible := make([]content.MenuGroup, 0, baseGroups)

	column := first

	for _, capacity := range columnCapacity {
		if column >= last {
			break
		}

		end := min(column+capacity, last)
		label := ""

		if column == first {
			label = "Modded choices"
		}

		visible = append(visible, content.MenuGroup{
			Label: label,
			IDs:   added[column:end],
		})

		column = end
	}

	return baseCount + first, baseCount + last, visible
}

func (m *AppModel) characterChoiceName(id string) string {
	if m.screen == ScreenSpecies {
		if definition, err := m.catalog.Species(id); err == nil {
			return definition.Name
		}

		return id
	}

	if definition, err := m.catalog.Job(id); err == nil {
		return definition.Name
	}

	return id
}

func (m *AppModel) characterChoiceColors(id string, index int) (Color, Color) {
	color := LightGrey
	background := Black

	status := "restricted"
	hasOtherChoice := false
	available := false

	if m.screen == ScreenSpecies {
		available = m.hasPlayableChoice(id, m.jobID, false)
		hasOtherChoice = m.jobID != ""

		if hasOtherChoice {
			status = m.choices[script.ChoiceKey{
				SpeciesID:    id,
				JobID:        m.jobID,
				SpeciesFirst: false,
			}].Restriction
		}
	} else {
		available = m.hasPlayableChoice(m.speciesID, id, true)
		hasOtherChoice = m.speciesID != ""

		if hasOtherChoice {
			status = m.choices[script.ChoiceKey{
				SpeciesID:    m.speciesID,
				JobID:        id,
				SpeciesFirst: true,
			}].Restriction
		}
	}

	if !available {
		color = DarkGrey
	} else if hasOtherChoice && status == "recommended" {
		color = White
	}

	if index != m.focus {
		return color, background
	}

	color = White

	if !available {
		background = DarkGrey
	} else if status == "recommended" && hasOtherChoice {
		background = Green
	} else if hasOtherChoice {
		background = LightGrey
	} else {
		background = Blue
	}

	return color, background
}

func (m *AppModel) drawCharacterChoiceHints(canvas *Canvas) {
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

	species, _ := m.catalog.Species(m.speciesID)

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

		label := fmt.Sprintf("%c - %-18s (%+d apt)", menuLetter(i), option.Name, aptitude)

		canvas.Write(2, 3+i, label, color, background)
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

	if m.speciesID != "" {
		if named {
			who += " the"
		}

		species, _ := m.catalog.Species(m.speciesID)
		who += " " + species.Name
	}

	if m.jobID == "JOB_FIGHTER" {
		who += " Fighter"
	}

	return "Welcome, " + who + "."
}
