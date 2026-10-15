package script

import (
	"fmt"

	"dcrawl-go/internal/terrain"
	"github.com/gravestench/akara"
)

// stagedActorAt includes movements made earlier in the same Lua action.
// The grid itself changes only when ApplyPending reaches the action barrier.
func (r *Runtime) stagedActorAt(cell gridCell) (akara.Entity, bool) {
	if actor, changed := r.pendingActors[cell]; changed {
		return actor, actor != 0 && !r.pendingDestroy[actor]
	}

	actor, found := r.services.Grid.ActorAt(cell.levelID, cell.x, cell.y)

	return actor, found && !r.pendingDestroy[actor]
}

func (r *Runtime) stagedWalkable(cell gridCell) bool {
	if feature, changed := r.pendingCells[cell]; changed {
		return terrain.Walkable(feature)
	}

	return r.services.Grid.Walkable(cell.levelID, cell.x, cell.y)
}

func (r *Runtime) stagedPosition(entity akara.Entity) (gridCell, bool, error) {
	if position, changed := r.pendingPositions[entity]; changed {
		if position == nil {
			return gridCell{}, false, nil
		}

		return *position, true, nil
	}

	target := componentTarget{
		entity: entity,
		name:   "core.position",
	}

	if view, changed := r.pendingViews[target]; changed {
		if !view.present {
			return gridCell{}, false, nil
		}

		return gridCellFromValues(view.values)
	}

	host, found := r.hostComponents["core.position"]

	if !found {
		return gridCell{}, false, fmt.Errorf("grid requires core.position")
	}

	values, present := host.Get(entity)

	if !present {
		return gridCell{}, false, nil
	}

	return gridCellFromValues(values)
}

func gridCellFromValues(values map[string]any) (gridCell, bool, error) {
	levelID, levelOK := values["level_id"].(int64)
	x, xOK := values["x"].(int64)
	y, yOK := values["y"].(int64)

	if !levelOK ||
		!xOK ||
		!yOK {
		return gridCell{}, false, fmt.Errorf("core.position has invalid coordinates")
	}

	return gridCell{
		levelID: int(levelID),
		x:       int(x),
		y:       int(y),
	}, true, nil
}

func (r *Runtime) stageActorPosition(
	actor akara.Entity,
	old *gridCell,
	next *gridCell,
) {
	if old != nil {
		r.pendingActors[*old] = 0
	}

	if next != nil {
		r.pendingActors[*next] = actor
	}

	r.pendingPositions[actor] = next

	target := componentTarget{
		entity: actor,
		name:   "core.position",
	}

	if next == nil {
		r.pendingViews[target] = &pendingComponent{}

		return
	}

	r.pendingViews[target] = &pendingComponent{
		present: true,
		values: map[string]any{
			"level_id": int64(next.levelID),
			"x":        int64(next.x),
			"y":        int64(next.y),
		},
	}
}
