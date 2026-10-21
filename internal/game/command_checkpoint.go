package game

import (
	"fmt"

	"crawl/internal/save"
)

// restoreCheckpoint replaces every part of a failed portal command, including
// ECS components, grids, scheduler clocks, RNG streams, and the Lua VM. A
// partial reversal here would leave save validation dependent on where the
// error occurred in the travel sequence.
func (g *Game) restoreCheckpoint(snapshot save.Snapshot) error {
	restored, err := RestoreWithRules(snapshot, g.rules, RestorePolicy{})

	if err != nil {
		return fmt.Errorf("restore travel checkpoint: %w", err)
	}

	previous := *g

	*g = *restored

	// The restored VM's service closures initially capture the temporary
	// Game returned by RestoreWithRules. Rebind them to this stable Game
	// pointer before the caller executes another command.
	services, err := g.scriptServices()

	if err != nil {
		*g = previous
		_ = restored.Close()

		return fmt.Errorf("bind restored travel services: %w", err)
	}

	g.scripts.RebindServices(services)

	if err := previous.Close(); err != nil {
		return fmt.Errorf("close failed travel world: %w", err)
	}

	return nil
}
