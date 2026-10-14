package terminal

import (
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/script"
	"github.com/mattn/go-runewidth"
)

func (m *AppModel) drawStartup(canvas *Canvas) {
	m.drawPregame(canvas, "startup")
}

func (m *AppModel) drawCharacterChoice(canvas *Canvas) {
	if m.screen == ScreenSpecies {
		m.drawPregame(canvas, "species")

		return
	}

	m.drawPregame(canvas, "background")
}

func (m *AppModel) drawWeapon(canvas *Canvas) {
	m.drawPregame(canvas, "weapon")
}

func (m *AppModel) drawName(canvas *Canvas) {
	m.drawPregame(canvas, "name")
}

func (m *AppModel) drawPregame(canvas *Canvas, screen string) {
	options := make([]any, 0, len(m.options))

	for _, option := range m.options {
		options = append(options, map[string]any{
			"id":          option.ID,
			"name":        option.Name,
			"restriction": option.Restriction,
		})
	}

	choices := make(map[string]any)

	if screen == "species" || screen == "background" {
		groups := m.presentation.SpeciesGroups

		if screen == "background" {
			groups = m.presentation.JobGroups
		}

		for _, id := range flattenGroups(groups) {
			status, _ := m.characterChoiceStatus(id)

			choices[id] = map[string]any{
				"available":   status.available,
				"restriction": status.restriction,
			}
		}
	}

	result := runPresentation(m.presentationPolicy, "presentation.pregame", map[string]any{
		"screen":     screen,
		"name":       m.name,
		"species_id": m.speciesID,
		"job_id":     m.jobID,
		"focus":      m.focus,
		"width":      m.width,
		"notice":     m.notice,
		"saved_run":  m.savedRunExists(),
		"vanilla":    m.rules.Vanilla(),
		"rules_hash": m.rules.Hash(),
		"changes":    m.rules.Changes(),
		"options":    options,
		"choices":    choices,
	})

	drawPresentation(canvas, fullRegion(canvas), result)
}

type choiceStatus struct {
	available   bool
	restriction string
}

func (m *AppModel) characterChoiceStatus(id string) (choiceStatus, bool) {
	if m.screen == ScreenSpecies {
		hasOther := m.jobID != ""
		status := choiceStatus{available: m.hasPlayableChoice(id, m.jobID, false)}

		if hasOther {
			status.restriction = m.choices[script.ChoiceKey{
				SpeciesID:    id,
				JobID:        m.jobID,
				SpeciesFirst: false,
			}].Restriction
		}

		return status, hasOther
	}

	hasOther := m.speciesID != ""
	status := choiceStatus{available: m.hasPlayableChoice(m.speciesID, id, true)}

	if hasOther {
		status.restriction = m.choices[script.ChoiceKey{
			SpeciesID:    m.speciesID,
			JobID:        id,
			SpeciesFirst: true,
		}].Restriction
	}

	return status, hasOther
}

func (m *AppModel) characterChoiceColors(id string, index int) (Color, Color) {
	status, hasOther := m.characterChoiceStatus(id)
	result := runPresentation(m.presentationPolicy, "presentation.choice_color", map[string]any{
		"choice": map[string]any{
			"available":   status.available,
			"restriction": status.restriction,
		},
		"focused":   index == m.focus,
		"has_other": hasOther,
	})

	return policyColor(result["fg"]), policyColor(result["bg"])
}

func (m *AppModel) welcomeText() string {
	result := runPresentation(m.presentationPolicy, "presentation.welcome", map[string]any{
		"name":       m.name,
		"species_id": m.speciesID,
		"job_id":     m.jobID,
	})

	return result["text"].(string)
}

// The menu input handler uses the same page geometry as the Lua presentation policy.
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
