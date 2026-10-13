package terminal

import (
	"fmt"
	"strconv"
	"strings"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
)

// StartModel owns the pregame choice and delegates to Model after a run exists.
type StartModel struct {
	catalog       content.Catalog
	seed          uint64
	savePath      string
	options       []character.WeaponOption
	play          *Model
	width, height int
	notice        string
}

func NewStartModel(catalog content.Catalog, seed uint64, savePath string) (*StartModel, error) {
	player := catalog.Player()
	options, err := character.WeaponOptions(catalog, player.SpeciesID, player.JobID)
	if err != nil {
		return nil, err
	}
	if len(options) == 0 || len(options) > 9 {
		return nil, fmt.Errorf("Human/Fighter has no displayable weapon choices")
	}
	return &StartModel{catalog: catalog, seed: seed, savePath: savePath, options: options, width: 80, height: 24}, nil
}

func (m *StartModel) Init() tea.Cmd { return nil }

func (m *StartModel) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	if m.play != nil {
		_, command := m.play.Update(message)
		return m, command
	}
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
	case tea.KeyPressMsg:
		key := msg.String()
		switch key {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "L":
			snapshot, err := save.Read(m.savePath)
			if err == nil {
				var restored *game.Game
				restored, err = game.Restore(snapshot, m.catalog)
				if err == nil {
					m.play = NewModel(restored, m.savePath)
					m.play.width, m.play.height = m.width, m.height
					return m, nil
				}
			}
			m.notice = fmt.Sprintf("Load failed: %v", err)
			return m, nil
		}
		index, err := strconv.Atoi(key)
		if err != nil || index < 1 || index > len(m.options) {
			return m, nil
		}
		player := m.catalog.Player()
		weaponID := m.options[index-1].ID
		if err := character.ValidateWeaponChoice(m.catalog, player.SpeciesID, player.JobID, weaponID); err != nil {
			m.notice = fmt.Sprintf("Start failed: %v", err)
			return m, nil
		}
		started, err := game.NewScenario(m.seed, m.catalog, weaponID)
		if err != nil {
			m.notice = fmt.Sprintf("Start failed: %v", err)
			return m, nil
		}
		m.play = NewModel(started, m.savePath)
		m.play.width, m.play.height = m.width, m.height
	}
	return m, nil
}

func (m *StartModel) View() tea.View {
	if m.play != nil {
		return m.play.View()
	}
	header := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6")).Render("DCrawl · Human Fighter")
	lines := []string{header, "Choose a starting weapon:"}
	for i, option := range m.options {
		row := fmt.Sprintf("%d. %s", i+1, option.Name)
		if option.Restriction == character.Recommended {
			row += " (recommended)"
		}
		lines = append(lines, row)
	}
	lines = append(lines, "1-6 choose · L load · q quit")
	if m.notice != "" {
		lines = append(lines, m.notice)
	}
	if m.height > 0 && len(lines) > m.height {
		lines = lines[:m.height]
	}
	return tea.NewView(strings.Join(lines, "\n"))
}

func (m *StartModel) Close() error {
	if m.play != nil {
		return m.play.Close()
	}
	return nil
}
