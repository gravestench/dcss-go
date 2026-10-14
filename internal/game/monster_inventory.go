package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// A dead monster releases its item entities onto its own cell. The item keeps
// its identity and properties, so combat, pickup, and save all see one object.
func (g *Game) dropMonsterInventory(monsterID akara.Entity, cell ecs.Position) error {
	for _, itemID := range g.stores.CarriedBy.Entities() {
		carrier, found := g.stores.CarriedBy.Get(itemID)

		if !found || carrier.Holder != monsterID {
			continue
		}

		if !g.stores.Items.Has(itemID) || g.stores.Positions.Has(itemID) {
			return fmt.Errorf("monster %d has invalid carried item %d", monsterID, itemID)
		}

		g.stores.Equipped.Remove(itemID)

		if !g.stores.CarriedBy.Remove(itemID) {
			return fmt.Errorf("monster %d lost item %d carrier", monsterID, itemID)
		}

		if _, err := g.stores.Positions.Set(itemID, cell); err != nil {
			return fmt.Errorf("place dropped item %d: %w", itemID, err)
		}
	}

	return nil
}
