package terminal

import (
	"fmt"
	"strings"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
)

type Model struct {
	game          *game.Game
	savePath      string
	width, height int
	showInventory bool
	showCharacter bool
	notice        string
}

func NewModel(g *game.Game, savePath string) *Model {
	return &Model{game: g, savePath: savePath, width: 80, height: 24}
}

func (m *Model) Init() tea.Cmd { return nil }

func (m *Model) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := message.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
	case tea.KeyPressMsg:
		key := msg.String()
		switch key {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "i":
			m.showInventory = !m.showInventory
			if m.showInventory {
				m.showCharacter = false
			}
			return m, nil
		case "c":
			m.showCharacter = !m.showCharacter
			if m.showCharacter {
				m.showInventory = false
			}
			return m, nil
		case "S":
			if err := save.Write(m.savePath, m.game.Snapshot()); err != nil {
				m.notice = fmt.Sprintf("Save failed: %v", err)
			} else {
				m.notice = "Game saved."
			}
			return m, nil
		case "L":
			snapshot, err := save.Read(m.savePath)
			if err == nil {
				// The restored game is separate until it has passed all validation.
				replacement, restoreErr := m.game.Restore(snapshot)
				if restoreErr == nil {
					old := m.game
					m.game = replacement
					_ = old.Close()
					m.notice = "Game loaded."
					return m, nil
				}
				err = restoreErr
			}
			m.notice = fmt.Sprintf("Load failed: %v", err)
			return m, nil
		}
		if command, ok := CommandForKey(key); ok {
			_, err := m.game.Step(command)
			if err != nil {
				m.notice = fmt.Sprintf("Action failed: %v", err)
			} else {
				m.notice = ""
			}
		}
	}
	return m, nil
}

func (m *Model) View() tea.View {
	view := m.game.View()
	result := Render(view, m.width, m.height)
	if m.showInventory {
		rows := []string{"Inventory"}
		for _, item := range view.Inventory {
			row := fmt.Sprintf("%d %s", item.Quantity, item.Name)
			if item.Plus != 0 {
				row += fmt.Sprintf(" %+d", item.Plus)
			}
			if item.Charges != 0 {
				row += fmt.Sprintf(" · %d charges", item.Charges)
			}
			if item.Ego != "" {
				row += " · " + item.Ego
			}
			if item.Slot != "" {
				row += " (equipped: " + item.Slot + ")"
			}
			rows = append(rows, row)
		}
		if len(rows) == 1 {
			rows = append(rows, "(empty)")
		}
		result.Content += "\n" + lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).Padding(0, 1).Render(strings.Join(rows, "\n"))
	}
	if m.showCharacter {
		rows := []string{"Skills"}
		for _, skill := range view.Skills {
			rows = append(rows, fmt.Sprintf("%s %d", skillName(skill.ID), skill.Level))
		}
		result.Content += "\n" + lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).Padding(0, 1).Render(strings.Join(rows, "\n"))
	}
	if m.notice != "" {
		result.Content += "\n" + m.notice
	}
	return result
}

func (m *Model) Close() error { return m.game.Close() }

func skillName(id string) string {
	switch id {
	case "SK_FIGHTING":
		return "Fighting"
	case "SK_SHIELDS":
		return "Shields"
	case "SK_ARMOUR":
		return "Armour"
	case "SK_SHORT_BLADES":
		return "Short Blades"
	case "SK_MACES_FLAILS":
		return "Maces & Flails"
	case "SK_AXES":
		return "Axes"
	case "SK_POLEARMS":
		return "Polearms"
	case "SK_LONG_BLADES":
		return "Long Blades"
	case "SK_UNARMED_COMBAT":
		return "Unarmed Combat"
	default:
		return id
	}
}
