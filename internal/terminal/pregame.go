package terminal

import (
	"fmt"
	"strings"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/script"
	"github.com/mattn/go-runewidth"
)

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

func (m *AppModel) appendNameCharacter(value string) {
	if len([]rune(value)) != 1 {
		return
	}

	if value == " " && m.name == "" {
		return
	}

	candidate := m.name + value

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

		return choice.Playable && m.supportedStarts[script.ChoiceKey{
			SpeciesID: speciesID,
			JobID:     jobID,
		}]
	}

	if speciesID == "" {
		for _, candidate := range m.presentation.SpeciesIDs() {
			if m.hasPlayableChoice(candidate, jobID, speciesFirst) {
				return true
			}
		}

		return false
	}

	for _, candidate := range m.presentation.JobIDs() {
		if m.hasPlayableChoice(speciesID, candidate, speciesFirst) {
			return true
		}
	}

	return false
}

func (m *AppModel) enterWeaponChoice() {
	result, err := m.presentationPolicy("character.weapon_options", map[string]any{
		"species_id": m.speciesID,
		"job_id":     m.jobID,
	})

	if err != nil {
		m.notice = fmt.Sprintf("Weapon choices failed: %v", err)

		return
	}

	rows := policyRows(result["options"])
	options := make([]menuWeaponOption, 0, len(rows))

	for _, raw := range rows {
		option := policyRecord(raw)
		options = append(options, menuWeaponOption{
			ID:          option["id"].(string),
			Name:        option["name"].(string),
			Restriction: option["restriction"].(string),
		})
	}

	m.weaponReturn = m.screen
	m.options = options

	m.screen = ScreenWeapon
	m.focus = 0
}

func projectSupportedStarts(
	runtime *script.Runtime,
	presentation script.MenuPresentation,
) (map[script.ChoiceKey]bool, error) {
	pairs := make([]any, 0)
	keys := make([]script.ChoiceKey, 0)

	for _, speciesID := range presentation.SpeciesIDs() {
		for _, jobID := range presentation.JobIDs() {
			keys = append(keys, script.ChoiceKey{
				SpeciesID: speciesID,
				JobID:     jobID,
			})

			pairs = append(pairs, map[string]any{
				"species_id": speciesID,
				"job_id":     jobID,
			})
		}
	}

	result, err := runtime.Policy("character.supported_starts", map[string]any{
		"pairs": pairs,
	})

	if err != nil {
		return nil, err
	}

	rows := policyRows(result["supported"])

	if len(rows) != len(keys) {
		return nil, fmt.Errorf("Lua start support returned %d choices for %d pairs", len(rows), len(keys))
	}

	supported := make(map[script.ChoiceKey]bool, len(keys))

	for index, key := range keys {
		value, ok := rows[index].(bool)

		if !ok {
			return nil, fmt.Errorf("Lua start support %d has type %T", index, rows[index])
		}

		supported[key] = value
	}

	return supported, nil
}

func (m *AppModel) startGame() {
	started, err := game.NewDungeonGameWithRules(
		m.seed,
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

func flattenGroups(groups []script.MenuGroup) []string {
	var ids []string

	for _, group := range groups {
		ids = append(ids, group.IDs...)
	}

	return ids
}
