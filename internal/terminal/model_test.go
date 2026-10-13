package terminal

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
)

func newModel(t *testing.T) *Model {
	t.Helper()
	catalog, err := content.LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	g, err := game.NewScenario(1, catalog, "WPN_RAPIER", "Tester")
	if err != nil {
		t.Fatal(err)
	}
	m := NewModel(g, filepath.Join(t.TempDir(), "save.json"))
	t.Cleanup(func() { m.Close() })
	return m
}

func press(m *Model, key string) {
	m.Update(tea.KeyPressMsg{Text: key, Code: []rune(key)[0]})
}

func TestMovementKeyStepsOnce(t *testing.T) {
	m := newModel(t)
	press(m, "l")
	if got := m.game.View().CurrentAut; got != 10 {
		t.Fatalf("movement key advanced to %d aut", got)
	}
}

func TestUnknownKeyIsFree(t *testing.T) {
	m := newModel(t)
	press(m, "z")
	if got := m.game.View().CurrentAut; got != 0 {
		t.Fatalf("unknown key advanced to %d aut", got)
	}
}

func TestResizeIsFree(t *testing.T) {
	m := newModel(t)
	m.Update(tea.WindowSizeMsg{Width: 80, Height: 30})
	if m.width != 80 || m.height != 30 || m.game.View().CurrentAut != 0 {
		t.Fatalf("resize changed time or missed dimensions: %dx%d", m.width, m.height)
	}
}

func TestViewDoesNotStep(t *testing.T) {
	m := newModel(t)
	before := m.game.Snapshot()
	first, second := m.View(), m.View()
	if first.Content != second.Content || !reflect.DeepEqual(before, m.game.Snapshot()) {
		t.Fatal("rendering changed game state")
	}
}

func TestSaveLoadKeys(t *testing.T) {
	m := newModel(t)
	press(m, "S")
	if _, err := os.Stat(m.savePath); err != nil {
		t.Fatalf("save key did not create file: %v", err)
	}
	initial := m.game.Snapshot()
	press(m, "l")
	press(m, "L")
	if !reflect.DeepEqual(initial, m.game.Snapshot()) {
		t.Fatal("load key did not restore saved state")
	}
	before := m.game
	if err := os.WriteFile(m.savePath, []byte(`{"version":1}`), 0600); err != nil {
		t.Fatal(err)
	}
	press(m, "L")
	if m.game != before || !strings.Contains(m.notice, "version") {
		t.Fatalf("failed load replaced game or hid error: %q", m.notice)
	}
}

func TestRenderShowsCharacterAttributes(t *testing.T) {
	m := newModel(t)
	view := m.View()
	for _, want := range []string{"Human Fighter", "Str:16", "Int:8", "Dex:12"} {
		if !strings.Contains(view.Content, want) {
			t.Fatalf("render missing %q: %s", want, view.Content)
		}
	}
}

func TestCharacterInfoShowsSkillsWithoutTurn(t *testing.T) {
	m := newModel(t)
	press(m, "c")
	content := m.View().Content
	for _, want := range []string{"Skills", "Fighting 3", "Shields 3", "Armour 3", "Short Blades 2"} {
		if !strings.Contains(content, want) {
			t.Fatalf("character view missing %q: %s", want, content)
		}
	}
	if m.game.View().CurrentAut != 0 {
		t.Fatal("character inspection spent a turn")
	}
	press(m, "c")
	if strings.Contains(m.View().Content, "Short Blades 2") || m.game.View().CurrentAut != 0 {
		t.Fatal("character view did not close freely")
	}
}

func TestMalformedLoadPreservesLiveGame(t *testing.T) {
	for _, test := range []struct {
		name   string
		mutate func(*save.Snapshot)
	}{
		{"item health", func(snapshot *save.Snapshot) {
			for i := range snapshot.Entities {
				if snapshot.Entities[i].Item != nil {
					snapshot.Entities[i].Health = &ecs.Health{Current: 0, Max: 1}
				}
			}
		}},
		{"clock mismatch", func(snapshot *save.Snapshot) { snapshot.CurrentAut = 100 }},
	} {
		t.Run(test.name, func(t *testing.T) {
			m := newModel(t)
			before := m.game
			snapshot := before.Snapshot()
			test.mutate(&snapshot)
			if err := save.Write(m.savePath, snapshot); err != nil {
				t.Fatal(err)
			}
			press(m, "L")
			if m.game != before || !strings.Contains(m.notice, "Load failed") {
				t.Fatalf("malformed load changed live game: %q", m.notice)
			}
		})
	}
}
