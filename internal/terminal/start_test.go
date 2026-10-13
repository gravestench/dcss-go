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

func startFixture(t *testing.T) (*StartModel, content.Catalog, string) {
	t.Helper()
	catalog, err := content.LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(t.TempDir(), "run.json")
	m, err := NewStartModel(catalog, 17, path)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { m.Close() })
	return m, catalog, path
}

func pressStart(m *StartModel, key string) tea.Cmd {
	_, command := m.Update(tea.KeyPressMsg{Text: key, Code: []rune(key)[0]})
	return command
}

func TestStartMenu(t *testing.T) {
	m, _, _ := startFixture(t)
	if m.play != nil || !strings.Contains(m.View().Content, "rapier") || !strings.Contains(m.View().Content, "unarmed") {
		t.Fatalf("weapon menu missing choices or created game early: %q", m.View().Content)
	}
	pressStart(m, "z")
	pressStart(m, "h")
	if m.play != nil {
		t.Fatal("invalid pregame keys created a game")
	}
	pressStart(m, "1")
	if m.play == nil || m.play.game.View().CurrentAut != 0 || len(m.play.game.View().Inventory) != 4 {
		t.Fatal("legal choice did not start an equipped game at aut zero")
	}
	if !strings.Contains(m.View().Content, "Human Fighter") {
		t.Fatal("game view not shown after choice")
	}
	quit, _, _ := startFixture(t)
	if command := pressStart(quit, "q"); command == nil || quit.play != nil {
		t.Fatal("quit failed at menu")
	}
}

func TestStartMenuLoadBypassesChoice(t *testing.T) {
	m, catalog, path := startFixture(t)
	if err := os.WriteFile(path, []byte(`{"version":2}`), 0600); err != nil {
		t.Fatal(err)
	}
	pressStart(m, "L")
	if m.play != nil || !strings.Contains(m.View().Content, "Load failed") {
		t.Fatal("old save left menu or hid error")
	}
	if err := os.WriteFile(path, []byte("bad json"), 0600); err != nil {
		t.Fatal(err)
	}
	pressStart(m, "L")
	if m.play != nil || !strings.Contains(m.View().Content, "Load failed") {
		t.Fatal("invalid save left menu or hid error")
	}
	g, err := game.NewScenario(17, catalog, "WPN_UNARMED")
	if err != nil {
		t.Fatal(err)
	}
	defer g.Close()
	if err := save.Write(path, g.Snapshot()); err != nil {
		t.Fatal(err)
	}
	pressStart(m, "L")
	if m.play == nil || m.play.game.View().CurrentAut != 0 || len(m.play.game.View().Inventory) != 3 {
		t.Fatal("valid save did not bypass choice and restore unarmed loadout")
	}
}
