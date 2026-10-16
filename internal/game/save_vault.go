package game

import "sort"

func (g *Game) vaultValidationLevels() []any {
	ids := make([]int, 0, len(g.levels))

	for id := range g.levels {
		ids = append(ids, id)
	}

	sort.Ints(ids)
	levels := make([]any, 0, len(ids))

	for _, id := range ids {
		level := g.levels[id]
		records := make([]any, 0, len(level.vaultRecords))

		for _, record := range level.vaultRecords {
			records = append(records, map[string]any{
				"kind":      string(record.Kind),
				"source_id": record.SourceID,
				"identity":  record.Identity,
				"x":         record.X,
				"y":         record.Y,
				"pending":   record.Pending,
				"arguments": vaultRecordArguments(record),
			})
		}

		levels = append(levels, map[string]any{
			"id":            level.ID,
			"vault_id":      level.VaultID(),
			"vault_records": records,
		})
	}

	return levels
}
