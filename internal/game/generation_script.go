package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// scenarioLevels is the terrain returned by the effective Lua ruleset.
// The Go constructor attaches entities and systems to these levels.
type scenarioLevels struct {
	levels            map[int]*Level
	entry             point
	populationEntries map[int]point
	curing            point
	heal              point
	haste             point
}

// buildScriptScenario asks the effective Lua ruleset for terrain and links.
// Level remains the Go grid and occupancy owner after generation finishes.
func (g *Game) buildScriptScenario(
	scenarioID string,
	positions *akara.Store[ecs.Position],
) (scenarioLevels, error) {
	result, err := g.scripts.Policy("world.generate_scenario", map[string]any{
		"scenario_id": scenarioID,
	})

	if err != nil {
		return scenarioLevels{}, err
	}

	records, ok := result["levels"].([]any)

	if !ok || len(records) == 0 {
		return scenarioLevels{}, fmt.Errorf("Lua scenario returned no levels")
	}

	entries := make(map[int]point, len(records))
	links := make(map[int][]any, len(records))

	for _, value := range records {
		record, ok := value.(map[string]any)

		if !ok {
			return scenarioLevels{}, fmt.Errorf("Lua level has invalid type %T", value)
		}

		id, err := decisionInteger(record, "id")

		if err != nil {
			return scenarioLevels{}, err
		}

		rows, err := luaScenarioRows(record["rows"])

		if err != nil {
			return scenarioLevels{}, fmt.Errorf("Lua level %d: %w", id, err)
		}

		level, err := NewLevel(id, rows, positions)

		if err != nil {
			return scenarioLevels{}, err
		}

		level.initialMonsters, err = decisionInteger(record, "initial_monsters")

		if err != nil {
			return scenarioLevels{}, err
		}

		entryX, err := decisionInteger(record, "entry_x")

		if err != nil {
			return scenarioLevels{}, err
		}

		entryY, err := decisionInteger(record, "entry_y")

		if err != nil {
			return scenarioLevels{}, err
		}

		if g.levels[id] != nil {
			return scenarioLevels{}, fmt.Errorf("duplicate Lua level %d", id)
		}

		g.levels[id] = level
		entries[id] = point{
			x: entryX,
			y: entryY,
		}

		stairs, ok := record["stairs"].([]any)

		if !ok {
			return scenarioLevels{}, fmt.Errorf("Lua level %d has no stair links", id)
		}

		links[id] = stairs
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

	curing, err := luaScenarioPoint(result["curing"])

	if err != nil {
		return scenarioLevels{}, err
	}

	heal, err := luaScenarioPoint(result["heal"])

	if err != nil {
		return scenarioLevels{}, err
	}

	haste, err := luaScenarioPoint(result["haste"])

	if err != nil {
		return scenarioLevels{}, err
	}

	return scenarioLevels{
		levels:            g.levels,
		entry:             entry,
		populationEntries: entries,
		curing:            curing,
		heal:              heal,
		haste:             haste,
	}, nil
}

func luaScenarioRows(value any) ([]string, error) {
	entries, ok := value.([]any)

	if !ok {
		return nil, fmt.Errorf("terrain rows are not a list")
	}

	rows := make([]string, len(entries))

	for index, entry := range entries {
		row, ok := entry.(string)

		if !ok {
			return nil, fmt.Errorf("terrain row %d is not text", index)
		}

		rows[index] = row
	}

	return rows, nil
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

	return StairLink{
		X:           numbers[0],
		Y:           numbers[1],
		ToLevelID:   numbers[2],
		ToX:         numbers[3],
		ToY:         numbers[4],
		Unavailable: unavailable,
	}, nil
}
