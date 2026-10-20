package game

import (
	"fmt"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

// scenarioLevels is the terrain returned by the effective Lua ruleset.
// The Go constructor attaches entities and systems to these levels.
type scenarioLevels struct {
	levels            map[int]*Level
	entry             point
	populationEntries map[int]point
	spawnExclusions   map[int][]point
	startingItems     []any
}

// buildScriptScenario asks the effective Lua ruleset for terrain and links.
// Level remains the Go grid and occupancy owner after generation finishes.
func (g *Game) buildScriptScenario(
	scenarioID string,
	positions *akara.Store[ecs.Position],
	speciesID, playerName string,
) (scenarioLevels, error) {
	policyID := "world.generate_scenario"

	if scenarioID == generatedDungeonScenarioID {
		policyID = "world.generate_first_floor"
	}

	result, err := g.scripts.Policy(policyID, map[string]any{
		"scenario_id":       scenarioID,
		"player_species_id": speciesID,
		"player_name":       playerName,
	})

	if err != nil {
		return scenarioLevels{}, err
	}

	if scenarioID == generatedDungeonScenarioID {
		if err := g.acceptLuaBranchSchedule(result["branch_schedule"]); err != nil {
			return scenarioLevels{}, err
		}

		if err := g.acceptLuaTemplePlan(result["temple_plan"]); err != nil {
			return scenarioLevels{}, err
		}
	}

	records, ok := result["levels"].([]any)

	if !ok || len(records) == 0 {
		return scenarioLevels{}, fmt.Errorf("Lua scenario returned no levels")
	}

	entries, exclusions, links, err := g.decodeLuaLevelRecords(records, positions)

	if err != nil {
		return scenarioLevels{}, err
	}

	for id, records := range links {
		for _, value := range records {
			stair, err := luaScenarioStair(value)

			if err != nil {
				return scenarioLevels{}, fmt.Errorf("Lua level %d stair: %w", id, err)
			}

			if err := g.levels[id].AddStairLink(stair); err != nil {
				return scenarioLevels{}, err
			}
		}
	}

	if err := validateStairLinks(g.levels); err != nil {
		return scenarioLevels{}, err
	}

	entry, err := luaScenarioPoint(result["entry"])

	if err != nil {
		return scenarioLevels{}, err
	}

	startingItems, err := luaScenarioList(result["starting_items"], "starting items")

	if err != nil {
		return scenarioLevels{}, err
	}

	return scenarioLevels{
		levels:            g.levels,
		entry:             entry,
		populationEntries: entries,
		spawnExclusions:   exclusions,
		startingItems:     startingItems,
	}, nil
}

// Empty Lua arrays decode as empty tables, so accept both shapes at the
// policy boundary. Nonempty records must remain ordered arrays.
func luaScenarioList(value any, label string) ([]any, error) {
	if entries, ok := value.([]any); ok {
		return entries, nil
	}

	if table, ok := value.(map[string]any); ok && len(table) == 0 {
		return []any{}, nil
	}

	return nil, fmt.Errorf("Lua %s are not a list", label)
}

// decodeLuaLevelRecords installs grids and authored metadata before their
// links, allowing a newly entered floor to use the same decoder as startup.
func (g *Game) decodeLuaLevelRecords(
	records []any,
	positions *akara.Store[ecs.Position],
) (map[int]point, map[int][]point, map[int][]any, error) {
	entries := make(map[int]point, len(records))
	exclusions := make(map[int][]point, len(records))
	links := make(map[int][]any, len(records))

	for _, value := range records {
		record, ok := value.(map[string]any)

		if !ok {
			return nil, nil, nil, fmt.Errorf("Lua level has invalid type %T", value)
		}

		id, err := decisionInteger(record, "id")

		if err != nil {
			return nil, nil, nil, err
		}

		cells, err := luaScenarioCells(record["cells"])

		if err != nil {
			return nil, nil, nil, fmt.Errorf("Lua level %d: %w", id, err)
		}

		level, err := NewLevel(id, cells, positions)

		if err != nil {
			return nil, nil, nil, err
		}

		branchID, ok := record["branch_id"].(string)

		if !ok || branchID == "" {
			return nil, nil, nil, fmt.Errorf("Lua level %d has no branch ID", id)
		}

		level.BranchID = branchID

		localDepth, err := decisionInteger(record, "local_depth")

		if err != nil || localDepth < 1 {
			return nil, nil, nil, fmt.Errorf("Lua level %d has invalid local depth", id)
		}

		level.LocalDepth = localDepth

		if raw, present := record["spawn_exclusions"]; present {
			points, ok := raw.([]any)

			if empty, isTable := raw.(map[string]any); isTable && len(empty) == 0 {
				points = []any{}
				ok = true
			}

			if !ok {
				return nil, nil, nil, fmt.Errorf("Lua level %d spawn exclusions are not a list", id)
			}

			for _, value := range points {
				cell, pointErr := luaScenarioPoint(value)

				if pointErr != nil {
					return nil, nil, nil, fmt.Errorf(
						"Lua level %d spawn exclusion: %w",
						id,
						pointErr,
					)
				}

				if cell.x < 0 ||
					cell.x >= level.width ||
					cell.y < 0 ||
					cell.y >= len(level.terrain) {
					return nil, nil, nil, fmt.Errorf("Lua level %d has invalid spawn exclusion", id)
				}

				exclusions[id] = append(exclusions[id], cell)
			}
		}

		level.spawnExclusions = append([]point(nil), exclusions[id]...)

		if err := loadLuaVault(level, record); err != nil {
			return nil, nil, nil, err
		}

		if branchID == shoalsBranchID {
			level.InitShoalsTide()

			if raw, present := record["heightmap"]; present {
				heights, heightErr := luaShoalsHeights(raw)

				if heightErr != nil {
					return nil, nil, nil, fmt.Errorf("Lua level %d: %w", id, heightErr)
				}

				if err := level.SetShoalsHeights(heights); err != nil {
					return nil, nil, nil, err
				}
			}
		} else if _, present := record["heightmap"]; present {
			return nil, nil, nil, fmt.Errorf("Lua level %d heightmap is outside Shoals", id)
		}

		level.initialMonsters, err = decisionInteger(record, "initial_monsters")

		if err != nil {
			return nil, nil, nil, err
		}

		entryX, err := decisionInteger(record, "entry_x")

		if err != nil {
			return nil, nil, nil, err
		}

		entryY, err := decisionInteger(record, "entry_y")

		if err != nil {
			return nil, nil, nil, err
		}

		if g.levels[id] != nil {
			return nil, nil, nil, fmt.Errorf("duplicate Lua level %d", id)
		}

		g.levels[id] = level
		entries[id] = point{
			x: entryX,
			y: entryY,
		}

		stairs, ok := record["stairs"].([]any)

		if !ok {
			return nil, nil, nil, fmt.Errorf("Lua level %d has no stair links", id)
		}

		links[id] = stairs
	}

	return entries, exclusions, links, nil
}

func luaScenarioCells(value any) ([][]terrain.ID, error) {
	entries, ok := value.([]any)

	if !ok {
		return nil, fmt.Errorf("terrain cells are not a list")
	}

	cells := make([][]terrain.ID, len(entries))

	for index, entry := range entries {
		row, ok := entry.([]any)

		if !ok {
			return nil, fmt.Errorf("terrain row %d is not a list", index)
		}

		cells[index] = make([]terrain.ID, len(row))

		for x, value := range row {
			feature, ok := value.(string)

			if !ok {
				return nil, fmt.Errorf("terrain cell (%d,%d) is not a feature ID", x, index)
			}

			cells[index][x] = terrain.ID(feature)
		}
	}

	return cells, nil
}

// A Shoals generator may author intermediate elevations instead of deriving
// threshold heights from the final visible feature of each cell.
func luaShoalsHeights(value any) ([][]int, error) {
	rows, ok := value.([]any)

	if !ok {
		return nil, fmt.Errorf("Shoals heightmap is not a list")
	}

	heights := make([][]int, len(rows))

	for y, entry := range rows {
		row, ok := entry.([]any)

		if !ok {
			return nil, fmt.Errorf("Shoals heightmap row %d is not a list", y)
		}

		heights[y] = make([]int, len(row))

		for x, value := range row {
			height, ok := value.(int64)

			if !ok {
				return nil, fmt.Errorf("Shoals heightmap cell (%d,%d) is not an integer", x, y)
			}

			heights[y][x] = int(height)
		}
	}

	return heights, nil
}

func luaScenarioPoint(value any) (point, error) {
	record, ok := value.(map[string]any)

	if !ok {
		return point{}, fmt.Errorf("Lua scenario point is not a record")
	}

	x, err := decisionInteger(record, "x")

	if err != nil {
		return point{}, err
	}

	y, err := decisionInteger(record, "y")

	if err != nil {
		return point{}, err
	}

	return point{
		x: x,
		y: y,
	}, nil
}

func luaScenarioStair(value any) (StairLink, error) {
	record, ok := value.(map[string]any)

	if !ok {
		return StairLink{}, fmt.Errorf("stair is not a record")
	}

	fields := []string{
		"x",
		"y",
		"to_level_id",
		"to_x",
		"to_y",
	}

	numbers := make([]int, len(fields))

	for index, field := range fields {
		value, err := decisionInteger(record, field)

		if err != nil {
			return StairLink{}, err
		}

		numbers[index] = value
	}

	unavailable, ok := record["unavailable"].(string)

	if !ok {
		return StairLink{}, fmt.Errorf("stair availability is not text")
	}

	pending := false

	if raw, present := record["pending"]; present {
		pending, ok = raw.(bool)

		if !ok {
			return StairLink{}, fmt.Errorf("stair pending state is not a boolean")
		}
	}

	targetBranchID := ""
	sourceFeature := ""

	if raw, present := record["target_branch_id"]; present {
		targetBranchID, ok = raw.(string)

		if !ok {
			return StairLink{}, fmt.Errorf("stair target branch ID is not text")
		}
	}

	if raw, present := record["source_feature"]; present {
		sourceFeature, ok = raw.(string)

		if !ok {
			return StairLink{}, fmt.Errorf("stair source feature is not text")
		}
	}

	return StairLink{
		X:              numbers[0],
		Y:              numbers[1],
		ToLevelID:      numbers[2],
		ToX:            numbers[3],
		ToY:            numbers[4],
		Pending:        pending,
		Unavailable:    unavailable,
		TargetBranchID: targetBranchID,
		SourceFeature:  sourceFeature,
	}, nil
}
