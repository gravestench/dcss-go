package terminal

import (
	"fmt"
	"strings"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"dcrawl-go/internal/game"
)

func Render(view game.View, width, height int) tea.View {
	if width <= 0 {
		width = 80
	}
	if height <= 0 {
		height = 24
	}
	rows := make([][]rune, len(view.Terrain))
	for y, row := range view.Terrain {
		rows[y] = []rune(row)
		if len(rows[y]) > width {
			rows[y] = rows[y][:width]
		}
	}
	// Draw the player last when a floor item occupies the same cell.
	for _, playerPass := range []bool{false, true} {
		for _, entity := range view.Entities {
			if (entity.Glyph == '@') != playerPass || entity.Y < 0 || entity.Y >= len(rows) || entity.X < 0 || entity.X >= len(rows[entity.Y]) {
				continue
			}
			rows[entity.Y][entity.X] = entity.Glyph
		}
	}
	mapRows := make([]string, len(rows))
	for y, row := range rows {
		mapRows[y] = string(row)
	}
	header := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6")).Render("DCrawl · Dungeon slice")
	status := fmt.Sprintf("%s  Str:%d Int:%d Dex:%d  D:%d HP:%d/%d MP:%d/%d Aut:%d", view.CharacterName,
		view.Attributes.Strength, view.Attributes.Intelligence, view.Attributes.Dexterity,
		view.LevelID, view.PlayerHP, view.PlayerMaxHP, view.PlayerMP, view.PlayerMaxMP, view.CurrentAut)
	mapText := lipgloss.NewStyle().Foreground(lipgloss.Color("7")).Render(strings.Join(mapRows, "\n"))
	lines := []string{header, status, mapText}
	if len(view.Messages) > 0 {
		messages := view.Messages
		if len(messages) > 3 {
			messages = messages[len(messages)-3:]
		}
		lines = append(lines, strings.Join(messages, "\n"))
	}
	lines = append(lines, "h/j/k/l or arrows move · . wait · g pickup · </> stairs", "i inventory · c character · S save · L load · q quit")
	content := strings.Join(lines, "\n")
	if len(strings.Split(content, "\n")) > height {
		content = strings.Join(strings.Split(content, "\n")[:height], "\n")
	}
	return tea.NewView(content)
}
