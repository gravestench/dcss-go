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

	blockers := g.opaqueClouds(position.LevelID)
	visible, err := visibility.ComputeWithOpacity(
		level.terrain, position.X, position.Y, int(radius),
		func(x, y int) bool {
			cell := point{
				x: x,
				y: y,
			}

			return blockers[cell]
		},
	)

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

	seenKinds := make([]any, 0)

	for _, entity := range g.stores.Positions.Entities() {
		location, found := g.stores.Positions.Get(entity)

		if !found || location.LevelID != position.LevelID {
			continue
		}

		index := location.Y*level.width + location.X

		if index < 0 || index >= len(visible) || !visible[index] {
			continue
		}

		if item, found := g.stores.Items.Get(entity); found {
			seenKinds = append(seenKinds, item.KindID)
		}
	}

	for _, entity := range g.stores.CarriedBy.Entities() {
		carrier, found := g.stores.CarriedBy.Get(entity)

		if !found || carrier.Holder != g.player {
			continue
		}

		if item, found := g.stores.Items.Get(entity); found {
			seenKinds = append(seenKinds, item.KindID)
		}
	}

	if _, err := g.scripts.Policy("character.record_seen_items", map[string]any{
		"kind_ids": seenKinds,
	}); err != nil {
		return err
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return err
	}

	return nil
}
