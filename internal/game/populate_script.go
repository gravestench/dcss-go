package game

import (
	"fmt"
	"sort"

	"dcrawl-go/internal/vault"
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

		excluded := make([]any, 0, len(setup.spawnExclusions[id]))

		for _, cell := range setup.spawnExclusions[id] {
			excluded = append(excluded, map[string]any{
				"x": cell.x,
				"y": cell.y,
			})
		}

		levels = append(levels, map[string]any{
			"id":               id,
			"entry_x":          entry.x,
			"entry_y":          entry.y,
			"budget":           level.initialMonsters,
			"width":            level.width,
			"height":           len(level.terrain),
			"vault_records":    populationVaultRecords(level),
			"spawn_exclusions": excluded,
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

	if err := g.markMaterializedVaultRecords(result["materialized"]); err != nil {
		return err
	}

	return nil
}

func populationVaultRecords(level *Level) []any {
	records := []any{}

	for index, record := range level.vaultRecords {
		if !record.Pending ||
			record.Overridden ||
			(record.Kind != vault.KindItem &&
				record.Kind != vault.KindMonster) {
			continue
		}

		targeted := false

		for _, argument := range record.Arguments {
			if argument.Name == "targets" && argument.String != "" {
				targeted = true
			}
		}

		if !targeted {
			continue
		}

		records = append(records, map[string]any{
			"index":    index + 1,
			"kind":     string(record.Kind),
			"identity": record.Identity,
			"x":        record.X,
			"y":        record.Y,
		})
	}

	return records
}

func (g *Game) markMaterializedVaultRecords(value any) error {
	entries, ok := value.([]any)

	if !ok {
		if empty, isMap := value.(map[string]any); isMap && len(empty) == 0 {
			return nil
		}

		return fmt.Errorf("Lua population has invalid materialized vault list")
	}

	for _, entry := range entries {
		fields, isMap := entry.(map[string]any)

		if !isMap {
			return fmt.Errorf("Lua population materialized entry is not a record")
		}

		levelID, err := decisionInteger(fields, "level_id")

		if err != nil {
			return err
		}

		index, err := decisionInteger(fields, "index")

		if err != nil {
			return err
		}

		level := g.levels[levelID]

		if level == nil ||
			index < 1 ||
			index > len(level.vaultRecords) {
			return fmt.Errorf("Lua population materialized an unknown vault record")
		}

		record := &level.vaultRecords[index-1]

		if !record.Pending ||
			(record.Kind != vault.KindItem && record.Kind != vault.KindMonster) {
			return fmt.Errorf("Lua population materialized an invalid vault record")
		}

		record.Pending = false
	}

	return nil
}
