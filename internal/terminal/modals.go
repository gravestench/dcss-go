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
	order := []struct {
		class string
		title string
	}{
		{
			class: "OBJ_WEAPONS",
			title: "Hand Weapons",
		},
		{
			class: "OBJ_MISSILES",
			title: "Missiles",
		},
		{
			class: "OBJ_ARMOUR",
			title: "Armour",
		},
		{
			class: "OBJ_WANDS",
			title: "Wands",
		},
		{
			class: "OBJ_SCROLLS",
			title: "Scrolls",
		},
		{
			class: "OBJ_POTIONS",
			title: "Potions",
		},
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

// DrawQuaff uses inventory letters so a choice always selects the displayed item.
func DrawQuaff(canvas *Canvas, view game.View) {
	canvas.Write(0, 0, "Quaff which potion?", White, Black)
	y := 2

	for index, item := range view.Inventory {
		if item.Class != "OBJ_POTIONS" {
			continue
		}

		label := item.Name

		if item.Quantity > 1 {
			label = fmt.Sprintf("%d %s", item.Quantity, label)
		}

		writeClipped(canvas, 1, y, canvas.width-1, fmt.Sprintf("%c - %s", menuLetter(index), label), LightGrey)
		y++
	}

	if y == 2 {
		canvas.Write(1, y, "You have no potions.", Brown, Black)
	}

	canvas.Write(0, canvas.height-2, "Esc - Cancel    ? - Help", Brown, Black)
}

func skillName(id string) string {
	special := map[string]string{
		"SK_MACES_FLAILS":   "Maces & Flails",
		"SK_UNARMED_COMBAT": "Unarmed Combat",
		"SK_SHORT_BLADES":   "Short Blades",
		"SK_LONG_BLADES":    "Long Blades",
	}

	if name := special[id]; name != "" {
		return name
	}

	name := strings.TrimPrefix(id, "SK_")

	return strings.Title(strings.ToLower(strings.ReplaceAll(name, "_", " ")))
}

// DrawSkills uses the source's two columns and labels for unavailable controls.
func DrawSkills(canvas *Canvas, view game.View, catalog content.Catalog) {
	canvas.Write(0, 0, "Skills", White, Black)

	for _, x := range []int{1, 40} {
		writeClipped(canvas, x, 2, 38, "Skill                 Level Apt Train", LightBlue)
	}

	species, _ := catalog.Species("SP_HUMAN")
	levels := make(map[string]int, len(view.Skills))

	for _, skill := range view.Skills {
		levels[skill.ID] = skill.Level
	}

	letter := 0

	for col, skills := range catalog.Presentation().SkillColumns {
		x := 1 + col*39

		for row, id := range skills {
			if id == "" {
				continue
			}

			apt := species.Aptitudes[id]
			color := DarkGrey

			if levels[id] > 0 {
				color = LightGrey
			}

			label := fmt.Sprintf(
				"%c - %-19s %4.1f %+2d  --",
				menuLetter(letter),
				skillName(id),
				float64(levels[id]),
				apt.Value,
			)
			writeClipped(canvas, x, 3+row, 38, label, color)
			letter++
		}
	}

	writeClipped(canvas, 0, canvas.height-5, canvas.width, "/ - mode    | - skill    * - skills    ! - view", Brown)
	writeClipped(canvas, 0, canvas.height-4, canvas.width, "= - target    ? - help    Esc - Return", Brown)
	writeClipped(canvas, 0, canvas.height-3, canvas.width, "Training controls are unavailable in the Go port.", Brown)
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
		"Quaff: q (curing, might)         Run right: L (unavailable)",
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
