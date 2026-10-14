package game

import (
	"fmt"
	"sort"

	"dcrawl-go/internal/save"
)

func (g *Game) restoreLevels(records []save.LevelRecord, currentAut int64) error {
	for _, record := range records {
		if _, duplicate := g.levels[record.ID]; duplicate {
			return fmt.Errorf("duplicate level %d", record.ID)
		}

		level, levelErr := NewLevel(record.ID, record.Rows, g.stores.Positions)

		if levelErr != nil {
			return levelErr
		}

		level.initialMonsters = record.InitialMonsters
		level.initialActors = record.InitialActors

		if knownErr := level.LoadKnownRows(record.Known); knownErr != nil {
			return knownErr
		}

		for _, savedLink := range record.Stairs {
			if linkErr := level.AddStairLink(StairLink{
				X:           savedLink.X,
				Y:           savedLink.Y,
				ToLevelID:   savedLink.ToLevelID,
				ToX:         savedLink.ToX,
				ToY:         savedLink.ToY,
				Unavailable: savedLink.Unavailable,
			}); linkErr != nil {
				return linkErr
			}
		}

		g.levels[record.ID] = level

		if record.AwaySinceAut != nil {
			if *record.AwaySinceAut < 0 || *record.AwaySinceAut > currentAut {
				return fmt.Errorf("invalid level %d away clock", record.ID)
			}

			awaySince := Aut(*record.AwaySinceAut)

			level.awaySinceAut = &awaySince
		}
	}

	if err := validateStairLinks(g.levels); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_scenario_levels", map[string]any{
		"scenario_id": g.scenarioID,
		"levels":      scenarioLevelPolicyRecords(g.levels),
	}); err != nil {
		return err
	}

	return nil
}

// Project only level data into the Lua save policy after generic level and
// stair construction has validated the underlying grid.
func scenarioLevelPolicyRecords(levels map[int]*Level) []any {
	ids := make([]int, 0, len(levels))

	for id := range levels {
		ids = append(ids, id)
	}

	sort.Ints(ids)
	records := make([]any, 0, len(ids))

	for _, id := range ids {
		level := levels[id]
		stairs := make([]any, 0, len(level.stairs))

		for _, link := range level.StairLinks() {
			stairs = append(stairs, map[string]any{
				"x":           link.X,
				"y":           link.Y,
				"to_level_id": link.ToLevelID,
				"to_x":        link.ToX,
				"to_y":        link.ToY,
				"unavailable": link.Unavailable,
			})
		}

		records = append(records, map[string]any{
			"id":               id,
			"rows":             level.terrain,
			"stairs":           stairs,
			"initial_monsters": level.initialMonsters,
			"initial_actors":   level.initialActors,
		})
	}

	return records
}
