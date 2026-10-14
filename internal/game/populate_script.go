package game

import (
	"fmt"
	"sort"
)

// populateFromScript gives the effective Lua ruleset the established level
// grids. The policy creates actors and floor items through the shared ECS API.
func (g *Game) populateFromScript(setup scenarioLevels) error {
	ids := make([]int, 0, len(g.levels))

	for id := range g.levels {
		ids = append(ids, id)
	}

	sort.Ints(ids)
	levels := make([]any, 0, len(ids))

	for _, id := range ids {
		level := g.levels[id]
		entry, found := setup.populationEntries[id]

		if !found {
			return fmt.Errorf("level %d has no population entry", id)
		}

		levels = append(levels, map[string]any{
			"id":      id,
			"entry_x": entry.x,
			"entry_y": entry.y,
			"budget":  level.initialMonsters,
			"width":   level.width,
			"height":  len(level.terrain),
		})
	}

	result, err := g.scripts.Policy("world.populate", map[string]any{
		"scenario_id": g.scenarioID,
		"levels":      levels,
		"curing": map[string]any{
			"x": setup.curing.x,
			"y": setup.curing.y,
		},

		"heal": map[string]any{
			"x": setup.heal.x,
			"y": setup.heal.y,
		},

		"haste": map[string]any{
			"x": setup.haste.x,
			"y": setup.haste.y,
		},
	})

	if err != nil {
		return err
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return err
	}

	counts, ok := result["initial_actors"].([]any)

	if !ok {
		return fmt.Errorf("Lua population returned no actor counts")
	}

	for _, value := range counts {
		entry, ok := value.(map[string]any)

		if !ok {
			return fmt.Errorf("Lua population count has invalid type %T", value)
		}

		id, err := decisionInteger(entry, "id")

		if err != nil {
			return err
		}

		count, err := decisionInteger(entry, "count")

		if err != nil {
			return err
		}

		level := g.levels[id]

		if level == nil || count < 0 {
			return fmt.Errorf("Lua population count for invalid level %d", id)
		}

		level.initialActors = count
	}

	return nil
}
