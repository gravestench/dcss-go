package game

import (
	"fmt"

	"dcrawl-go/internal/visibility"
)

// refreshVisibility updates only the current player's derived sight and the
// terrain that player has actually seen on the current level.
func (g *Game) refreshVisibility() error {
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		return fmt.Errorf("player %d has no position", g.player)
	}

	level := g.levels[position.LevelID]

	if level == nil {
		return fmt.Errorf("player level %d is missing", position.LevelID)
	}

	sight, err := g.scripts.Policy("character.vision", nil)

	if err != nil {
		return err
	}

	radius, ok := sight["radius"].(int64)

	if !ok {
		return fmt.Errorf("Lua character vision has no integer radius")
	}

	visible, err := visibility.Compute(level.terrain, position.X, position.Y, int(radius))

	if err != nil {
		return err
	}

	newlySeen, err := level.Remember(visible)

	if err != nil {
		return err
	}

	if err := g.applyExploration(level, newlySeen); err != nil {
		return err
	}

	if err := g.applyItemDetection(level, position.X, position.Y, visible); err != nil {
		return err
	}

	g.visible = visible
	g.visibleLevelID = position.LevelID

	return nil
}
