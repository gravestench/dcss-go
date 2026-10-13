package terminal

import (
	"fmt"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
)

// DrawInventory follows the source's full-screen inventory listing and pack letters.
func DrawInventory(canvas *Canvas, view game.View) {
	canvas.Write(0, 0, fmt.Sprintf("Inventory: %d/52 slots", len(view.Inventory)), White, Black)
	order := []struct{ class, title string }{
		{"OBJ_WEAPONS", "Hand Weapons"},
		{"OBJ_MISSILES", "Missiles"},
		{"OBJ_ARMOUR", "Armour"},
		{"OBJ_WANDS", "Wands"},
		{"OBJ_SCROLLS", "Scrolls"},
		{"OBJ_POTIONS", "Potions"},
	}
	y := 2
	for _, category := range order {
		var entries []int
		for i, item := range view.Inventory {
			if item.Class == category.class {
				entries = append(entries, i)
			}
		}
		if len(entries) == 0 {
			continue
		}
		canvas.Write(0, y, category.title, LightBlue, Black)
		y++
		for _, i := range entries {
			item := view.Inventory[i]
			label := item.Name
			if item.Quantity > 1 {
				label = fmt.Sprintf("%d %s", item.Quantity, item.Name)
			}
			if item.Plus != 0 {
				label = fmt.Sprintf("%+d %s", item.Plus, label)
			}
			if item.Slot != "" {
				label += " (" + item.Slot + ")"
			}
			writeClipped(canvas, 1, y, canvas.width-1, fmt.Sprintf("%c - %s", menuLetter(i), label), LightGrey)
			y++
		}
		y++
	}
	canvas.Write(0, canvas.height-2, "Esc - Return    ? - Help", Brown, Black)
}

func skillName(id string) string {
	special := map[string]string{"SK_MACES_FLAILS": "Maces & Flails", "SK_UNARMED_COMBAT": "Unarmed Combat", "SK_SHORT_BLADES": "Short Blades", "SK_LONG_BLADES": "Long Blades"}
	if name := special[id]; name != "" {
		return name
	}
	name := strings.TrimPrefix(id, "SK_")
	return strings.Title(strings.ToLower(strings.ReplaceAll(name, "_", " ")))
}

// DrawSkills uses the source skill columns; unported training is explicit.
func DrawSkills(canvas *Canvas, view game.View, catalog content.Catalog) {
	canvas.Write(0, 0, "Skills", White, Black)
	canvas.Write(1, 2, "Skill                      Level  Apt  Train", LightBlue, Black)
	species, _ := catalog.Species("SP_HUMAN")
	for i, skill := range view.Skills {
		apt := species.Aptitudes[skill.ID]
		writeClipped(canvas, 1, 3+i, canvas.width-1, fmt.Sprintf("%c - %-24s %5.1f  %+2d    --", menuLetter(i), skillName(skill.ID), float64(skill.Level), apt.Value), LightGrey)
	}
	canvas.Write(0, canvas.height-3, "Training controls are unavailable in the Go port.", Brown, Black)
	canvas.Write(0, canvas.height-2, "Esc - Return    ? - Help", Brown, Black)
}

// DrawHelp keeps the source command meanings visible for supported and stubbed actions.
func DrawHelp(canvas *Canvas) {
	lines := []string{
		"Dungeon Crawl Stone Soup - Help",
		"",
		"Movement: h j k l, y u b n, arrow keys",
		"Wait: . or s     Pick up: g ,     Stairs: < or >",
		"Inventory: i     Skills: m     Help: ?",
		"Save and exit: S (confirm), Ctrl-S (now)",
		"Abandon character: Ctrl-Q (confirm)",
		"Quaff: q (unavailable)     Run right: L (unavailable)",
		"Other unported commands explain their unavailable status.",
		"",
		"Esc - Return",
	}
	for y, line := range lines {
		color := LightGrey
		if y == 0 {
			color = Yellow
		}
		writeClipped(canvas, 0, y, canvas.width, line, color)
	}
}

func (m *AppModel) handleModalKey(key string) {
	switch key {
	case "esc":
		m.screen, m.notice = ScreenPlay, ""
	case "?":
		m.previous, m.screen, m.notice = m.screen, ScreenHelp, ""
	default:
		m.notice = "This menu control is unavailable in the Go port."
	}
}

func (m *AppModel) drawModalNotice(canvas *Canvas) {
	if m.notice != "" {
		writeClipped(canvas, 0, canvas.height-1, canvas.width, m.notice, LightRed)
	}
}
