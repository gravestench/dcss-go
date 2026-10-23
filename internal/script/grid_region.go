package script

import (
	"fmt"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

// region_plan gives Lua a detached, complete plan for one level. A
// shifting rule may edit its cells and records before replace_region
// validates the result; merely reading the plan never mutates the game.
func (r *Runtime) luaGridRegionPlan(state *lua.LState) int {
	if r.services.Grid == nil {
		state.RaiseError("grid is unavailable")

		return 0
	}

	levelID := r.gridIntegers(state, 1)[0]
	plan, err := r.services.Grid.RegionPlan(levelID)

	if err != nil {
		state.RaiseError("region plan: %v", err)

		return 0
	}

	table, err := r.policyTable(plan)

	if err != nil {
		state.RaiseError("region plan encoding: %v", err)

		return 0
	}

	state.Push(table)

	return 1
}

// replace_region stages one complete grid owner. Its plan is decoded and
// validated by the host before any terrain or ECS position changes. Lua
// remains responsible for deciding which cells and actors should survive.
func (r *Runtime) luaGridReplaceRegion(state *lua.LState) int {
	if r.services.Grid == nil {
		state.RaiseError("grid is unavailable")

		return 0
	}

	levelID := r.gridIntegers(state, 1)[0]
	table := state.CheckTable(3)
	plan, err := policyValues(table)

	if err != nil {
		state.RaiseError("region plan: %v", err)

		return 0
	}

	// Combat can already have staged health or status commands when it
	// banishes an actor. Only earlier commands against this level's grid
	// conflict with replacing that grid; unrelated ECS edits remain ordered.
	for _, command := range r.pending {
		if command.spatialLevel == levelID {
			state.RaiseError("region replacement follows a change to that level")

			return 0
		}
	}

	for cell := range r.pendingCells {
		if cell.levelID == levelID {
			state.RaiseError("region has earlier staged cell changes")

			return 0
		}
	}

	for _, position := range r.pendingPositions {
		if position != nil && position.levelID == levelID {
			state.RaiseError("region has earlier staged actor movement")

			return 0
		}
	}

	change, err := r.services.Grid.PrepareRegion(levelID, plan)

	if err != nil {
		state.RaiseError("invalid region: %v", err)

		return 0
	}

	for y, row := range change.Cells {
		for x, feature := range row {
			r.pendingCells[gridCell{
				levelID: levelID,
				x:       x,
				y:       y,
			}] = feature
		}
	}

	stageRegionActors(r, levelID, change.ActorMoves,
		change.RetiredActors)

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply:        change.Apply,
		undo:         change.Undo,
	})

	r.pendingRegions[levelID] = change

	return 0
}

// A policy can materialize authored records after staging a new grid.
// The change owns a detached next level; record edits on it become visible
// only when the same region command commits, and disappear on discard.
func (r *Runtime) luaGridMarkRegionRecords(state *lua.LState) int {
	levelID := r.gridIntegers(state, 1)[0]
	change, found := r.pendingRegions[levelID]

	if !found || change.MarkRecords == nil {
		state.RaiseError("level %d has no staged region records", levelID)

		return 0
	}

	values, err := policyValues(state.CheckTable(3))

	if err != nil {
		state.RaiseError("materialized records: %v", err)

		return 0
	}

	entries, ok := values["entries"].([]any)

	if !ok {
		empty, isMap := values["entries"].(map[string]any)

		if isMap && len(empty) == 0 {
			entries = []any{}
			ok = true
		}
	}

	if !ok {
		state.RaiseError("materialized records must be a list")

		return 0
	}

	records := make([]map[string]any, 0, len(entries))

	for _, value := range entries {
		record, ok := value.(map[string]any)

		if !ok {
			state.RaiseError("%s", fmt.Sprintf("materialized record has type %T", value))

			return 0
		}

		records = append(records, record)
	}

	if err := change.MarkRecords(records); err != nil {
		state.RaiseError("materialized records: %v", err)
	}

	return 0
}

// Population created by a staged region increases that region's saved
// monster budget before publication. The budget follows the same rollback
// boundary as its terrain and authored records.
func (r *Runtime) luaGridAddRegionActors(state *lua.LState) int {
	values := r.gridIntegers(state, 2)
	change, found := r.pendingRegions[values[0]]

	if !found || change.AddActors == nil {
		state.RaiseError("level %d has no staged region", values[0])

		return 0
	}

	if err := change.AddActors(values[1]); err != nil {
		state.RaiseError("region actor budget: %v", err)
	}

	return 0
}

// Mirror the host-validated permutation in the pending Lua view. Later
// policy calls in the same action read the new occupancy and terrain,
// while ApplyPending commits both through the host's reversible change.
func stageRegionActors(
	runtime *Runtime,
	levelID int,
	moves []ActorMove,
	retired []akara.Entity,
) {
	for _, move := range moves {
		old, _, _ := runtime.stagedPosition(move.Actor)

		runtime.pendingActors[old] = 0
	}

	// Retire before installing destinations: a survivor may move into a
	// retired actor's old cell in the same validated permutation.
	for _, actor := range retired {
		old, _, _ := runtime.stagedPosition(actor)

		runtime.stageActorPosition(actor, &old, nil)
	}

	for _, move := range moves {
		next := gridCell{
			levelID: levelID,
			x:       move.X,
			y:       move.Y,
		}

		runtime.stageActorPosition(move.Actor, nil, &next)
	}
}
