package game

import (
	"fmt"
	"sort"

	"crawl/internal/save"
)

func (g *Game) restoreLevels(records []save.LevelRecord, currentAut int64) error {
	for _, record := range records {
		if _, duplicate := g.levels[record.ID]; duplicate {
			return fmt.Errorf("duplicate level %d", record.ID)
		}

		if record.BranchID == "" {
			return fmt.Errorf("level %d has no branch ID", record.ID)
		}

		level, levelErr := NewLevel(record.ID, record.Cells, g.stores.Positions)

		if levelErr != nil {
			return levelErr
		}

		level.initialMonsters = record.InitialMonsters
		level.initialActors = record.InitialActors
		level.BranchID = record.BranchID

		excluded := make(map[point]bool, len(record.SpawnExclusions))

		for _, saved := range record.SpawnExclusions {
			cell := point{
				x: saved.X,
				y: saved.Y,
			}

			if !level.inBounds(cell.x, cell.y) || excluded[cell] {
				return fmt.Errorf("level %d has invalid spawn exclusion", record.ID)
			}

			excluded[cell] = true
			level.spawnExclusions = append(level.spawnExclusions, cell)
		}

		if record.ShoalsTide != nil {
			if record.BranchID != shoalsBranchID {
				return fmt.Errorf("level %d has Shoals tide outside Shoals", record.ID)
			}

			if err := level.SetShoalsHeights(record.ShoalsTide.Heights); err != nil {
				return err
			}

			if record.ShoalsTide.LastAut > currentAut {
				return fmt.Errorf("level %d Shoals tide clock is in the future", record.ID)
			}

			if err := level.SetShoalsTideClock(
				record.ShoalsTide.Height,
				record.ShoalsTide.Velocity,
				record.ShoalsTide.LastAut,
			); err != nil {
				return err
			}
		} else if record.BranchID == shoalsBranchID {
			level.InitShoalsTide()
		}

		if record.VaultID != "" {
			if err := level.SetVaultID(record.VaultID); err != nil {
				return err
			}
		}

		if err := level.SetVaultIDs(record.VaultIDs); err != nil {
			return err
		}

		for _, savedVault := range record.VaultRecords {
			if err := level.AddVaultRecord(savedVault); err != nil {
				return err
			}
		}

		if knownErr := level.LoadKnownCells(record.Known); knownErr != nil {
			return knownErr
		}

		if seenErr := level.LoadSeenCells(record.Seen); seenErr != nil {
			return seenErr
		}

		if detectedErr := level.LoadDetectedItems(record.DetectedItems); detectedErr != nil {
			return detectedErr
		}

		for _, savedLink := range record.Stairs {
			if linkErr := level.AddStairLink(StairLink{
				X:              savedLink.X,
				Y:              savedLink.Y,
				ToLevelID:      savedLink.ToLevelID,
				ToX:            savedLink.ToX,
				ToY:            savedLink.ToY,
				Pending:        savedLink.Pending,
				Unavailable:    savedLink.Unavailable,
				TargetBranchID: savedLink.TargetBranchID,
				SourceFeature:  savedLink.SourceFeature,
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
		"scenario_id":     g.scenarioID,
		"levels":          scenarioLevelPolicyRecords(g.levels),
		"branch_schedule": branchSchedulePolicyInput(g.branchSchedule),
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
				"x":                link.X,
				"y":                link.Y,
				"to_level_id":      link.ToLevelID,
				"to_x":             link.ToX,
				"to_y":             link.ToY,
				"pending":          link.Pending,
				"unavailable":      link.Unavailable,
				"target_branch_id": link.TargetBranchID,
				"source_feature":   link.SourceFeature,
			})
		}

		records = append(records, map[string]any{
			"id":               id,
			"branch_id":        level.BranchID,
			"cells":            level.Cells(),
			"stairs":           stairs,
			"initial_monsters": level.initialMonsters,
			"initial_actors":   level.initialActors,
		})
	}

	return records
}
