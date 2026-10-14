package main

import (
	"flag"
	"fmt"
	"os"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/terminal"
)

func run() error {
	seed := flag.Uint64("seed", 1, "deterministic scenario seed")
	savePath := flag.String("save", "dcrawl-save.json", "save file path")
	modDir := flag.String("mod-dir", "", "optional Lua overlay directory")
	allowMismatch := flag.Bool(
		"allow-ruleset-mismatch",
		false,
		"explicitly load a save made with different Lua files",
	)
	flag.Parse()

	rules, err := modfs.Load(*modDir)

	if err != nil {
		return fmt.Errorf("load Lua rules: %w", err)
	}

	catalog, err := content.LoadDefault()

	if err != nil {
		return fmt.Errorf("load content: %w", err)
	}

	model, err := terminal.NewAppModelWithRules(
		catalog,
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
