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

// DrawPlay renders source output.cc's inline pane positions from a read-only view.
// The Go-only differences are an expanding dungeon and explicit placeholders.
func DrawPlay(canvas *Canvas, layout Layout, view game.View, notice string) {
	drawDungeon(canvas, layout.Dungeon, view)
	drawHUD(canvas, layout.HUD, view)
	drawNearbyMonsters(canvas, layout.Monsters, view.Entities)
	drawMessages(canvas, layout.Messages, view.Messages, notice)
}

// hudRenderer keeps pane coordinates in one place for the source-shaped HUD.
type hudRenderer struct {
	canvas *Canvas
	region Region
}

type vitalRow struct {
	y        int
	label    string
	current  int
	maximum  int
	yellowAt int
	redAt    int
}

type attributeRow struct {
	y     int
	label string
	value int
}

func (h hudRenderer) write(x, y int, value string, color Color) {
	writeClipped(
		h.canvas,
		h.region.X+x,
		h.region.Y+y,
		h.region.W-x,
		value,
		color,
	)
}

func drawHUD(canvas *Canvas, region Region, view game.View) {
	hud := hudRenderer{
		canvas: canvas,
		region: region,
	}

	// source/skills.cc:91; the current playable start is Fighter only.
	hud.write(0, 0, view.PlayerName+" the Shield-Bearer", Yellow)
	hud.write(0, 1, "Human", Yellow)

	hud.drawVitals(view)
	hud.drawDefenses(view)
	hud.drawAttributes(view)
	hud.drawStatus(view)
}

func (h hudRenderer) drawVitals(view game.View) {
	rows := []vitalRow{
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
	}

	for _, stat := range rows {
		h.write(0, stat.y, stat.label, Brown)

		value := fmt.Sprintf("%d", stat.current)
		color := statusValueColor(
			stat.current,
			stat.maximum,
			stat.yellowAt,
			stat.redAt,
		)

		h.write(len(stat.label), stat.y, value, color)
		h.write(len(stat.label)+len(value), stat.y, fmt.Sprintf("/%d", stat.maximum), LightGrey)
	}

	meterX := h.region.X + 18
	healthY := h.region.Y + 2
	magicY := h.region.Y + 3

	drawMeter(h.canvas, meterX, healthY, 24, view.PlayerHP, view.PlayerMaxHP, LightGreen)

	drawMeter(h.canvas, meterX, magicY, 24, view.PlayerMP, view.PlayerMaxMP, LightBlue)
}

func (h hudRenderer) drawDefenses(view game.View) {
	labels := []string{
		"AC: --",
		"EV: --",
		"SH: --",
	}

	if view.DefenseKnown {
		labels = []string{
			fmt.Sprintf("AC: %d", view.PlayerAC),
			fmt.Sprintf("EV: %d", view.PlayerEV),
			fmt.Sprintf("SH: %d", view.PlayerSH),
		}
	}

	for index, label := range labels {
		h.write(0, 4+index, label, Brown)
	}
}

func (h hudRenderer) drawAttributes(view game.View) {
	rows := []attributeRow{
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
	}

	for _, stat := range rows {
		h.write(18, stat.y, stat.label, Brown)

		color := LightGrey

		if stat.value < 3 {
			color = Red
		}

		h.write(18+len(stat.label), stat.y, fmt.Sprintf("%d", stat.value), color)
	}
}

func (h hudRenderer) drawStatus(view game.View) {
	experience := fmt.Sprintf(
		"XL: %2d Next: %2d%%",
		view.ExperienceLevel,
		view.NextLevelPercent,
	)
	h.write(0, 7, experience, Brown)

	h.write(18, 7, fmt.Sprintf("Place: D:%d", view.LevelID), Brown)

	h.write(0, 8, "Noise: --", Brown)

	h.write(18, 8, fmt.Sprintf("Time: %.1f", float64(view.CurrentAut)/10), Brown)

	h.write(0, 9, equippedWeaponLabel(view.Inventory), LightGrey)
	h.write(0, 10, "Quiver: --", Brown)

	if view.MightAut > 0 {
		h.write(0, 11, "Might", LightBlue)
	}
}

func equippedWeaponLabel(inventory []game.ItemView) string {
	for index, item := range inventory {
		if item.Slot == "weapon" {
			return fmt.Sprintf("%c) %+d %s", 'a'+index, item.Plus, item.Name)
		}
	}

	return "-) Unarmed"
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
