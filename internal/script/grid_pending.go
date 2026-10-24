package script

import (
	"fmt"

	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

// stagedActorAt includes movements made earlier in the same Lua action.
// The grid itself changes only when ApplyPending reaches the action barrier.
func (r *Runtime) stagedActorAt(cell gridCell) (akara.Entity, bool) {
	if _, changed := r.pendingActors[cell]; !changed &&
		r.services.Grid != nil {
		actor, found := r.services.Grid.ActorAt(
			cell.levelID, cell.x, cell.y,
		)

		if found && !r.pendingDestroy[actor] {
			return actor, true
		}

		if !found {
			return 0, false
		}
	}

	actors := r.stagedActorsAt(cell)

	if len(actors) == 0 {
		return 0, false
	}

	return actors[0], true
}

// Staged enumeration applies earlier moves and removals before querying
// the host. Copying protects the pending index from policy callers.
func (r *Runtime) stagedActorsAt(cell gridCell) []akara.Entity {
	actors, changed := r.pendingActors[cell]

	if !changed && r.services.Grid != nil {
		actors = r.services.Grid.ActorsAt(cell.levelID, cell.x, cell.y)
	}

	live := make([]akara.Entity, 0, len(actors))

	for _, actor := range actors {
		if !r.pendingDestroy[actor] {
			live = append(live, actor)
		}
	}

	return live
}

func (r *Runtime) stagedHasActor(cell gridCell, wanted akara.Entity) bool {
	for _, actor := range r.stagedActorsAt(cell) {
		if actor == wanted {
			return true
		}
	}

	return false
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
	r.stageActorPositionShared(actor, old, next, false)
}

func (r *Runtime) stageActorPositionShared(
	actor akara.Entity,
	old *gridCell,
	next *gridCell,
	primary bool,
) {
	if old != nil {
		actors := r.stagedActorsAt(*old)

		for index, indexed := range actors {
			if indexed == actor {
				actors = append(actors[:index], actors[index+1:]...)
				break
			}
		}

		r.pendingActors[*old] = actors
	}

	if next != nil {
		actors := r.stagedActorsAt(*next)

		if primary {
			actors = append([]akara.Entity{actor}, actors...)
		} else {
			actors = append(actors, actor)
		}

		r.pendingActors[*next] = actors
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
