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

func drawDungeon(canvas *Canvas, region Region, view game.View) {
	centerX, centerY := region.X+region.W/2, region.Y+region.H/2
	for y, row := range view.Terrain {
		for x, glyph := range row {
			sx, sy := centerX+x-view.PlayerX, centerY+y-view.PlayerY
			if sx < region.X || sy < region.Y || sx >= region.X+region.W || sy >= region.Y+region.H {
				continue
			}
			color := DarkGrey
			switch glyph {
			case '#':
				color = LightGrey
			case '<', '>':
				color = Yellow
			}
			canvas.Put(sx, sy, glyph, color, Black)
		}
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
			}
			canvas.Put(sx, sy, entity.Glyph, color, Black)
		}
	}
}

// DrawPlay renders source output.cc's inline pane positions from a read-only view.
// The Go-only differences are an expanding dungeon and explicit placeholders.
func DrawPlay(canvas *Canvas, layout Layout, view game.View, notice string) {
	drawDungeon(canvas, layout.Dungeon, view)
	h := layout.HUD
	hud := func(x, y int, value string, color Color) { writeClipped(canvas, h.X+x, h.Y+y, h.W-x, value, color) }
	hud(0, 0, view.PlayerName+" the Shield-Bearer", Yellow) // source/skills.cc:91; current Fighter only
	hud(0, 1, "Human", Yellow)
	hud(0, 2, fmt.Sprintf("Health: %d/%d", view.PlayerHP, view.PlayerMaxHP), LightGrey)
	hud(0, 3, fmt.Sprintf("Magic:  %d/%d", view.PlayerMP, view.PlayerMaxMP), LightGrey)
	drawMeter(canvas, h.X+18, h.Y+2, 24, view.PlayerHP, view.PlayerMaxHP, LightGreen)
	drawMeter(canvas, h.X+18, h.Y+3, 24, view.PlayerMP, view.PlayerMaxMP, LightBlue)
	for i, label := range []string{"AC: --", "EV: --", "SH: --"} {
		hud(0, 4+i, label, Brown)
	}
	hud(18, 4, fmt.Sprintf("Str: %d", view.Attributes.Strength), Brown)
	hud(18, 5, fmt.Sprintf("Int: %d", view.Attributes.Intelligence), Brown)
	hud(18, 6, fmt.Sprintf("Dex: %d", view.Attributes.Dexterity), Brown)
	hud(0, 7, "XL: -- Next: --", Brown)
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

	var monsters []string
	for _, entity := range view.Entities {
		if entity.Role == "monster" && entity.Name != "" {
			monsters = append(monsters, "a "+entity.Name)
		}
	}
	sort.Strings(monsters)
	for i, name := range monsters {
		if i >= layout.Monsters.H {
			break
		}
		writeClipped(canvas, layout.Monsters.X, layout.Monsters.Y+i, layout.Monsters.W, name, LightGrey)
	}
	messages := append([]string(nil), view.Messages...)
	if notice != "" {
		messages = append(messages, notice)
	}
	if len(messages) > layout.Messages.H {
		messages = messages[len(messages)-layout.Messages.H:]
	}
	for i, message := range messages {
		writeClipped(canvas, layout.Messages.X, layout.Messages.Y+i, layout.Messages.W, strings.TrimSpace(message), LightGrey)
	}
}
