package terminal

import (
	"path/filepath"
	"testing"

	"crawl/internal/game"
	"crawl/internal/modfs"
)

func TestLuaPlayKeyOverrideChangesBindingAndRulesetHash(t *testing.T) {
	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	modded, err := modfs.Load("testdata/play-key-mod")

	if err != nil {
		t.Fatal(err)
	}

	if bundled.Hash() == modded.Hash() {
		t.Fatal("play key override kept the bundled ruleset hash")
	}

	model, err := NewAppModelWithRules(
		17,
		filepath.Join(t.TempDir(), "run.json"),
		modded,
		game.RestorePolicy{},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer model.Close()

	enterName(model, "Alice")
	pressApp(model, "enter")
	pressApp(model, "j")
	pressApp(model, "a")
	pressApp(model, "a")

	if model.screen != ScreenPlay {
		t.Fatalf("modded run did not reach play: %s", model.notice)
	}

	before := model.game.View().CurrentAut
	model.handleKey("z")

	if model.game.View().CurrentAut <= before {
		t.Fatal("modded z key did not spend a wait turn")
	}
}

func TestMalformedLuaInputKeepsTerminalAndGameState(t *testing.T) {
	rules, err := modfs.Load("testdata/malformed-key-mod")

	if err != nil {
		t.Fatal(err)
	}

	model, err := NewAppModelWithRules(
		17,
		filepath.Join(t.TempDir(), "run.json"),
		rules,
		game.RestorePolicy{},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer model.Close()

	enterName(model, "Alice")
	pressApp(model, "enter")
	pressApp(model, "j")
	pressApp(model, "a")
	pressApp(model, "a")

	if model.screen != ScreenPlay {
		t.Fatalf("modded run did not reach play: %s", model.notice)
	}

	beforeAut := model.game.View().CurrentAut
	beforeScreen := model.screen
	beforePrevious := model.previous
	beforeFocus := model.focus

	model.handleKey("z")

	if model.game.View().CurrentAut != beforeAut {
		t.Fatal("malformed input spent game time")
	}

	if model.screen != beforeScreen ||
		model.previous != beforePrevious ||
		model.focus != beforeFocus {
		t.Fatal("malformed input changed terminal navigation state")
	}

	if model.notice != "Input policy returned an invalid screen." {
		t.Fatalf("malformed input notice = %q", model.notice)
	}
}

func TestLuaInputRejectsGameScreenBeforeGameStarts(t *testing.T) {
	rules, err := modfs.Load("testdata/invalid-navigation-mod")

	if err != nil {
		t.Fatal(err)
	}

	model, err := NewAppModelWithRules(
		17,
		filepath.Join(t.TempDir(), "run.json"),
		rules,
		game.RestorePolicy{},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer model.Close()

	model.handleKey("z")

	if model.screen != ScreenStartup || model.game != nil {
		t.Fatal("invalid navigation entered a game screen before game start")
	}

	if model.notice == "" {
		t.Fatal("invalid navigation had no diagnostic notice")
	}

	model.handleKey("x")

	if model.screen != ScreenStartup || model.game != nil {
		t.Fatal("game action executed before game start")
	}
}

func TestLuaInputCannotMutateGameThroughContext(t *testing.T) {
	rules, err := modfs.Load("testdata/stateful-key-mod")

	if err != nil {
		t.Fatal(err)
	}

	model, err := NewAppModelWithRules(
		17,
		filepath.Join(t.TempDir(), "run.json"),
		rules,
		game.RestorePolicy{},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer model.Close()

	enterName(model, "Alice")
	pressApp(model, "enter")
	pressApp(model, "j")
	pressApp(model, "a")
	pressApp(model, "a")

	if model.screen != ScreenPlay {
		t.Fatalf("modded run did not reach play: %s", model.notice)
	}

	before := model.game.Snapshot()
	model.handleKey("z")
	after := model.game.Snapshot()

	if len(after.Entities) != len(before.Entities) {
		t.Fatal("input policy created an entity in the live game")
	}

	if after.CurrentAut != before.CurrentAut {
		t.Fatal("rejected input policy spent game time")
	}

	if model.screen != ScreenPlay {
		t.Fatal("rejected input policy changed screens")
	}
}

func TestMalformedDropQuantityKeepsMenuState(t *testing.T) {
	model := playingModel(t)

	model.screen = ScreenDrop
	model.dropQuantity = "12"

	model.applyInputDecision(map[string]any{
		"action": "drop_quantity",
		"value":  "twelve",
	})

	if model.screen != ScreenDrop || model.dropQuantity != "12" {
		t.Fatal("malformed drop quantity changed menu state")
	}

	if model.notice == "" {
		t.Fatal("malformed drop quantity had no diagnostic notice")
	}
}

func TestLuaInputRejectsIncompleteMove(t *testing.T) {
	_, err := playCommandFromDecision(map[string]any{
		"kind": int64(game.CommandMove),
	})

	if err == nil {
		t.Fatal("move without a direction was accepted")
	}
}
