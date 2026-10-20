package game

import (
	"fmt"
	"sort"

	"crawl/internal/save"
)

// Copy the run's selected graph at the save boundary so callers cannot
// mutate future entrance placement through a returned Snapshot value.
func cloneBranchSchedule(source *save.BranchScheduleRecord) *save.BranchScheduleRecord {
	if source == nil {
		return nil
	}

	copy := *source
	copy.Entries = append([]save.BranchEntryRecord(nil), source.Entries...)

	return &copy
}

// Decode Lua's keyed entries into an ordered Go save value. Lua remains the
// owner of source branch facts; this boundary only checks field shapes.
func decodeLuaBranchSchedule(value any) (*save.BranchScheduleRecord, error) {
	raw, ok := value.(map[string]any)

	if !ok {
		return nil, fmt.Errorf("Lua generation returned no branch schedule")
	}

	water, waterOK := raw["water_branch_id"].(string)
	poison, poisonOK := raw["poison_branch_id"].(string)
	entries, entriesOK := raw["entries"].(map[string]any)

	if !waterOK || !poisonOK || !entriesOK {
		return nil, fmt.Errorf("Lua generation returned invalid branch schedule fields")
	}

	ids := make([]string, 0, len(entries))

	for id := range entries {
		ids = append(ids, id)
	}

	sort.Strings(ids)

	schedule := &save.BranchScheduleRecord{
		WaterBranchID:  water,
		PoisonBranchID: poison,
		Entries:        make([]save.BranchEntryRecord, 0, len(ids)),
	}

	for _, id := range ids {
		entry, ok := entries[id].(map[string]any)

		if !ok {
			return nil, fmt.Errorf("Lua branch %s has invalid entry", id)
		}

		parent, ok := entry["parent_id"].(string)

		if !ok {
			return nil, fmt.Errorf("Lua branch %s has no parent ID", id)
		}

		depth, err := decisionInteger(entry, "parent_depth")

		if err != nil {
			return nil, fmt.Errorf("Lua branch %s: %w", id, err)
		}

		schedule.Entries = append(schedule.Entries, save.BranchEntryRecord{
			BranchID:    id,
			ParentID:    parent,
			ParentDepth: depth,
		})
	}

	return schedule, nil
}

// Recreate Lua's keyed shape for policy validation and future generation.
// Ordered Go entries make snapshots stable even if Lua table iteration varies.
func luaBranchSchedule(source *save.BranchScheduleRecord) map[string]any {
	entries := make(map[string]any, len(source.Entries))

	for _, entry := range source.Entries {
		entries[entry.BranchID] = map[string]any{
			"parent_id":    entry.ParentID,
			"parent_depth": entry.ParentDepth,
		}
	}

	return map[string]any{
		"water_branch_id":  source.WaterBranchID,
		"poison_branch_id": source.PoisonBranchID,
		"entries":          entries,
	}
}

// Fixed scenarios have no branch schedule. Keep their Lua policy input nil
// rather than fabricating an empty graph that would change fixture saves.
func branchSchedulePolicyInput(source *save.BranchScheduleRecord) any {
	if source == nil {
		return nil
	}

	return luaBranchSchedule(source)
}

// Every restored schedule passes through the same source-backed Lua policy
// used by new-game selection before it becomes Game-owned state.
func (g *Game) acceptBranchSchedule(source *save.BranchScheduleRecord) error {
	if source == nil {
		return fmt.Errorf("generated game has no branch schedule")
	}

	seen := make(map[string]bool, len(source.Entries))

	for _, entry := range source.Entries {
		if entry.BranchID == "" || seen[entry.BranchID] {
			return fmt.Errorf("duplicate or empty saved branch ID %q", entry.BranchID)
		}

		seen[entry.BranchID] = true
	}

	_, err := g.scripts.Policy("world.validate_branch_schedule", map[string]any{
		"branch_schedule": luaBranchSchedule(source),
	})

	if err != nil {
		return fmt.Errorf("invalid branch schedule: %w", err)
	}

	g.branchSchedule = cloneBranchSchedule(source)

	return nil
}

// New-game generation returns a Lua table; normalize it before any level is
// installed so errors cannot leave a partly initialized run.
func (g *Game) acceptLuaBranchSchedule(value any) error {
	schedule, err := decodeLuaBranchSchedule(value)

	if err != nil {
		return err
	}

	return g.acceptBranchSchedule(schedule)
}
