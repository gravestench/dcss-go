package game

import (
	"fmt"

	"crawl/internal/ecs"
	"crawl/internal/script"
	"crawl/internal/vault"

	"github.com/gravestench/akara"
)

// PrepareRegion validates a complete replacement without publishing it.
// The returned mutation swaps the level owner and applies its actor
// permutation together; Undo restores the original owner and positions.
func (grid scriptGrid) PrepareRegion(
	levelID int,
	plan map[string]any,
) (script.RegionChange, error) {
	old := grid.levels[levelID]

	if old == nil {
		return script.RegionChange{}, fmt.Errorf("missing region %d", levelID)
	}

	cells, err := luaScenarioCells(plan["cells"])

	if err != nil {
		return script.RegionChange{}, err
	}

	if len(cells) == 0 ||
		len(cells) != len(old.terrain) ||
		len(cells[0]) != old.width {
		return script.RegionChange{}, fmt.Errorf(
			"region %d changes the level dimensions", levelID)
	}

	depth, err := decisionInteger(plan, "local_depth")

	if err != nil ||
		depth < 1 {
		return script.RegionChange{}, fmt.Errorf(
			"region %d has invalid local depth", levelID)
	}

	next, err := NewLevel(levelID, cells, old.positions)

	if err != nil {
		return script.RegionChange{}, err
	}

	next.BranchID = old.BranchID
	next.LocalDepth = depth
	next.mappingLevel = old.mappingLevel
	next.awaySinceAut = old.awaySinceAut
	next.initialMonsters = old.initialMonsters
	next.initialActors = old.initialActors
	next.spawnExclusions = append([]point(nil), old.spawnExclusions...)
	next.shoalsHeights = cloneRegionHeights(old.shoalsHeights)
	next.tideHeight = old.tideHeight
	next.tideVelocity = old.tideVelocity
	next.tideLastAut = old.tideLastAut
	next.actors = make(map[point]akara.Entity, len(old.actors))

	for cell, actor := range old.actors {
		next.actors[cell] = actor
	}

	if raw, present := plan["initial_monsters"]; present {
		amount, valid := regionInteger(raw)

		if !valid || amount < 0 {
			return script.RegionChange{}, fmt.Errorf(
				"region %d has invalid monster budget", levelID)
		}

		next.initialMonsters = amount
	}

	if raw, present := plan["initial_actors"]; present {
		amount, valid := regionInteger(raw)

		if !valid || amount < 0 {
			return script.RegionChange{}, fmt.Errorf(
				"region %d has invalid initial actor count", levelID)
		}

		next.initialActors = amount
	}

	if err := prepareRegionMetadata(next, plan); err != nil {
		return script.RegionChange{}, err
	}

	retired, retiredPositions, err := grid.prepareRegionRetire(
		old, next, plan["actor_retire"])

	if err != nil {
		return script.RegionChange{}, err
	}

	moves, prior, err := grid.prepareRegionActors(old, next,
		plan["actor_moves"], retiredPositions)

	if err != nil {
		return script.RegionChange{}, err
	}

	applied := false
	change := script.RegionChange{
		Cells:         cells,
		ActorMoves:    moves,
		RetiredActors: retired,
	}

	change.MarkRecords = func(entries []map[string]any) error {
		if applied {
			return fmt.Errorf("region %d is already applied", levelID)
		}

		values := make([]any, len(entries))

		for index, entry := range entries {
			values[index] = entry
		}

		before := vault.Clone(next.vaultRecords)
		err := markMaterializedVaultRecords(
			map[int]*Level{levelID: next}, values)

		if err != nil {
			next.vaultRecords = before
		}

		return err
	}

	change.AddActors = func(count int) error {
		if applied || count < 0 {
			return fmt.Errorf("region %d has invalid actor addition", levelID)
		}

		next.initialActors += count

		return nil
	}

	change.Apply = func() error {
		if applied || grid.levels[levelID] != old {
			return fmt.Errorf("region %d changed before commit", levelID)
		}

		grid.levels[levelID] = next

		if err := grid.MoveActors(moves); err != nil {
			grid.levels[levelID] = old

			return err
		}

		for _, actor := range retired {
			old.positions.Remove(actor)
		}

		applied = true

		return nil
	}

	change.Undo = func() error {
		if !applied || grid.levels[levelID] != next {
			return fmt.Errorf("region %d is not the applied change", levelID)
		}

		for actor, position := range prior {
			current, found := old.positions.Get(actor)

			if !found {
				return fmt.Errorf("region actor %d lost its position", actor)
			}

			*current = position
		}

		for actor, position := range retiredPositions {
			if _, err := old.positions.Set(actor, position); err != nil {
				return fmt.Errorf("restore retired actor %d: %w", actor, err)
			}
		}

		grid.levels[levelID] = old
		applied = false

		return nil
	}

	return change, nil
}

