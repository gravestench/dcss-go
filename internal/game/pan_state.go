package game

import (
	"fmt"

	"crawl/internal/save"
)

// clonePanState prevents callers from changing the next Pan draw through a
// Snapshot's history slice or return pointer.
func clonePanState(source *save.PanStateRecord) *save.PanStateRecord {
	if source == nil {
		return nil
	}

	copy := *source

	copy.VaultIDs = append([]string(nil), source.VaultIDs...)

	if source.Return != nil {
		origin := *source.Return

		copy.Return = &origin
	}

	return &copy
}

// Validate only storage facts here. Lua owns the Pan map names and return
// policy, while Go rejects an impossible pointer before a saved game runs.
func (g *Game) acceptPanState(source *save.PanStateRecord) error {
	if source == nil {
		g.panState = nil

		return nil
	}

	if g.scenarioID != generatedDungeonScenarioID ||
		source.RegionsSeen < 1 ||
		source.ActiveLevelID < 0 {
		return fmt.Errorf("invalid saved Pan session state")
	}

	for _, id := range source.VaultIDs {
		if id == "" {
			return fmt.Errorf("saved Pan history has an empty vault ID")
		}
	}

	if source.ActiveLevelID == 0 {
		if source.Return != nil {
			return fmt.Errorf("inactive Pan history has a return site")
		}
	} else {
		if g.levels[source.ActiveLevelID] == nil ||
			source.Return == nil {
			return fmt.Errorf("active Pan history has no level or return site")
		}

		origin := source.Return
		level := g.levels[origin.LevelID]

		if level == nil ||
			!level.inBounds(origin.X, origin.Y) ||
			origin.LevelID == source.ActiveLevelID {
			return fmt.Errorf("saved Pan return site is invalid")
		}
	}

	g.panState = clonePanState(source)

	return nil
}

// luaPanState passes durable history to Lua command policy without sharing a
// mutable Go slice. Lua decides the next portal operation from this snapshot.
func luaPanState(source *save.PanStateRecord) map[string]any {
	if source == nil {
		return nil
	}

	ids := make([]any, 0, len(source.VaultIDs))

	for _, id := range source.VaultIDs {
		ids = append(ids, id)
	}

	state := map[string]any{
		"regions_seen":    source.RegionsSeen,
		"vault_ids":       ids,
		"active_level_id": source.ActiveLevelID,
	}

	if source.Return != nil {
		state["return_site"] = map[string]any{
			"level_id": source.Return.LevelID,
			"x":        source.Return.X,
			"y":        source.Return.Y,
		}
	}

	return state
}
