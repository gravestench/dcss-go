package terminal

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
)

func pregameModel(t *testing.T) *AppModel {
	t.Helper()
	catalog, err := content.LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	m, err := NewAppModel(catalog, 17, filepath.Join(t.TempDir(), "run.json"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { m.Close() })
	return m
}

func pressApp(m *AppModel, key string) tea.Cmd {
	special := map[string]rune{
		"enter":     tea.KeyEnter,
		"down":      tea.KeyDown,
		"up":        tea.KeyUp,
		"space":     tea.KeySpace,
		"esc":       tea.KeyEscape,
		"backspace": tea.KeyBackspace,
	}
	if code, ok := special[key]; ok {
		_, cmd := m.Update(tea.KeyPressMsg{Code: code})
		return cmd
	}
	_, cmd := m.Update(tea.KeyPressMsg{
		Text: key,
		Code: []rune(key)[0],
	})
	return cmd
}

func plainApp(m *AppModel) string {
	return strings.Join(m.renderCanvas().PlainRows(), "\n")
}

func enterName(m *AppModel, name string) {
	for _, r := range name {
		pressApp(m, string(r))
	}
}

func TestPregameStartupBannerAndSourceModes(t *testing.T) {
	m := pregameModel(t)
	view := plainApp(m)
	for _, want := range []string{
		"Dungeon Crawl Stone Soup 0.30-a0-23-ge60ba3568b0",
		"Enter your name:",
		"Choices:",
		"Dungeon Crawl",
		"Choose Game Seed",
		"Tutorial for Dungeon Crawl",
		"Hints Mode for Dungeon Crawl",
		"Dungeon Sprint",
		"Instructions",
		"The Arena",
		"High Scores",
	} {
		if !strings.Contains(view, want) {
			t.Fatalf("startup missing %q", want)
		}
	}
	if m.screen != ScreenStartup || m.game != nil {
		t.Fatal("startup created a run")
	}
	if !strings.Contains(view, "[ctrl-p] view rc file information and log") {
		t.Fatal("source startup footer missing")
	}
	m.handleKey("ctrl+p")
	if m.screen != ScreenStartup || !strings.Contains(m.notice, "unavailable") {
		t.Fatal("unported rc-file control lacked explanation")
	}
	pressApp(m, "down")
	pressApp(m, "enter")
	if m.screen != ScreenStartup || !strings.Contains(m.notice, "unavailable") {
		t.Fatalf("unported mode changed screen: %v / %q", m.screen, m.notice)
	}
}

func TestPregameWelcomeTextAndWeaponReturnAfterHelp(t *testing.T) {
	m := pregameModel(t)
	pressApp(m, "enter")
	if !strings.Contains(plainApp(m), "Welcome.") || strings.Contains(plainApp(m), "Welcome, .") {
		t.Fatal("blank-name welcome text")
	}
	pressApp(m, "j")
	if !strings.Contains(plainApp(m), "Welcome, unnamed Human.") {
		t.Fatal("species welcome text")
	}
	pressApp(m, "a")
	if !strings.Contains(plainApp(m), "Welcome, unnamed Human Fighter.") {
		t.Fatal("weapon welcome text")
	}
	pressApp(m, "?")
	pressApp(m, "esc")
	pressApp(m, "backspace")
	if m.screen != ScreenBackground {
		t.Fatalf("weapon return after help: %v", m.screen)
	}
	m.name = "Alice"
	if got := m.welcomeText(); got != "Welcome, Alice the Human Fighter." {
		t.Fatalf("named welcome: %q", got)
	}
}

func TestPregameSpeciesBackgroundOrderAndDescriptions(t *testing.T) {
	m := pregameModel(t)
	pressApp(m, "enter")
	if m.screen != ScreenSpecies {
		t.Fatalf("startup -> %v", m.screen)
	}
	view := plainApp(m)
	for _, want := range []string{
		"Simple",
		"Intermediate",
		"Advanced",
		"a - Hill Orc",
		"j - Human",
		"A - Mummy",
		"Hill Orcs are skilled",
	} {
		if !strings.Contains(view, want) {
			t.Fatalf("species menu missing %q", want)
		}
	}
	pressApp(m, "down")
	if !strings.Contains(plainApp(m), "Minotaurs are large") {
		t.Fatal("focus did not update description")
	}
	pressApp(m, "j")
	if m.screen != ScreenBackground || m.speciesID != "SP_HUMAN" {
		t.Fatalf("Human choice: %v / %s", m.screen, m.speciesID)
	}
	view = plainApp(m)
	for _, want := range []string{
		"Warrior",
		"Adventurer",
		"Zealot",
		"Warrior-mage",
		"Mage",
		"a - Fighter",
		"y - Venom Mage",
		"Fighters are equipped",
	} {
		if !strings.Contains(view, want) {
			t.Fatalf("background menu missing %q", want)
		}
	}
}

func TestPregameBothChoiceOrdersAndSixWeapons(t *testing.T) {
	for i, weapon := range []string{
		"WPN_RAPIER",
		"WPN_FLAIL",
		"WPN_WAR_AXE",
		"WPN_TRIDENT",
		"WPN_LONG_SWORD",
		"WPN_UNARMED",
	} {
		t.Run(weapon, func(t *testing.T) {
			m := pregameModel(t)
			enterName(m, "Alice")
			pressApp(m, "enter")
			if i%2 == 0 {
				pressApp(m, "j")
				pressApp(m, "a")
			} else {
				pressApp(m, "space")
				pressApp(m, "a")
				pressApp(m, "j")
			}
			if m.screen != ScreenWeapon {
				t.Fatalf("choice order did not reach weapon: %v / %s", m.screen, m.notice)
			}
			if !strings.Contains(plainApp(m), "a - rapier") || !strings.Contains(plainApp(m), "f - unarmed") {
				t.Fatal("source weapon letters missing")
			}
			pressApp(m, string(rune('a'+i)))
			if m.screen != ScreenPlay || m.game == nil || m.weaponID != weapon {
				t.Fatalf("weapon %s start failed: %v / %q", weapon, m.screen, m.notice)
			}
			if view := m.game.View(); view.PlayerName != "Alice" || view.CurrentAut != 0 {
				t.Fatalf("started view: %+v", view)
			}
		})
	}
}

func TestPregamePostWeaponNamePromptAndUnavailableChoices(t *testing.T) {
	m := pregameModel(t)
	pressApp(m, "enter")
	pressApp(m, "a")
	if m.screen != ScreenSpecies || m.game != nil || !strings.Contains(m.notice, "unavailable") {
		t.Fatal("unported Hill Orc started a game")
	}
	pressApp(m, "space")
	pressApp(m, "b")
	if m.screen != ScreenBackground || m.game != nil || !strings.Contains(m.notice, "unavailable") {
		t.Fatal("unported Gladiator started a game")
	}
	pressApp(m, "a")
	pressApp(m, "j")
	pressApp(m, "a")
	if m.screen != ScreenName || m.game != nil || !strings.Contains(plainApp(m), "Enter your name") {
		t.Fatal("blank startup name skipped post-weapon prompt")
	}
	pressApp(m, "enter")
	if m.screen != ScreenName || m.game != nil {
		t.Fatal("invalid name created game")
	}
	pressApp(m, "!")
	if m.name != "" || !strings.Contains(m.notice, "invalid") {
		t.Fatal("invalid name character was accepted")
	}
	enterName(m, "Alice")
	pressApp(m, "enter")
	if m.screen != ScreenPlay || m.game == nil || m.game.View().PlayerName != "Alice" {
		t.Fatalf("name completion: %v / %q", m.screen, m.notice)
	}
}

func TestStartupLoadKeepsStateOnCorruptSave(t *testing.T) {
	m := pregameModel(t)
	if err := os.WriteFile(m.savePath, []byte("bad json"), 0600); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(plainApp(m), "Saved games:") {
		t.Fatal("saved-run entry missing")
	}
	for i := 0; i < 8; i++ {
		pressApp(m, "down")
	}
	pressApp(m, "enter")
	if m.screen != ScreenStartup || m.game != nil || !strings.Contains(m.notice, "Load failed") {
		t.Fatalf("corrupt load changed state: %v / %q", m.screen, m.notice)
	}
	catalog, err := content.LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	g, err := game.NewScenario(17, catalog, "WPN_RAPIER", "Alice")
	if err != nil {
		t.Fatal(err)
	}
	defer g.Close()
	if err := save.Write(m.savePath, g.Snapshot()); err != nil {
		t.Fatal(err)
	}
	pressApp(m, "enter")
	if m.screen != ScreenPlay || m.game == nil || m.game.View().PlayerName != "Alice" {
		t.Fatalf("valid startup load: %v / %q", m.screen, m.notice)
	}
}

func TestMenuResizePreservesFocusAndGameState(t *testing.T) {
	m := pregameModel(t)
	pressApp(m, "enter")
	pressApp(m, "down")
	focus := m.focus
	m.Update(tea.WindowSizeMsg{
		Width:  78,
		Height: 23,
	})
	if !strings.Contains(plainApp(m), "too small") {
		t.Fatal("small terminal warning missing")
	}
	if m.focus != focus || m.screen != ScreenSpecies || m.game != nil {
		t.Fatal("resize changed menu state")
	}
	m.Update(tea.WindowSizeMsg{
		Width:  79,
		Height: 24,
	})
	if m.focus != focus || !strings.Contains(plainApp(m), "Minotaurs are large") {
		t.Fatal("resize recovery lost focus")
	}
}
