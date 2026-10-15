package game

import (
	"fmt"
)

// applyItemDetection offers current floor-item locations to the Lua sense
// rule. The level keeps only the generic map marker, never the item's kind.
func (g *Game) applyItemDetection(
	level *Level,
	playerX, playerY int,
	visible []bool,
) error {
	items := make([]any, 0)
	locations := make(map[point]bool)

	for _, entity := range g.stores.Items.Entities() {
		position, found := g.stores.Positions.Get(entity)

		if !found || position.LevelID != level.ID {
			continue
		}

		cell := point{
			x: position.X,
			y: position.Y,
		}

		locations[cell] = true
		items = append(items, map[string]any{
			"x": position.X,
			"y": position.Y,
		})
	}

	if len(items) == 0 {
		return nil
	}

	output, err := g.scripts.Policy("world.detect_items", map[string]any{
		"player_x": playerX,
		"player_y": playerY,
		"items":    items,
	})

	if err != nil {
		return err
	}

	detected, err := gridPoints(output["detected"], "item detection")

	if err != nil {
		g.scripts.DiscardPending()

		return err
	}

	for _, cell := range detected {
		if !level.inBounds(cell.x, cell.y) || !locations[cell] {
			g.scripts.DiscardPending()

			return fmt.Errorf("Lua item detection returned a cell without a floor item")
		}
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return err
	}

	for _, cell := range detected {
		if visible[cell.y*level.width+cell.x] {
			continue
		}

		if err := level.DetectItem(cell.x, cell.y); err != nil {
			return err
		}
	}

	return nil
}
