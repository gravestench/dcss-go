package game

import (
	"fmt"

	"crawl/internal/save"
	"github.com/gravestench/akara"
)

// noteEntity retains the allocator's high-water mark after an entity dies.
// Script creation and the initial player creation are the production paths.
func (g *Game) noteEntity(entity akara.Entity) {
	if uint64(entity) > g.entityCursor {
		g.entityCursor = uint64(entity)
	}
}

// restoreEntityCursor advances Akara's allocator past IDs of dead entities.
// Its explicit-ID restore API updates the cursor; removing the temporary
// entity leaves the live ECS world exactly as it was in the snapshot.
func (g *Game) restoreEntityCursor(snapshot save.Snapshot) error {
	for _, entity := range g.world.Entities() {
		g.noteEntity(entity)
	}

	if snapshot.EntityCursor < g.entityCursor {
		return fmt.Errorf("saved entity cursor %d is below a live entity ID %d",
			snapshot.EntityCursor, g.entityCursor)
	}

	if snapshot.EntityCursor > g.entityCursor {
		cursor := akara.Entity(snapshot.EntityCursor)

		if err := g.world.CreateEntityWithID(cursor); err != nil {
			return fmt.Errorf("restore entity cursor: %w", err)
		}

		g.world.DestroyEntity(cursor)
	}

	g.entityCursor = snapshot.EntityCursor

	return nil
}
