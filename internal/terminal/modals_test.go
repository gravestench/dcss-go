package terminal

import (
	"strings"
	"testing"

	tea "charm.land/bubbletea/v2"
)

func TestInventoryPageSourceCategoriesAndLetters(t *testing.T) {
	m := playingModel(t)
	m.handleKey("i")

	if m.screen != ScreenInventory {
		t.Fatal("inventory did not open")
	}

	page := plainApp(m)

	for _, want := range []string{
		"Inventory:",
		"Hand Weapons",
		"Armour",
		"Potions",
		"a -",
		"b -",
		"c -",
		"d -",
		"rapier",
		"scale mail",
		"buckler",
		"potion of might",
		"weapon",
		"body",
		"shield",
	} {
		if !strings.Contains(page, want) {
			t.Fatalf("inventory missing %q", want)
		}
	}

	if strings.Index(page, "rapier") > strings.Index(page, "scale mail") ||
		strings.Index(page, "scale mail") > strings.Index(page, "potion of might") {
		t.Fatal("inventory source category order")
	}
}

func TestSkillsPageLevelsAptitudesAndUnavailableTraining(t *testing.T) {
	m := playingModel(t)
	aut := m.game.View().CurrentAut
	m.handleKey("m")

	if m.screen != ScreenSkills {
		t.Fatal("skills did not open")
	}

	page := plainApp(m)

	for _, want := range []string{
		"Skills",
		"Skill",
		"Level",
		"Apt",
		"Train",
		"Fighting",
		"Short Blades",
		"Armour",
		"Shields",
		"3.0",
		"2.0",
		"+0",
		"--",
	} {
		if !strings.Contains(page, want) {
			t.Fatalf("skills missing %q", want)
		}
	}

	m.handleKey("a")

	if !strings.Contains(plainApp(m), "unavailable") || m.game.View().CurrentAut != aut {
		t.Fatal("training control changed turn or lacked explanation")
	}
}

func TestHelpPageSourceKeysAndModalNavigation(t *testing.T) {
	m := playingModel(t)
	aut := m.game.View().CurrentAut
	m.handleKey("?")
	page := plainApp(m)

	for _, want := range []string{
		"Dungeon Crawl Stone Soup",
		"Movement",
		"h j k l",
		"g ,",
		"i",
		"m",
		"S",
		"Ctrl-S",
		"Ctrl-Q",
		"q",
		"L",
		"unavailable",
	} {
		if !strings.Contains(page, want) {
			t.Fatalf("help missing %q", want)
		}
	}

	m.handleKey("esc")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != aut {
		t.Fatal("help escape changed run")
	}

	m.handleKey("i")
	m.handleKey("?")
	m.handleKey("esc")
	m.handleKey("esc")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != aut {
		t.Fatal("nested modal escape changed run")
	}
}

func TestModalResizePreservesFocusGameAndAut(t *testing.T) {
	m := playingModel(t)
	m.handleKey("i")
	aut, g := m.game.View().CurrentAut, m.game
	m.focus = 2
	m.Update(tea.WindowSizeMsg{
		Width:  78,
		Height: 23,
	})

	if !strings.Contains(plainApp(m), "too small") {
		t.Fatal("resize warning missing")
	}

	m.Update(tea.WindowSizeMsg{
		Width:  79,
		Height: 24,
	})

	if m.screen != ScreenInventory ||
		m.focus != 2 ||
		m.game != g ||
		m.game.View().CurrentAut != aut ||
		!strings.Contains(plainApp(m), "Inventory:") {
		t.Fatal("modal resize lost state")
	}
}