// Retired actors leave the new occupancy index before the survivor move
// validator runs. This lets a survivor occupy a cell vacated at the edge.
// Their ECS positions are removed only when the region is committed.
func (grid scriptGrid) prepareRegionRetire(
	old, next *Level,
	raw any,
) ([]akara.Entity, map[akara.Entity]ecs.Position, error) {
	if raw == nil {
		return nil, map[akara.Entity]ecs.Position{}, nil
	}

	entries, err := luaScenarioList(raw, "region actor retirements")

	if err != nil {
		return nil, nil, err
	}

	actors := make([]akara.Entity, 0, len(entries))
	positions := make(map[akara.Entity]ecs.Position, len(entries))

	for _, value := range entries {
		actor, okay := value.(akara.Entity)

		if !okay || actor == 0 {
			return nil, nil, fmt.Errorf("region retirement has no live actor handle")
		}

		position, found := old.positions.Get(actor)

		if !found {
			return nil, nil, fmt.Errorf("region actor %d is not indexed", actor)
		}

		origin := point{
			x: position.X,
			y: position.Y,
		}

		if position.LevelID != old.ID ||
			old.actors[origin] != actor {
			return nil, nil, fmt.Errorf("region actor %d is not indexed", actor)
		}

		if _, duplicate := positions[actor]; duplicate {
			return nil, nil, fmt.Errorf("region actor %d retired twice", actor)
		}

		positions[actor] = *position
		actors = append(actors, actor)
		delete(next.actors, origin)
	}

	return actors, positions, nil
}

// Keep ordinary level metadata alongside terrain so a vault record or
// stair cannot refer to an invalid cell after the region is published.
func prepareRegionMetadata(level *Level, plan map[string]any) error {
	if raw, present := plan["spawn_exclusions"]; present {
		entries, err := luaScenarioList(raw, "region spawn exclusions")

		if err != nil {
			return err
		}

		level.spawnExclusions = nil

		for _, value := range entries {
			cell, err := luaScenarioPoint(value)

			if err != nil ||
				!level.inBounds(cell.x, cell.y) {
				return fmt.Errorf("region spawn exclusion is invalid")
			}

			level.spawnExclusions = append(level.spawnExclusions, cell)
		}
	}

	if err := loadLuaVault(level, plan); err != nil {
		return err
	}

	stairs, err := luaScenarioList(plan["stairs"], "region stairs")

	if err != nil {
		return err
	}

	for _, value := range stairs {
		link, err := luaScenarioStair(value)

		if err != nil {
			return err
		}

		if err := level.AddStairLink(link); err != nil {
			return err
		}
	}

	if raw, present := plan["known"]; present {
		cells, err := luaScenarioCells(raw)

		if err != nil {
			return err
		}

		if err := level.LoadKnownCells(cells); err != nil {
			return err
		}
	}

	if raw, present := plan["seen"]; present {
		cells, err := regionBoolRows(raw)

		if err != nil {
			return err
		}

		if err := level.LoadSeenCells(cells); err != nil {
			return err
		}
	}

	if raw, present := plan["detected_items"]; present {
		cells, err := regionBoolRows(raw)

		if err != nil {
			return err
		}

		if err := level.LoadDetectedItems(cells); err != nil {
			return err
		}
	}

	return regionCellColours(level, plan["cell_colours"])
}

// Lua numbers cross the policy boundary as int64 only when exactly
// representable. Reject floats and identifiers outside host int range.
func regionInteger(value any) (int, bool) {
	number, okay := value.(int64)

	if !okay || int64(int(number)) != number {
		return 0, false
	}

	return int(number), true
}

