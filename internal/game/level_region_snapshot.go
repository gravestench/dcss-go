package game

import (
	"fmt"
	"sort"

	"crawl/internal/vault"
)

// RegionPlan returns the level-owned facts that a Lua world rule may
// transform before asking PrepareRegion to validate and publish them.
// Every collection is detached from the live level, so a policy error
// leaves the existing map and its authored records intact.
func (grid scriptGrid) RegionPlan(levelID int) (map[string]any, error) {
	level := grid.levels[levelID]

	if level == nil {
		return nil, fmt.Errorf("missing region %d", levelID)
	}

	plan := map[string]any{
		"cells":              level.Cells(),
		"local_depth":        level.LocalDepth,
		"known":              level.KnownCells(),
		"seen":               regionBoolValues(level.SeenCells()),
		"detected_items":     regionBoolValues(level.DetectedItems()),
		"detected_creatures": regionStringValues(level.DetectedCreatures()),
		"initial_monsters":   level.initialMonsters,
		"initial_actors":     level.initialActors,
		"vault_ids":          level.VaultIDs(),
		"vault_records":      regionVaultRecords(level.VaultRecords()),
		"stairs":             regionStairs(level.StairLinks()),
		"cell_colours":       regionColours(level),
		"spawn_exclusions":   regionExclusions(level),
		"actor_moves":        []any{},
		"actor_retire":       []any{},
	}

	if id := level.VaultID(); id != "" {
		plan["vault_id"] = id
	}

	return plan, nil
}

// A Lua region plan needs detached, one-based rows of sensed monster IDs.
func regionStringValues(rows [][]string) []any {
	result := make([]any, len(rows))

	for y, row := range rows {
		cells := make([]any, len(row))

		for x, value := range row {
			cells[x] = value
		}

		result[y] = cells
	}

	return result
}

// Gopher Lua's generic policy bridge accepts nested []any rather than a
// Go-specific [][]bool. Preserve false entries, including unseen cells.
func regionBoolValues(rows [][]bool) []any {
	result := make([]any, len(rows))

	for y, row := range rows {
		cells := make([]any, len(row))

		for x, value := range row {
			cells[x] = value
		}

		result[y] = cells
	}

	return result
}

// Keep all source-facing record fields. A shifted vault must retain its
// pending effects and script identity, not only the feature it painted.
func regionVaultRecords(records []vault.Record) []any {
	result := make([]any, 0, len(records))

	for _, record := range records {
		arguments := make(map[string]any, len(record.Arguments))

		for _, argument := range record.Arguments {
			switch argument.Kind {
			case vault.ValueBool:
				arguments[argument.Name] = argument.Bool

			case vault.ValueInt:
				arguments[argument.Name] = argument.Int

			case vault.ValueString:
				arguments[argument.Name] = argument.String
			}
		}

		result = append(result, map[string]any{
			"kind":       string(record.Kind),
			"vault_id":   record.SourceID,
			"identity":   record.Identity,
			"source":     record.SourceGlyph,
			"directive":  record.Directive,
			"method":     record.ActivationHook,
			"x":          record.X,
			"y":          record.Y,
			"line":       record.Line,
			"pending":    record.Pending,
			"overridden": record.Overridden,
			"arguments":  arguments,
		})
	}

	return result
}

func regionStairs(links []StairLink) []any {
	result := make([]any, 0, len(links))

	for _, link := range links {
		result = append(result, map[string]any{
			"x":                link.X,
			"y":                link.Y,
			"to_level_id":      link.ToLevelID,
			"to_x":             link.ToX,
			"to_y":             link.ToY,
			"pending":          link.Pending,
			"exit":             link.Exit,
			"unavailable":      link.Unavailable,
			"target_branch_id": link.TargetBranchID,
			"source_feature":   link.SourceFeature,
		})
	}

	return result
}

func regionColours(level *Level) []any {
	cells := make([]point, 0, len(level.cellColours))

	for cell := range level.cellColours {
		cells = append(cells, cell)
	}

	sort.Slice(cells, func(i, j int) bool {
		if cells[i].y != cells[j].y {
			return cells[i].y < cells[j].y
		}

		return cells[i].x < cells[j].x
	})

	result := make([]any, 0, len(cells))

	for _, cell := range cells {
		result = append(result, map[string]any{
			"x":      cell.x,
			"y":      cell.y,
			"colour": level.cellColours[cell],
		})
	}

	return result
}

func regionExclusions(level *Level) []any {
	result := make([]any, 0, len(level.spawnExclusions))

	for _, cell := range level.spawnExclusions {
		result = append(result, map[string]any{
			"x": cell.x,
			"y": cell.y,
		})
	}

	return result
}

func cloneRegionHeights(rows [][]int) [][]int {
	if rows == nil {
		return nil
	}

	result := make([][]int, len(rows))

	for y, row := range rows {
		result[y] = append([]int(nil), row...)
	}

	return result
}
