package main

import (
	"flag"
	"fmt"
	"os"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/terminal"
)

func run() error {
	seed := flag.Uint64("seed", 1, "deterministic scenario seed")
	savePath := flag.String("save", "dcrawl-save.json", "save file path")
	flag.Parse()
	catalog, err := content.LoadDefault()
	if err != nil {
		return fmt.Errorf("load content: %w", err)
	}
	model, err := terminal.NewAppModel(catalog, *seed, *savePath)
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