// Visibility arrays are copied into the new level, not shared with Lua.
func regionBoolRows(raw any) ([][]bool, error) {
	rows, okay := raw.([]any)

	if !okay {
		return nil, fmt.Errorf("region visibility is not a row list")
	}

	result := make([][]bool, len(rows))

	for y, value := range rows {
		entries, okay := value.([]any)

		if !okay {
			return nil, fmt.Errorf("region visibility row %d is invalid", y)
		}

		row := make([]bool, len(entries))

		for x, entry := range entries {
			visible, okay := entry.(bool)

			if !okay {
				return nil, fmt.Errorf(
					"region visibility cell (%d,%d) is invalid", x, y)
			}

			row[x] = visible
		}

		result[y] = row
	}

	return result, nil
}

// A colour record is validated against the new grid before any live
// colour is replaced, so a bad vault tint cannot leave half a region.
func regionCellColours(level *Level, raw any) error {
	if raw == nil {
		return nil
	}

	entries, err := luaScenarioList(raw, "region cell colours")

	if err != nil {
		return err
	}

	for _, value := range entries {
		record, okay := value.(map[string]any)

		if !okay {
			return fmt.Errorf("region cell colour is not a record")
		}

		x, err := decisionInteger(record, "x")

		if err != nil {
			return err
		}

		y, err := decisionInteger(record, "y")

		if err != nil {
			return err
		}

		colour, okay := record["colour"].(string)

		if !okay || colour == "" {
			return fmt.Errorf("region cell colour is empty")
		}

		if err := level.SetCellColour(x, y, colour); err != nil {
			return err
		}
	}

	return nil
}

// Validate the whole simultaneous actor move before changing occupancy.
// An unmoved actor may stay only on walkable replacement terrain.
func (grid scriptGrid) prepareRegionActors(
	old, next *Level,
	raw any,
	retired map[akara.Entity]ecs.Position,
) ([]script.ActorMove, map[akara.Entity]ecs.Position, error) {
	if raw == nil {
		raw = []any{}
	}

	entries, err := luaScenarioList(raw, "region actor moves")

	if err != nil {
		return nil, nil, err
	}

	moves := make([]script.ActorMove, 0, len(entries))
	prior := make(map[akara.Entity]ecs.Position, len(entries))
	destinations := make(map[point]bool, len(entries))

	for _, value := range entries {
		record, okay := value.(map[string]any)

		if !okay {
			return nil, nil, fmt.Errorf("region actor move is not a record")
		}

		actor, okay := record["actor"].(akara.Entity)

		if !okay || actor == 0 {
			return nil, nil, fmt.Errorf("region actor move has no live handle")
		}

		levelID, err := decisionInteger(record, "level_id")

		if err != nil ||
			levelID != old.ID {
			return nil, nil, fmt.Errorf("region actor move changes ownership")
		}

		x, err := decisionInteger(record, "x")

		if err != nil {
			return nil, nil, err
		}

		y, err := decisionInteger(record, "y")

		if err != nil {
			return nil, nil, err
		}

		position, found := old.positions.Get(actor)

		if !found {
			return nil, nil, fmt.Errorf("region actor %d move is invalid", actor)
		}

		target := point{
			x: x,
			y: y,
		}

		origin := point{
			x: position.X,
			y: position.Y,
		}

		_, alreadyMoving := prior[actor]
		_, alreadyRetired := retired[actor]

		if position.LevelID != old.ID ||
			old.actors[origin] != actor ||
			!next.Walkable(x, y) ||
			alreadyMoving ||
			alreadyRetired ||
			destinations[target] {
			return nil, nil, fmt.Errorf("region actor %d move is invalid", actor)
		}

		prior[actor] = *position
		destinations[target] = true
		moves = append(moves, script.ActorMove{
			Actor:   actor,
			LevelID: old.ID,
			X:       x,
			Y:       y,
		})
	}

	for cell, actor := range old.actors {
		if _, gone := retired[actor]; gone {
			continue
		}

		if _, moving := prior[actor]; moving {
			continue
		}

		if !next.Walkable(cell.x, cell.y) ||
			destinations[cell] {
			return nil, nil, fmt.Errorf(
				"region would block unmoved actor %d", actor)
		}
	}

	return moves, prior, nil
}
