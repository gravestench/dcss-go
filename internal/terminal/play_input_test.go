package terminal

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/game"
)

func playingModel(t *testing.T) *AppModel {
	t.Helper()
	m := pregameModel(t)
	enterName(m, "Alice")

	pressApp(m, "enter")
	pressApp(m, "j")

	pressApp(m, "a")
	pressApp(m, "a")

	if m.screen != ScreenPlay || m.game == nil {
		t.Fatalf("could not start run: %v / %s", m.screen, m.notice)
	}

	return m
}

func TestPlayKeysSourceBindingsAndTurnCost(t *testing.T) {
	expect := func(key string, kind game.CommandKind, dx, dy int) {
		t.Helper()
		command, ok := CommandForKey(key)

		if !ok ||
			command.Kind != kind ||
			command.DX != dx ||
			command.DY != dy {
			t.Fatalf("%q: %+v, %v", key, command, ok)
		}
	}

	expect("h", game.CommandMove, -1, 0)
	expect("l", game.CommandMove, 1, 0)

	expect("j", game.CommandMove, 0, 1)
	expect("k", game.CommandMove, 0, -1)

	expect("y", game.CommandMove, -1, -1)
	expect("u", game.CommandMove, 1, -1)

	expect("b", game.CommandMove, -1, 1)
	expect("n", game.CommandMove, 1, 1)

	expect("home", game.CommandMove, -1, -1)
	expect("end", game.CommandMove, -1, 1)

	expect("pgup", game.CommandMove, 1, -1)
	expect("pgdown", game.CommandMove, 1, 1)

	expect("s", game.CommandWait, 0, 0)
	expect(".", game.CommandWait, 0, 0)

	expect("g", game.CommandPickup, 0, 0)
	expect(",", game.CommandPickup, 0, 0)

	expect("<", game.CommandUpstairs, 0, 0)
	expect(">", game.CommandDownstairs, 0, 0)

	for _, key := range []string{
		"q",
		"L",
		"m",
		"S",
		"ctrl+s",
		"ctrl+q",
	} {
		if _, ok := CommandForKey(key); ok {
			t.Fatalf("UI/stub key %q became a game command", key)
		}
	}

	m := playingModel(t)
	base := m.game.View().CurrentAut
	m.handleKey("s")

	if m.game.View().CurrentAut <= base {
		t.Fatal("wait did not spend time")
	}

	base = m.game.View().CurrentAut

	for _, key := range []string{
		"q",
		"L",
		"g",
		"<",
		"i",
		"m",
		"?",
	} {
		m.handleKey(key)

		if key == "q" && m.screen != ScreenQuaff {
			t.Fatal("q did not open potion choice")
		}

		if key == "L" && !strings.Contains(m.notice, "unavailable") {
			t.Fatalf("%q did not explain unavailable action", key)
		}

		if m.screen != ScreenPlay {
			m.handleKey("esc")
		}

		if m.game.View().CurrentAut != base {
			t.Fatalf("%q spent time", key)
		}
	}
}

func TestSaveExitConfirmationAndFailure(t *testing.T) {
	m := playingModel(t)
	aut := m.game.View().CurrentAut
	m.handleKey("S")

	if m.screen != ScreenConfirm || !strings.Contains(plainApp(m), "Save game and exit?") {
		t.Fatal("save confirmation missing")
	}

	m.handleKey("n")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != aut {
		t.Fatal("save cancellation changed run")
	}

	m.savePath = filepath.Join(t.TempDir(), "missing", "run.json")
	m.handleKey("S")
	cmd := m.handleKey("y")

	if cmd != nil || m.screen != ScreenPlay ||
		!strings.Contains(m.notice, "Save failed") || m.game.View().CurrentAut != aut {
		t.Fatalf("failed save changed run: screen %v, notice %q", m.screen, m.notice)
	}

	m.savePath = filepath.Join(t.TempDir(), "run.json")
	m.handleKey("S")
	cmd = m.handleKey("y")

	if cmd == nil {
		t.Fatal("successful save did not exit")
	}

	if _, err := os.Stat(m.savePath); err != nil {
		t.Fatal(err)
	}
}

func TestSaveExitImmediateAndQuit(t *testing.T) {
	m := playingModel(t)

	if cmd := m.handleKey("ctrl+s"); cmd == nil {
		t.Fatal("Ctrl-S did not save and exit")
	}

	if _, err := os.Stat(m.savePath); err != nil {
		t.Fatal(err)
	}

	m = playingModel(t)
	aut := m.game.View().CurrentAut
	m.handleKey("ctrl+q")

	if m.screen != ScreenConfirm || !strings.Contains(plainApp(m), "abandon") {
		t.Fatal("abandonment confirmation missing")
	}

	m.handleKey("n")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != aut {
		t.Fatal("abandonment cancellation changed run")
	}

	m.handleKey("ctrl+q")
	m.handleKey("y")

	if m.screen != ScreenDeath || m.game.View().CurrentAut != aut {
		t.Fatal("abandonment did not enter terminal state")
	}
}

func TestDeathTransitionAfterStep(t *testing.T) {
	m := playingModel(t)
	m.afterStep(game.StepResult{View: game.View{PlayerDead: true}})

	if m.screen != ScreenDeath || !strings.Contains(plainApp(m), "You die") {
		t.Fatal("death did not enter terminal state")
	}

	m.handleKey("enter")

	if m.screen != ScreenStartup || m.game != nil {
		t.Fatal("death could not return to startup")
	}
}

func TestStatChoiceTransitionAfterStep(t *testing.T) {
	m := playingModel(t)
	m.afterStep(game.StepResult{
		View: game.View{PendingStatLevel: 3},
	})

	if m.screen != ScreenStatChoice {
		t.Fatalf("pending stat choice screen = %d", m.screen)
	}

	if !strings.Contains(plainApp(m), "Increase (S)trength") {
		t.Fatal("stat choice prompt is missing")
	}

	m.handleStatChoiceKey("x")

	if m.screen != ScreenStatChoice || m.notice == "" {
		t.Fatalf("invalid stat key changed screen: %d, notice %q", m.screen, m.notice)
	}
}
