package game

import (
	"fmt"

	"crawl/internal/save"
)

// cloneHellState keeps Snapshot callers from mutating live travel pointers.
func cloneHellState(source *save.HellStateRecord) *save.HellStateRecord {
	if source == nil {
		return nil
	}

	copy := *source

	if source.Return != nil {
		origin := *source.Return

		copy.Return = &origin
	}

	return &copy
}

// acceptHellState checks storage boundaries before a restored run resumes.
// Lua owns gate meaning; Go ensures every saved pointer names a live cell.
func (g *Game) acceptHellState(source *save.HellStateRecord) error {
	if source == nil {
		g.hellState = nil

		return nil
	}

	if g.scenarioID != generatedDungeonScenarioID ||
		source.VestibuleLevelID <= 0 ||
		source.Return == nil {
		return fmt.Errorf("invalid saved Hell session state")
	}

	vestibule := g.levels[source.VestibuleLevelID]
	origin := source.Return
	outside := g.levels[origin.LevelID]

	if vestibule == nil ||
		!vestibule.inBounds(source.EntryX, source.EntryY) ||
		!vestibule.Walkable(source.EntryX, source.EntryY) ||
		outside == nil ||
		!outside.inBounds(origin.X, origin.Y) ||
		origin.LevelID == source.VestibuleLevelID {
		return fmt.Errorf("saved Hell entry or return site is invalid")
	}

	g.hellState = cloneHellState(source)

	return nil
}

// luaHellState sends a copy of the saved entry and latest return gate to
// command policy. Lua never keeps this state in a module variable.
func luaHellState(source *save.HellStateRecord) map[string]any {
	if source == nil {
		return nil
	}

	state := map[string]any{
		"vestibule_level_id": source.VestibuleLevelID,
		"entry_x":            source.EntryX,
		"entry_y":            source.EntryY,
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
