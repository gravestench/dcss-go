package terminal

import (
	"fmt"
	"sort"
	"strings"

	"dcrawl-go/internal/game"
	"github.com/mattn/go-runewidth"
)

func writeClipped(canvas *Canvas, x, y, width int, value string, fg Color) {
	used := 0

	for _, glyph := range value {
		cells := runewidth.RuneWidth(glyph)

		if cells < 1 || used+cells > width {
			break
		}

		canvas.Put(x+used, y, glyph, fg, Black)
		used += cells
	}
}

func drawMeter(canvas *Canvas, x, y, width, current, maximum int, filled Color) {
	if maximum <= 0 {
		return
	}

	if current < 0 {
		current = 0
	}

	if current > maximum {
		current = maximum
	}

	n := width * current / maximum

	for i := 0; i < width; i++ {
		if i < n {
			canvas.Put(x+i, y, '=', filled, Black)
		} else {
			canvas.Put(x+i, y, '-', DarkGrey, Black)
		}
	}
}

func statusValueColor(current, maximum, yellowAt, redAt int) Color {
	if maximum <= 0 {
		return LightGrey
	}

	percent := current * 100 / maximum

	if percent <= redAt {
		return Red
	}

	if percent <= yellowAt {
		return Yellow
	}

	return LightGrey
}

func drawDungeon(canvas *Canvas, region Region, view game.View) {
	centerX, centerY := region.X+region.W/2, region.Y+region.H/2

	if view.Width <= 0 {
		return
	}

	for i, cell := range view.Cells {
		if cell.State == game.Unknown {
			continue
		}

		x, y := i%view.Width, i/view.Width
		sx, sy := centerX+x-view.PlayerX, centerY+y-view.PlayerY

		if sx < region.X || sy < region.Y || sx >= region.X+region.W || sy >= region.Y+region.H {
			continue
		}

		color := DarkGrey

		if cell.State == game.Visible {
			color = LightGrey

			if cell.Glyph == '<' || cell.Glyph == '>' {
				color = Yellow
			}
		}

		canvas.Put(sx, sy, cell.Glyph, color, Black)
	}

	for _, playerPass := range []bool{false, true} {
		for _, entity := range view.Entities {
			if (entity.Role == "player") != playerPass {
				continue
			}

			sx, sy := centerX+entity.X-view.PlayerX, centerY+entity.Y-view.PlayerY

			if sx < region.X || sy < region.Y || sx >= region.X+region.W || sy >= region.Y+region.H {
				continue
			}

			color := LightGrey

			switch entity.Role {
			case "player":
				color = White

			case "monster":
				color = Brown

			case "item":
				color = LightGreen

				if entity.KindID == "CORPSE_BODY" {
					color = Brown
				}

				if entity.KindID == "CORPSE_SKELETON" {
					color = LightGrey
				}
			}

			canvas.Put(sx, sy, entity.Glyph, color, Black)
		}
	}
}

// DrawPlay renders source output.cc's inline pane positions from a read-only view.
// The Go-only differences are an expanding dungeon and explicit placeholders.
func DrawPlay(canvas *Canvas, layout Layout, view game.View, notice string) {
	drawDungeon(canvas, layout.Dungeon, view)
	drawHUD(canvas, layout.HUD, view)
	drawNearbyMonsters(canvas, layout.Monsters, view.Entities)
	drawMessages(canvas, layout.Messages, view.Messages, notice)
}

