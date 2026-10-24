package game

import (
	"fmt"

	"crawl/internal/ecs"
)

const pendingShaftSchema = "world.pending_shaft"

// shaftPortal is a prepared fall from one floor to another. Lua owns the
// destination rule; this kernel transaction owns the occupied grid cells.
type shaftPortal struct {
	toLevelID int
	landing   point
}

func (portal *shaftPortal) staged() *stagedLevel {
	return nil
}

func (portal *shaftPortal) retiredLevelID() int {
	return 0
}

// The source floor remains loaded. Clear the action request only after the
// move succeeds, so a failed transaction can restore its prior snapshot.
func (portal *shaftPortal) commit(g *Game) (Event, error) {
	grid := scriptGrid{levels: g.levels}

	if err := grid.MoveActor(g.player, portal.toLevelID,
		portal.landing.x, portal.landing.y); err != nil {
		return Event{}, err
	}

	g.scripts.Components()[pendingShaftSchema].Remove(g.player)

	return Event{}, nil
}

// Read only a registered typed component. The request may be created by a
// card during command preparation, so Step checks it after Lua commits.
func (g *Game) pendingShaft() (map[string]any, bool, error) {
	store := g.scripts.Components()[pendingShaftSchema]
	state, found := store.Get(g.player)

	if !found {
		return nil, false, nil
	}

	values, err := state.Snapshot()

	if err != nil {
		return nil, false, err
	}

	return values, true, nil
}

// Lua owns the source safe-landing search, including terrain, clouds, and
// hostile sight. Go only validates its coordinate against the live grid.
func (g *Game) shaftLanding(level *Level) (point, error) {
	decision, err := g.scripts.Policy("world.shaft_landing", map[string]any{
		"level_id": level.ID,
	})

	if err != nil {
		return point{}, err
	}

	landing, err := luaScenarioPoint(decision)

	if err != nil {
		return point{}, fmt.Errorf("shaft landing: %w", err)
	}

	if !level.Walkable(landing.x, landing.y) {
		return point{}, fmt.Errorf("shaft landing is not walkable")
	}

	if _, occupied := level.ActorAt(landing.x, landing.y); occupied {
		return point{}, fmt.Errorf("shaft landing is occupied")
	}

	return landing, nil
}

// The next floor's pending stair is a generation anchor, even though a
// shaft does not make the player stand on that stair. Reuse the same map
// and population pipeline so unseen floors have ordinary saved links.
func (g *Game) generateShaftDestination(
	branchID string,
	depth int,
	position *ecs.Position,
) error {
	if g.scenarioID != generatedDungeonScenarioID {
		return fmt.Errorf("shaft destination %s:%d is not generated",
			branchID, depth)
	}

	parent := g.levels[position.LevelID]

	if parent == nil ||
		parent.BranchID != branchID ||
		depth <= parent.LocalDepth {
		return fmt.Errorf("shaft has no generated parent floor")
	}

	for nextDepth := parent.LocalDepth + 1; nextDepth <= depth; nextDepth++ {
		var existing *Level

		for _, level := range g.levels {
			if level.BranchID == branchID &&
				level.LocalDepth == nextDepth {
				existing = level

				break
			}
		}

		if existing != nil {
			parent = existing

			continue
		}

		var selected StairLink

		for _, link := range parent.StairLinks() {
			if link.Pending &&
				link.TargetBranchID == "" &&
				link.ToLevelID > 0 {
				selected = link

				break
			}
		}

		if selected.ToLevelID == 0 {
			return fmt.Errorf("shaft has no downward generation link from %s:%d",
				branchID, parent.LocalDepth)
		}

		generated, err := g.generateNextFloor(parent.ID, selected)

		if err != nil {
			return err
		}

		if err := g.populateNextFloorResult(generated); err != nil {
			return err
		}

		parent = g.levels[selected.ToLevelID]
	}

	return nil
}

// Match Lua's branch and local depth against live levels, not an assumed
// Dungeon numeric ID. Generation of a missing floor is added separately.
func (g *Game) prepareShaftPortal(
	request map[string]any,
	position *ecs.Position,
) (portalAction, error) {
	origin, err := decisionInteger(request, "origin_level_id")

	if err != nil {
		return nil, fmt.Errorf("shaft request has wrong origin: %w", err)
	}

	if origin != position.LevelID {
		return nil, fmt.Errorf("shaft request origin %d differs from current level %d",
			origin, position.LevelID)
	}

	branchID, okay := request["branch_id"].(string)

	if !okay || branchID == "" {
		return nil, fmt.Errorf("shaft request has no branch")
	}

	depth, err := decisionInteger(request, "local_depth")

	if err != nil {
		return nil, fmt.Errorf("shaft request has invalid depth: %w", err)
	}

	if depth <= 0 {
		return nil, fmt.Errorf("shaft request has invalid depth %d", depth)
	}

	source := g.levels[position.LevelID]

	if source == nil ||
		source.BranchID != branchID ||
		depth <= source.LocalDepth ||
		depth > source.LocalDepth+3 {
		return nil, fmt.Errorf("shaft destination %s:%d is not below current floor",
			branchID, depth)
	}

	var target *Level

	for _, level := range g.levels {
		if level.BranchID == branchID && level.LocalDepth == depth {
			target = level

			break
		}
	}

	if target == nil {
		if err := g.generateShaftDestination(branchID,
			depth, position); err != nil {
			return nil, err
		}

		for _, level := range g.levels {
			if level.BranchID == branchID &&
				level.LocalDepth == depth {
				target = level

				break
			}
		}

		if target == nil {
			return nil, fmt.Errorf("shaft destination %s:%d was not staged",
				branchID, depth)
		}
	}

	landing, err := g.shaftLanding(target)

	if err != nil {
		return nil, err
	}

	return &shaftPortal{
		toLevelID: target.ID,
		landing:   landing,
	}, nil
}
