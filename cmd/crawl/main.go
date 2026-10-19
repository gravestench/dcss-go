package main

import (
	"flag"
	"fmt"
	"os"

	tea "charm.land/bubbletea/v2"
	"crawl/internal/game"
	"crawl/internal/modfs"
	"crawl/internal/terminal"
)

func run() error {
	seed := flag.Uint64("seed", 1, "deterministic scenario seed")
	savePath := flag.String("save", "crawl-save.json", "save file path")
	var modDirectories modDirs
	flag.Var(&modDirectories, "mod-dir", "ordered Lua mod directory (repeatable)")
	allowMismatch := flag.Bool(
		"allow-ruleset-mismatch",
		false,
		"explicitly load a save made with different Lua files",
	)
	flag.Parse()

	rules, err := modfs.Load(modDirectories...)

	if err != nil {
		return fmt.Errorf("load Lua rules: %w", err)
	}

	model, err := terminal.NewAppModelWithRules(
		*seed,
		*savePath,
		rules,
		game.RestorePolicy{
			AllowRulesetMismatch: *allowMismatch,
		},
	)

	if err != nil {
		return fmt.Errorf("prepare start: %w", err)
	}

	defer model.Close()
	_, err = tea.NewProgram(model).Run()

	if err != nil {
		return fmt.Errorf("terminal: %w", err)
	}

	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