func drawHUD(canvas *Canvas, region Region, view game.View) {
	hud := func(x, y int, value string, color Color) {
		writeClipped(canvas, region.X+x, region.Y+y, region.W-x, value, color)
	}

	hud(0, 0, view.PlayerName+" the Shield-Bearer", Yellow) // source/skills.cc:91; current Fighter only
	hud(0, 1, "Human", Yellow)

	for _, stat := range []struct {
		y        int
		label    string
		current  int
		maximum  int
		yellowAt int
		redAt    int
	}{
		{
			y:        2,
			label:    "Health: ",
			current:  view.PlayerHP,
			maximum:  view.PlayerMaxHP,
			yellowAt: 70,
			redAt:    40,
		},
		{
			y:        3,
			label:    "Magic:  ",
			current:  view.PlayerMP,
			maximum:  view.PlayerMaxMP,
			yellowAt: 50,
			redAt:    25,
		},
	} {
		hud(0, stat.y, stat.label, Brown)
		value := fmt.Sprintf("%d", stat.current)
		color := statusValueColor(
			stat.current,
			stat.maximum,
			stat.yellowAt,
			stat.redAt,
		)
		hud(len(stat.label), stat.y, value, color)
		hud(len(stat.label)+len(value), stat.y, fmt.Sprintf("/%d", stat.maximum), LightGrey)
	}

	drawMeter(canvas, region.X+18, region.Y+2, 24, view.PlayerHP, view.PlayerMaxHP, LightGreen)
	drawMeter(canvas, region.X+18, region.Y+3, 24, view.PlayerMP, view.PlayerMaxMP, LightBlue)

	defenseLabels := []string{
		"AC: --",
		"EV: --",
		"SH: --",
	}

	if view.DefenseKnown {
		defenseLabels = []string{
			fmt.Sprintf("AC: %d", view.PlayerAC),
			fmt.Sprintf("EV: %d", view.PlayerEV),
			fmt.Sprintf("SH: %d", view.PlayerSH),
		}
	}

	for i, label := range defenseLabels {
		hud(0, 4+i, label, Brown)
	}

	for _, stat := range []struct {
		y     int
		label string
		value int
	}{
		{
			y:     4,
			label: "Str: ",
			value: view.Attributes.Strength,
		},
		{
			y:     5,
			label: "Int: ",
			value: view.Attributes.Intelligence,
		},
		{
			y:     6,
			label: "Dex: ",
			value: view.Attributes.Dexterity,
		},
	} {
		hud(18, stat.y, stat.label, Brown)
		color := LightGrey

		if stat.value < 3 {
			color = Red
		}

		hud(18+len(stat.label), stat.y, fmt.Sprintf("%d", stat.value), color)
	}

	hud(0, 7, fmt.Sprintf("XL: %2d Next: %2d%%", view.ExperienceLevel, view.NextLevelPercent), Brown)
	hud(18, 7, fmt.Sprintf("Place: D:%d", view.LevelID), Brown)
	hud(0, 8, "Noise: --", Brown)
	hud(18, 8, fmt.Sprintf("Time: %.1f", float64(view.CurrentAut)/10), Brown)
	weapon := "-) Unarmed"

	for i, item := range view.Inventory {
		if item.Slot == "weapon" {
			weapon = fmt.Sprintf("%c) %+d %s", 'a'+i, item.Plus, item.Name)
			break
		}
	}

	hud(0, 9, weapon, LightGrey)
	hud(0, 10, "Quiver: --", Brown)

	if view.MightAut > 0 {
		hud(0, 11, "Might", LightBlue)
	}
}

func drawNearbyMonsters(canvas *Canvas, region Region, entities []game.EntityView) {
	var monsters []string

	for _, entity := range entities {
		if entity.Role == "monster" && entity.Name != "" {
			monsters = append(monsters, "a "+entity.Name)
		}
	}

	sort.Strings(monsters)

	for i, name := range monsters {
		if i >= region.H {
			break
		}

		writeClipped(canvas, region.X, region.Y+i, region.W, name, LightGrey)
	}
}

func drawMessages(canvas *Canvas, region Region, history []string, notice string) {
	messages := append([]string(nil), history...)

	if notice != "" {
		messages = append(messages, notice)
	}

	if len(messages) > region.H {
		messages = messages[len(messages)-region.H:]
	}

	for i, message := range messages {
		writeClipped(canvas, region.X, region.Y+i, region.W, strings.TrimSpace(message), LightGrey)
	}
}
