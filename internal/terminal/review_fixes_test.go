package terminal

import (
	"strings"
	"testing"

	tea "charm.land/bubbletea/v2"
	"crawl/internal/script"
)

func TestFocusedEnterChoosesSpeciesBackgroundAndWeapon(t *testing.T) {
	m := pregameModel(t)
	pressApp(m, "enter")

	for i := 0; i < 9; i++ {
		pressApp(m, "down")
	}

	pressApp(m, "enter")

	if m.screen != ScreenBackground || m.speciesID != "SP_HUMAN" {
		t.Fatalf("focused Human not selected: %v/%s", m.screen, m.speciesID)
	}

	pressApp(m, "enter")

	if m.screen != ScreenWeapon || m.jobID != "JOB_FIGHTER" {
		t.Fatalf("focused Fighter not selected: %v/%s", m.screen, m.jobID)
	}

	pressApp(m, "down")
	pressApp(m, "enter")

	if m.screen != ScreenName || m.weaponID != "WPN_FLAIL" {
		t.Fatalf("focused flail not selected: %v/%s", m.screen, m.weaponID)
	}
}

func TestUndersizedTerminalBlocksHiddenInput(t *testing.T) {
	m := playingModel(t)
	m.handleKey("i")
	m.focus = 2

	aut := m.game.View().CurrentAut
	m.Update(tea.WindowSizeMsg{
		Width:  78,
		Height: 23,
	})

	for _, key := range []string{
		"esc",
		"s",
		"S",
		"ctrl+s",
	} {
		if cmd := m.handleKey(key); cmd != nil {
			t.Fatalf("%q exited behind resize warning", key)
		}
	}

	m.Update(tea.WindowSizeMsg{
		Width:  79,
		Height: 24,
	})

	if m.screen != ScreenInventory ||
		m.focus != 2 ||
		m.game.View().CurrentAut != aut {
		t.Fatal("hidden input changed modal or game")
	}
}

func TestSkillsPageTwoColumnsAndSourceControls(t *testing.T) {
	m := playingModel(t)
	m.handleKey("m")
	rows := m.renderCanvas().PlainRows()

	if !strings.Contains(rows[3][:39], "Fighting") ||
		!strings.Contains(rows[3][39:], "Spellcasting") {
		t.Fatalf("source skill columns absent: %q", rows[3])
	}

	page := strings.Join(rows, "\n")

	for _, want := range []string{
		"/ - mode",
		"| - skill",
		"* - skills",
		"! - view",
		"= - target",
		"? - help",
	} {
		if !strings.Contains(page, want) {
			t.Fatalf("source skill control %q absent", want)
		}
	}
}

func TestCreationRecommendationAndFocusColors(t *testing.T) {
	m := pregameModel(t)
	pressApp(m, "enter")
	m.jobID = "JOB_FIGHTER"

	m.focus = 9 // Human, restricted for Fighter.

	c := m.renderCanvas()
	x, y, offset := 0, 0, 0

	for groupIndex, group := range m.presentation.SpeciesGroups {
		if m.focus < offset+len(group.IDs) {
			col, row := groupPosition(ScreenSpecies, groupIndex)
			x, y = col, row+1+m.focus-offset
			break
		}

		offset += len(group.IDs)
	}

	if c.cells[y*c.width+x].fg != White || c.cells[y*c.width+x].bg != LightGrey {
		t.Fatalf("focused restricted species colors: %+v", c.cells[y*c.width+x])
	}

	m.screen = ScreenBackground
	m.focus = 0
	m.jobID = ""

	m.speciesID = "SP_BARACHI"

	ids := flattenGroups(m.presentation.JobGroups)

	for i, id := range ids {
		if id == "JOB_ARCANE_MARKSMAN" {
			m.focus = i
			break
		}
	}

	choice := m.choices[script.ChoiceKey{
		SpeciesID:    "SP_BARACHI",
		JobID:        "JOB_ARCANE_MARKSMAN",
		SpeciesFirst: true,
	}]

	if choice.Restriction != "recommended" {
		t.Fatal("review fixture does not contain a recommended pair")
	}

	c = m.renderCanvas()

	if !strings.Contains(strings.Join(c.PlainRows(), "\n"), "Arcane Marksman") {
		t.Fatal("recommended entry absent")
	}

	fg, bg := m.characterChoiceColors("JOB_ARCANE_MARKSMAN", m.focus)

	if !choice.Playable ||
		fg != White ||
		bg != Green {
		t.Fatalf("playable recommended start colors: %v/%v", fg, bg)
	}
}

func TestCreationShortcutColumnsAndContextText(t *testing.T) {
	m := pregameModel(t)
	pressApp(m, "enter")
	rows := m.renderCanvas().PlainRows()

	for row, want := range []string{
		"+ - Recommended species",
		"# - Recommended character",
		"% - List aptitudes",
		"? - Help",
	} {
		if !strings.HasPrefix(rows[14+row][1:], want) {
			t.Fatalf("left shortcut row %d: %q", 14+row, rows[14+row])
		}
	}

	for row, want := range []string{
		"* - Random species",
		"! - Random character",
		"Space - Pick background first",
	} {
		if !strings.Contains(rows[14+row][40:], want) {
			t.Fatalf("right shortcut row %d: %q", 14+row, rows[14+row])
		}
	}

	pressApp(m, "j")
	rows = m.renderCanvas().PlainRows()

	if !strings.Contains(rows[14], "Recommended background") ||
		!strings.Contains(rows[16][40:], "Space - Change species") {
		t.Fatal("contextual background shortcuts missing")
	}
}

func TestDrawPlayDangerValueColors(t *testing.T) {
	view := playView(t)

	view.PlayerHP = 7
	view.PlayerMP = 0
	view.Attributes.Strength = 2

	c := NewCanvas(79, 24)
	layout, _ := ComputeLayout(79, 24)
	DrawPlay(c, layout, view, "", testPresentationPolicy(t))
	cellAt := func(x, y int) cell {
		return c.cells[y*c.width+x]
	}

	if cellAt(37, 2).fg != Brown ||
		cellAt(45, 2).fg != Red ||
		cellAt(46, 2).fg != LightGrey {
		t.Fatalf("HP caption/current/max colors: %+v %+v %+v", cellAt(37, 2), cellAt(45, 2), cellAt(46, 2))
	}

	if cellAt(37, 3).fg != Brown || cellAt(45, 3).fg != Red {
		t.Fatalf("MP caption/current colors: %+v %+v", cellAt(37, 3), cellAt(45, 3))
	}

	if cellAt(55, 4).fg != Brown || cellAt(60, 4).fg != Red {
		t.Fatalf("stat caption/value colors: %+v %+v", cellAt(55, 4), cellAt(60, 4))
	}
}

func TestDeathPageExplainsUnportedRecords(t *testing.T) {
	m := playingModel(t)

	m.screen = ScreenDeath

	page := strings.ToLower(plainApp(m))

	if !strings.Contains(page, "morgue") ||
		!strings.Contains(page, "scores") ||
		!strings.Contains(page, "unavailable") {
		t.Fatal("death page lacks honest unported-record explanation")
	}
}
