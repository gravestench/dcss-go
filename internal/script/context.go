package script

import (
	"fmt"
	"slices"

	"crawl/internal/noise"
	"crawl/internal/terrain"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

func (r *Runtime) installContextAPI() {
	context := r.state.NewTable()

	r.state.SetField(context, "get", r.state.NewFunction(r.luaGetComponent))
	r.state.SetField(context, "set", r.state.NewFunction(r.luaSetComponent))
	r.state.SetField(context, "add", r.state.NewFunction(r.luaAddComponent))
	r.state.SetField(context, "remove", r.state.NewFunction(r.luaRemoveComponent))
	r.state.SetField(context, "destroy", r.state.NewFunction(r.luaDestroyEntity))
	r.state.SetField(context, "create", r.state.NewFunction(r.luaCreateEntity))
	r.state.SetField(context, "has", r.state.NewFunction(r.luaHasComponent))
	r.state.SetField(context, "query", r.state.NewFunction(r.luaQueryEntities))
	r.state.SetField(context, "entity", r.state.NewFunction(r.luaEntityByID))
	r.state.SetField(context, "id", r.state.NewFunction(r.luaEntityID))
	r.state.SetField(context, "cell", r.state.NewFunction(r.luaGridCell))
	r.state.SetField(context, "remembered", r.state.NewFunction(r.luaGridRemembered))
	r.state.SetField(context, "seen", r.state.NewFunction(r.luaGridSeen))
	r.state.SetField(context, "records_at", r.state.NewFunction(r.luaGridRecordsAt))
	r.state.SetField(context, "replace_record_string",
		r.state.NewFunction(r.luaGridReplaceRecordString))
	r.state.SetField(context, "marker_property", r.state.NewFunction(r.luaGridMarkerProperty))
	r.state.SetField(context, "level_size", r.state.NewFunction(r.luaGridLevelSize))
	r.state.SetField(context, "level_ids", r.state.NewFunction(r.luaGridLevelIDs))
	r.state.SetField(context, "level_branch", r.state.NewFunction(r.luaGridLevelBranch))
	r.state.SetField(context, "level_depth", r.state.NewFunction(r.luaGridLevelDepth))
	r.state.SetField(context, "shoals_height", r.state.NewFunction(r.luaGridShoalsHeight))
	r.state.SetField(context, "shoals_tide_clock", r.state.NewFunction(r.luaGridShoalsTideClock))
	r.state.SetField(context, "set_shoals_tide_clock", r.state.NewFunction(r.luaGridSetShoalsTideClock))
	r.state.SetField(context, "set_cell", r.state.NewFunction(r.luaGridSetCell))
	r.state.SetField(context, "move_stair", r.state.NewFunction(r.luaGridMoveStair))
	r.state.SetField(context, "replace_region",
		r.state.NewFunction(r.luaGridReplaceRegion))
	r.state.SetField(context, "region_plan",
		r.state.NewFunction(r.luaGridRegionPlan))
	r.state.SetField(context, "mark_region_records",
		r.state.NewFunction(r.luaGridMarkRegionRecords))
	r.state.SetField(context, "add_region_actors",
		r.state.NewFunction(r.luaGridAddRegionActors))
	r.state.SetField(context, "session_state",
		r.state.NewFunction(r.luaSessionState))
	r.state.SetField(context, "replace_session_state",
		r.state.NewFunction(r.luaReplaceSessionState))
	r.state.SetField(context, "set_cell_colour", r.state.NewFunction(r.luaGridSetCellColour))
	r.state.SetField(context, "cell_blood", r.state.NewFunction(r.luaGridCellBlood))
	r.state.SetField(context, "set_cell_blood", r.state.NewFunction(r.luaGridSetCellBlood))
	r.state.SetField(context, "map_cell", r.state.NewFunction(r.luaGridMapCell))
	r.state.SetField(context, "detect_item", r.state.NewFunction(r.luaGridDetectItem))
	r.state.SetField(context, "detect_creature", r.state.NewFunction(r.luaGridDetectCreature))
	r.state.SetField(context, "clear_detected_creatures", r.state.NewFunction(r.luaGridClearDetectedCreatures))
	r.state.SetField(context, "walkable", r.state.NewFunction(r.luaGridWalkable))
	r.state.SetField(context, "solid", r.state.NewFunction(r.luaGridSolid))
	r.state.SetField(context, "opaque", r.state.NewFunction(r.luaGridOpaque))
	r.state.SetField(context, "actor_at", r.state.NewFunction(r.luaGridActorAt))
	r.state.SetField(context, "actors_at", r.state.NewFunction(r.luaGridActorsAt))
	r.state.SetField(context, "stair_at", r.state.NewFunction(r.luaGridStairAt))
	r.state.SetField(context, "travel_feature_at", r.state.NewFunction(r.luaGridTravelFeatureAt))
	r.state.SetField(context, "visible", r.state.NewFunction(r.luaGridVisible))
	r.state.SetField(context, "visible_no_trans", r.state.NewFunction(r.luaGridVisibleNoTrans))
	r.state.SetField(context, "visible_no_trans_with_blocked",
		r.state.NewFunction(r.luaGridVisibleNoTransWithBlocked))
	r.state.SetField(context, "visible_cells", r.state.NewFunction(r.luaGridVisibleCells))
	r.state.SetField(context, "route_step", r.state.NewFunction(r.luaGridRouteStep))
	r.state.SetField(context, "projectile_clear", r.state.NewFunction(r.luaGridProjectileClear))
	r.state.SetField(context, "move_actor", r.state.NewFunction(r.luaGridMoveActor))
	r.state.SetField(context, "move_actors", r.state.NewFunction(r.luaGridMoveActors))
	r.state.SetField(context, "place_actor", r.state.NewFunction(r.luaGridPlaceActor))
	r.state.SetField(context, "remove_actor", r.state.NewFunction(r.luaGridRemoveActor))
	r.state.SetField(context, "aut", r.state.NewFunction(r.luaCurrentAut))
	r.state.SetField(context, "actor", r.state.NewFunction(r.luaActiveActor))
	r.state.SetField(context, "player", r.state.NewFunction(r.luaPlayerEntity))
	r.state.SetField(context, "random", r.state.NewFunction(r.luaRandom))
	r.state.SetField(context, "subgenerator",
		r.state.NewFunction(r.luaSubgenerator))
	r.state.SetField(context, "hash_with_seed", r.state.NewFunction(r.luaHashWithSeed))
	r.state.SetField(context, "hash3_quotient_mod",
		r.state.NewFunction(r.luaHash3QuotientMod))
	r.state.SetField(context, "worley", r.state.NewFunction(r.luaWorley))
	r.state.SetField(context, "fbm3", r.state.NewFunction(r.luaFBM3))
	r.state.SetField(context, "xor_u32", r.state.NewFunction(r.luaXorU32))
	r.state.SetField(context, "random_u64", r.state.NewFunction(r.luaRandomWord))
	r.state.SetField(context, "emit", r.state.NewFunction(r.luaEmit))
	r.state.SetField(context, "signal", r.state.NewFunction(r.luaSignal))
	r.state.SetField(context, "signals", r.state.NewFunction(r.luaSignals))

	r.context = context
}

// Lua represents integers as floats, so validate the exact source word
// range before passing a borrowed-floor choice to the unsigned Go kernel.
func (r *Runtime) luaHashWithSeed(state *lua.LState) int {
	values := [3]uint32{}

	for index := range values {
		number, err := exactLuaNumber(state.Get(index + 2))

		if err != nil ||
			number < 0 ||
			number > 4294967295 {
			state.RaiseError("hash_with_seed argument %d must be a uint32", index+1)

			return 0
		}

		values[index] = uint32(number)
	}

	state.Push(lua.LNumber(noise.HashWithSeed(values[0], values[1], values[2])))

	return 1
}

func (r *Runtime) componentArgs(
	state *lua.LState,
) (akara.Entity, string, *akara.DynamicStore, HostComponent) {
	handle := state.CheckUserData(2)
	entity, ok := handle.Value.(akara.Entity)

	if !ok {
		state.RaiseError("expected entity handle")

		return 0, "", nil, HostComponent{}
	}

	name := state.CheckString(3)
	store, dynamic := r.components[name]
	host, hosted := r.hostComponents[name]

	if !dynamic && !hosted {
		state.RaiseError("unknown Lua component %s", name)

		return 0, "", nil, HostComponent{}
	}

	return entity, name, store, host
}

func (r *Runtime) luaGetComponent(state *lua.LState) int {
	entity, name, store, host := r.componentArgs(state)
	var values map[string]any
	var found bool
	var err error
	target := componentTarget{
		entity: entity,
		name:   name,
	}

	view, queued := r.pendingViews[target]

	if r.pendingDestroy[entity] {
		found = false
	} else if queued {
		values, found = view.values, view.present
	} else if store == nil {
		values, found = host.Get(entity)
	} else {
		component, present := store.Get(entity)
		found = present

		if found {
			values, err = component.Snapshot()
		}
	}

	if !found {
		state.Push(lua.LNil)

		return 1
	}

	if err != nil {
		state.RaiseError("get %s on entity %d: %v", name, entity, err)

		return 0
	}

	table := state.NewTable()
	fields := make([]string, 0, len(values))

	for field := range values {
		fields = append(fields, field)
	}

	slices.Sort(fields)

	for _, field := range fields {
		value := values[field]
		converted, err := r.luaFieldValue(value)

		if err != nil {
			state.RaiseError("get %s.%s: %v", name, field, err)

			return 0
		}

		state.SetField(table, field, converted)
	}

	state.Push(table)

	return 1
}

func (r *Runtime) luaHasComponent(state *lua.LState) int {
	entity, name, _, _ := r.componentArgs(state)
	state.Push(lua.LBool(r.componentHas(name, entity)))

	return 1
}

func (r *Runtime) luaQueryEntities(state *lua.LState) int {
	names, err := stringList(state.Get(2))

	if err != nil {
		state.RaiseError("query components: %v", err)

		return 0
	}

	for _, name := range names {
		_, dynamic := r.components[name]
		_, hosted := r.hostComponents[name]

		if !dynamic && !hosted {
			state.RaiseError("query has unknown component %s", name)

			return 0
		}
	}

	result := state.NewTable()

	for _, entity := range r.queryEntities(names) {
		result.Append(r.entityHandle(entity))
	}

	state.Push(result)

	return 1
}

func (r *Runtime) luaEntityByID(state *lua.LState) int {
	number, err := exactLuaNumber(state.Get(2))

	if err != nil ||
		number < 1 ||
		number > 9007199254740991 {
		state.RaiseError("entity ID must be a positive exact integer")

		return 0
	}

	entity := akara.Entity(uint64(number))

	if !r.world.EntityExists(entity) || r.pendingDestroy[entity] {
		state.Push(lua.LNil)

		return 1
	}

	state.Push(r.entityHandle(entity))

	return 1
}

func (r *Runtime) luaEntityID(state *lua.LState) int {
	handle := state.CheckUserData(2)
	entity, ok := handle.Value.(akara.Entity)

	if !ok {
		state.RaiseError("expected entity handle")

		return 0
	}

	state.Push(lua.LNumber(entity))

	return 1
}

func (r *Runtime) gridArgs(state *lua.LState) (int, int, int) {
	coordinates := r.gridIntegers(state, 3)

	return coordinates[0], coordinates[1], coordinates[2]
}

func (r *Runtime) gridIntegers(state *lua.LState, count int) []int {
	if r.services.Grid == nil {
		state.RaiseError("grid service is unavailable")

		return nil
	}

	coordinates := make([]int, count)

	for index := range coordinates {
		number, err := exactLuaNumber(state.Get(index + 2))

		if err != nil ||
			number < -2147483648 ||
			number > 2147483647 {
			state.RaiseError("grid coordinate %d must be an integer", index+1)

			return nil
		}

		coordinates[index] = int(number)
	}

	return coordinates
}

func (r *Runtime) luaGridCell(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	cell, found := r.services.Grid.Cell(levelID, x, y)

	cellKey := gridCell{
		levelID: levelID,
		x:       x,
		y:       y,
	}

	if pending, changed := r.pendingCells[cellKey]; changed {
		cell = pending
	}

	if !found {
		state.Push(lua.LNil)
	} else {
		state.Push(lua.LString(string(cell)))
	}

	return 1
}

// Return the player's saved terrain memory at a coordinate. An unexplored
// cell is nil, so Lua policies cannot mistake an unseen shop for a known one.
func (r *Runtime) luaGridRemembered(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	feature, found := r.services.Grid.Remembered(levelID, x, y)

	if !found || feature == terrain.Unseen {
		state.Push(lua.LNil)
	} else {
		state.Push(lua.LString(string(feature)))
	}

	return 1
}

// Keep actual sight distinct from remembered terrain. Xom's exploration
// estimate can count magic-mapped cells only when its source rule permits.
func (r *Runtime) luaGridSeen(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	seen, found := r.services.Grid.Seen(levelID, x, y)

	if !found {
		state.Push(lua.LNil)
	} else {
		state.Push(lua.LBool(seen))
	}

	return 1
}

// Return saved placement facts at one cell without giving Lua a mutable
// reference to the level's record slice. Rules interpret the typed facts.
func (r *Runtime) luaGridRecordsAt(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	records := r.services.Grid.RecordsAt(levelID, x, y)
	entries := make([]any, 0, len(records))

	for _, record := range records {
		entries = append(entries, map[string]any{
			"kind":       record.Kind,
			"source_id":  record.SourceID,
			"identity":   record.Identity,
			"x":          record.X,
			"y":          record.Y,
			"pending":    record.Pending,
			"overridden": record.Overridden,
			"arguments":  record.Arguments,
		})
	}

	converted, err := r.policyValue(entries)

	if err != nil {
		state.RaiseError("records at (%d,%d): %v", x, y, err)

		return 0
	}

	state.Push(converted)

	return 1
}

// Stage a compare-and-replace on one saved string argument. The old value
// and exact source identity make a confirmed action reject a changed map
// instead of silently editing whichever record later occupies the cell.
func (r *Runtime) luaGridReplaceRecordString(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	sourceID := state.CheckString(5)
	kind := state.CheckString(6)
	identity := state.CheckString(7)
	key := state.CheckString(8)
	expected := state.CheckString(9)
	replacement := state.CheckString(10)
	matches := 0

	for _, record := range r.services.Grid.RecordsAt(levelID, x, y) {
		if record.SourceID != sourceID ||
			record.Kind != kind ||
			record.Identity != identity {
			continue
		}

		value, found := record.Arguments[key].(string)

		if !found || value != expected {
			state.RaiseError("record %s argument %s changed", sourceID, key)

			return 0
		}

		matches++
	}

	if matches != 1 {
		state.RaiseError("expected one record %s at (%d,%d), found %d",
			sourceID, x, y, matches)

		return 0
	}

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply: func() error {
			return r.services.Grid.ReplaceRecordString(
				levelID, x, y, sourceID, kind, identity,
				key, expected, replacement)
		},
		undo: func() error {
			return r.services.Grid.ReplaceRecordString(
				levelID, x, y, sourceID, kind, identity,
				key, replacement, expected)
		},
	})

	return 0
}

func (r *Runtime) luaGridMarkerProperty(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	key := state.CheckString(5)
	value, found := r.services.Grid.MarkerProperty(levelID, x, y, key)

	if !found {
		state.Push(lua.LNil)
	} else {
		state.Push(lua.LString(value))
	}

	return 1
}

func (r *Runtime) luaGridLevelSize(state *lua.LState) int {
	levelID := state.CheckInt(2)
	width, height, found := r.services.Grid.Size(levelID)

	if !found {
		state.Push(lua.LNil)
		state.Push(lua.LNil)

		return 2
	}

	state.Push(lua.LNumber(width))
	state.Push(lua.LNumber(height))

	return 2
}

// Lua sees only saved levels already held by this game session. Returning
// sorted IDs keeps off-floor policy independent of Go map iteration order.
func (r *Runtime) luaGridLevelIDs(state *lua.LState) int {
	if r.services.Grid == nil {
		state.RaiseError("level IDs require a grid service")

		return 0
	}

	result := state.NewTable()

	for _, levelID := range r.services.Grid.LevelIDs() {
		result.Append(lua.LNumber(levelID))
	}

	state.Push(result)

	return 1
}

func (r *Runtime) luaGridLevelBranch(state *lua.LState) int {
	levelID := state.CheckInt(2)
	branchID, found := r.services.Grid.Branch(levelID)

	if !found {
		state.Push(lua.LNil)

		return 1
	}

	state.Push(lua.LString(branchID))

	return 1
}

// Lua reads the saved local branch depth from the same level record as its
// branch ID. Hell travel needs this without decoding a numeric level ID.
func (r *Runtime) luaGridLevelDepth(state *lua.LState) int {
	levelID := state.CheckInt(2)
	depth, found := r.services.Grid.Depth(levelID)

	if !found {
		state.Push(lua.LNil)

		return 1
	}

	state.Push(lua.LNumber(depth))

	return 1
}

func (r *Runtime) luaGridSetCell(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	feature := terrain.ID(state.CheckString(5))

	if !terrain.Valid(feature) {
		state.RaiseError("invalid grid terrain %q", feature)

		return 0
	}

	if _, found := r.services.Grid.Cell(levelID, x, y); !found {
		state.RaiseError("cannot change missing grid cell")

		return 0
	}

	cellKey := gridCell{
		levelID: levelID,
		x:       x,
		y:       y,
	}

	if !terrain.Walkable(feature) {
		if _, occupied := r.stagedActorAt(cellKey); occupied {
			state.RaiseError("terrain %q would block an actor", feature)

			return 0
		}
	}

	if _, linked := r.services.Grid.StairAt(levelID, x, y); linked &&
		!terrain.IsLinkedStair(feature) {
		state.RaiseError("terrain would remove a stair link")

		return 0
	}

	r.pendingCells[cellKey] = feature

	var previous terrain.ID

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply: func() error {
			previous, _ = r.services.Grid.Cell(levelID, x, y)

			return r.services.Grid.SetCell(levelID, x, y, feature)
		},
		undo: func() error {
			return r.services.Grid.SetCell(levelID, x, y, previous)
		},
	})

	return 0
}

// Xom stages a stair slide with the same reversible command path as terrain
// and actor movement. The level moves its link and glyph as one mutation.
func (r *Runtime) luaGridMoveStair(state *lua.LState) int {
	values := r.gridIntegers(state, 5)
	levelID := values[0]
	fromX, fromY := values[1], values[2]
	toX, toY := values[3], values[4]

	from, foundFrom := r.services.Grid.Cell(levelID, fromX, fromY)
	to, foundTo := r.services.Grid.Cell(levelID, toX, toY)

	if !foundFrom ||
		!foundTo ||
		!r.services.Grid.TravelFeatureAt(levelID, fromX, fromY) ||
		to != terrain.Floor {
		state.RaiseError("stair slide needs a travel feature and floor")

		return 0
	}

	if _, occupied := r.stagedActorAt(gridCell{
		levelID: levelID,
		x:       toX,
		y:       toY,
	}); occupied {
		state.RaiseError("stair slide destination is occupied")

		return 0
	}

	fromCell := gridCell{
		levelID: levelID,
		x:       fromX,
		y:       fromY,
	}

	toCell := gridCell{
		levelID: levelID,
		x:       toX,
		y:       toY,
	}

	r.pendingCells[fromCell] = terrain.Floor
	r.pendingCells[toCell] = from

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply: func() error {
			return r.services.Grid.MoveStair(levelID,
				fromX, fromY, toX, toY)
		},
		undo: func() error {
			return r.services.Grid.MoveStair(levelID,
				toX, toY, fromX, fromY)
		},
	})

	return 0
}

// A vault callback may recolour terrain after changing it. Stage the tint
// with structural commands so a failed Lua turn restores the previous view.
func (r *Runtime) luaGridSetCellColour(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	colour := state.CheckString(5)

	if colour == "" {
		state.RaiseError("cell colour cannot be empty")

		return 0
	}

	if _, found := r.services.Grid.Cell(levelID, x, y); !found {
		state.RaiseError("cannot recolour missing grid cell")

		return 0
	}

	previous, _ := r.services.Grid.CellColour(levelID, x, y)

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply: func() error {
			return r.services.Grid.SetCellColour(levelID, x, y, colour)
		},
		undo: func() error {
			return r.services.Grid.SetCellColour(levelID, x, y, previous)
		},
	})

	return 0
}

// Lua reads committed blood. The effect uses this to avoid clearing unrelated
// terrain state when a holy word passes over a cell.
func (r *Runtime) luaGridCellBlood(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	bloody, found := r.services.Grid.CellBlood(levelID, x, y)

	if !found {
		state.Push(lua.LNil)
	} else {
		state.Push(lua.LBool(bloody))
	}

	return 1
}

// Blood marks join the structural transaction so a later Lua failure
// restores the exact earlier value along with item and actor changes.
func (r *Runtime) luaGridSetCellBlood(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	bloody := state.CheckBool(5)
	previous, found := r.services.Grid.CellBlood(levelID, x, y)

	if !found {
		state.RaiseError("cannot mark missing grid cell")

		return 0
	}

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply: func() error {
			return r.services.Grid.SetCellBlood(levelID, x, y, bloody)
		},
		undo: func() error {
			return r.services.Grid.SetCellBlood(levelID, x, y, previous)
		},
	})

	return 0
}

func (r *Runtime) luaGridMapCell(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	previous, found := r.services.Grid.Remembered(levelID, x, y)

	if !found {
		state.RaiseError("cannot map missing grid cell")

		return 0
	}

	if previous != terrain.Unseen {
		state.Push(lua.LBool(false))

		return 1
	}

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply: func() error {
			return r.services.Grid.MapCell(levelID, x, y)
		},
		undo: func() error {
			return r.services.Grid.RestoreRemembered(levelID, x, y, previous)
		},
	})

	state.Push(lua.LBool(true))

	return 1
}

// Item detection is a saved grid marker, separate from remembered terrain.
// Staging and undo keep a failed Xom effect from publishing a false marker.
func (r *Runtime) luaGridDetectItem(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	previous, found := r.services.Grid.DetectedItem(levelID, x, y)

	if !found {
		state.RaiseError("cannot detect item at missing grid cell")

		return 0
	}

	if previous {
		state.Push(lua.LBool(false))

		return 1
	}

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply: func() error {
			return r.services.Grid.DetectItem(levelID, x, y)
		},
		undo: func() error {
			return r.services.Grid.RestoreDetectedItem(
				levelID, x, y, previous)
		},
	})

	state.Push(lua.LBool(true))

	return 1
}

// Sensed monster glyphs are map knowledge. Stage them so an event failure
// cannot leak a false marker into the player's saved map.
func (r *Runtime) luaGridDetectCreature(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	kindID := state.CheckString(5)
	previous, found := r.services.Grid.DetectedCreature(levelID, x, y)

	if !found || kindID == "" {
		state.RaiseError("cannot detect creature at missing cell or with empty kind")

		return 0
	}

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply: func() error {
			return r.services.Grid.SetDetectedCreature(levelID, x, y, kindID)
		},
		undo: func() error {
			return r.services.Grid.SetDetectedCreature(levelID, x, y, previous)
		},
	})

	state.Push(lua.LBool(true))

	return 1
}

// Each detection replaces old guesses, matching source map behavior. A
// detached snapshot also gives the transaction an exact rollback image.
func (r *Runtime) luaGridClearDetectedCreatures(state *lua.LState) int {
	levelID := state.CheckInt(2)
	previous, found := r.services.Grid.DetectedCreatures(levelID)

	if !found {
		state.RaiseError("cannot clear detected creatures on missing level")

		return 0
	}

	empty := make([][]string, len(previous))

	for y, row := range previous {
		empty[y] = make([]string, len(row))
	}

	r.pending = append(r.pending, structuralCommand{
		spatialLevel: levelID,
		apply: func() error {
			return r.services.Grid.LoadDetectedCreatures(levelID, empty)
		},
		undo: func() error {
			return r.services.Grid.LoadDetectedCreatures(levelID, previous)
		},
	})

	return 0
}

func (r *Runtime) luaGridWalkable(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	cellKey := gridCell{
		levelID: levelID,
		x:       x,
		y:       y,
	}

	state.Push(lua.LBool(r.stagedWalkable(cellKey)))

	return 1
}

// Walking and spatial solidity answer different questions at dangerous
// terrain. Xom's exploration estimate needs the latter classification.
func (r *Runtime) luaGridSolid(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	cellKey := gridCell{
		levelID: levelID,
		x:       x,
		y:       y,
	}

	feature, found := r.services.Grid.Cell(levelID, x, y)

	if pending, changed := r.pendingCells[cellKey]; changed {
		feature = pending
	}

	if !found {
		state.Push(lua.LNil)
	} else {
		state.Push(lua.LBool(terrain.Solid(feature)))
	}

	return 1
}

// Rules need the same terrain transparency used by line of sight. Keep
// classification in the generic terrain owner so Lua need not list every
// wall, door, and transparent feature to sample exploration correctly.
func (r *Runtime) luaGridOpaque(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	cellKey := gridCell{
		levelID: levelID,
		x:       x,
		y:       y,
	}

	feature, found := r.services.Grid.Cell(levelID, x, y)

	if pending, changed := r.pendingCells[cellKey]; changed {
		feature = pending
	}

	if !found {
		state.Push(lua.LNil)
	} else {
		state.Push(lua.LBool(terrain.Opaque(feature)))
	}

	return 1
}

func (r *Runtime) luaGridActorAt(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	entity, found := r.stagedActorAt(gridCell{
		levelID: levelID,
		x:       x,
		y:       y,
	})

	if !found {
		state.Push(lua.LNil)
	} else {
		state.Push(r.entityHandle(entity))
	}

	return 1
}

// actors_at is the explicit multi-occupant read for policies such as
// Fedhas. Ordinary actor_at keeps returning the primary actor.
func (r *Runtime) luaGridActorsAt(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	actors := r.stagedActorsAt(gridCell{
		levelID: levelID,
		x:       x,
		y:       y,
	})
	result := state.NewTable()

	for _, actor := range actors {
		result.Append(r.entityHandle(actor))
	}

	state.Push(result)

	return 1
}

func (r *Runtime) luaGridStairAt(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	stair, found := r.services.Grid.StairAt(levelID, x, y)

	if !found {
		state.Push(lua.LNil)

		return 1
	}

	value := state.NewTable()
	state.SetField(value, "to_level_id", lua.LNumber(stair.ToLevelID))
	state.SetField(value, "to_x", lua.LNumber(stair.ToX))
	state.SetField(value, "to_y", lua.LNumber(stair.ToY))
	state.SetField(value, "unavailable", lua.LString(stair.Unavailable))
	state.SetField(value, "exit", lua.LBool(stair.Exit))
	state.SetField(value, "target_branch_id", lua.LString(stair.TargetBranchID))
	state.Push(value)

	return 1
}

// A boolean travel query keeps Go's feature list out of Lua policy. The
// source Xom rule excludes shops even though they also use an entry glyph.
func (r *Runtime) luaGridTravelFeatureAt(state *lua.LState) int {
	levelID, x, y := r.gridArgs(state)
	state.Push(lua.LBool(r.services.Grid.TravelFeatureAt(levelID, x, y)))

	return 1
}

func (r *Runtime) luaGridVisible(state *lua.LState) int {
	coordinates := r.gridIntegers(state, 6)
	visible, err := r.services.Grid.Visible(
		coordinates[0], coordinates[1], coordinates[2],
		coordinates[3], coordinates[4], coordinates[5],
	)

	if err != nil {
		state.RaiseError("grid visibility: %v", err)

		return 0
	}

	state.Push(lua.LBool(visible))

	return 1
}

// No-trans sight blocks transparent walls while retaining ordinary sight
// through actors, so Lua cries and support spells need no projectile ray.
func (r *Runtime) luaGridVisibleNoTrans(state *lua.LState) int {
	coordinates := r.gridIntegers(state, 6)
	visible, err := r.services.Grid.VisibleNoTrans(
		coordinates[0], coordinates[1], coordinates[2],
		coordinates[3], coordinates[4], coordinates[5],
	)

	if err != nil {
		state.RaiseError("grid no-trans visibility: %v", err)

		return 0
	}

	state.Push(lua.LBool(visible))

	return 1
}

// Evaluate sight with temporary opaque cells without changing terrain or the
// queued Lua writes. Seal Doors uses this to compare a closed doorway first.
func (r *Runtime) luaGridVisibleNoTransWithBlocked(state *lua.LState) int {
	coordinates := r.gridIntegers(state, 6)
	points := state.CheckTable(8)
	blocked := make([]VisibleCell, 0, points.Len())

	for index := 1; index <= points.Len(); index++ {
		point, ok := points.RawGetInt(index).(*lua.LTable)

		if !ok {
			state.RaiseError("blocked sight cell %d must be a table", index)

			return 0
		}

		x, xerr := exactLuaNumber(point.RawGetString("x"))
		y, yerr := exactLuaNumber(point.RawGetString("y"))

		if xerr != nil ||
			yerr != nil ||
			x < -2147483648 ||
			x > 2147483647 ||
			y < -2147483648 ||
			y > 2147483647 {
			state.RaiseError("blocked sight cell %d needs integer x and y", index)

			return 0
		}

		blocked = append(blocked, VisibleCell{
			X: int(x),
			Y: int(y),
		})
	}

	visible, err := r.services.Grid.VisibleNoTransWithBlocked(
		coordinates[0], coordinates[1], coordinates[2],
		coordinates[3], coordinates[4], coordinates[5], blocked,
	)

	if err != nil {
		state.RaiseError("grid hypothetical no-trans visibility: %v", err)

		return 0
	}

	state.Push(lua.LBool(visible))

	return 1
}

func (r *Runtime) luaGridVisibleCells(state *lua.LState) int {
	coordinates := r.gridIntegers(state, 4)
	cells, err := r.services.Grid.VisibleCells(
		coordinates[0], coordinates[1], coordinates[2], coordinates[3],
	)

	if err != nil {
		state.RaiseError("grid visible cells: %v", err)

		return 0
	}

	result := state.NewTable()

	for _, cell := range cells {
		point := state.NewTable()
		state.SetField(point, "x", lua.LNumber(cell.X))
		state.SetField(point, "y", lua.LNumber(cell.Y))
		result.Append(point)
	}

	state.Push(result)

	return 1
}

func (r *Runtime) luaGridRouteStep(state *lua.LState) int {
	coordinates := r.gridIntegers(state, 5)
	var goal akara.Entity

	if value := state.Get(7); value != lua.LNil {
		handle, ok := value.(*lua.LUserData)

		if !ok {
			state.RaiseError("route goal must be an entity handle")

			return 0
		}

		goal, ok = handle.Value.(akara.Entity)

		if !ok {
			state.RaiseError("route goal must be an entity handle")

			return 0
		}
	}

	dx, dy, found := r.services.Grid.RouteStep(
		coordinates[0], coordinates[1], coordinates[2],
		coordinates[3], coordinates[4], goal,
	)

	if !found {
		state.Push(lua.LNil)
		state.Push(lua.LNil)
		state.Push(lua.LFalse)

		return 3
	}

	state.Push(lua.LNumber(dx))
	state.Push(lua.LNumber(dy))
	state.Push(lua.LTrue)

	return 3
}

func (r *Runtime) luaGridProjectileClear(state *lua.LState) int {
	coordinates := r.gridIntegers(state, 5)
	clear := r.services.Grid.ProjectileClear(
		coordinates[0], coordinates[1], coordinates[2],
		coordinates[3], coordinates[4],
	)
	state.Push(lua.LBool(clear))

	return 1
}

func (r *Runtime) luaGridMoveActor(state *lua.LState) int {
	entity := r.gridEntity(state)
	coordinates := r.gridIntegersAfterEntity(state, 3)
	share := state.GetTop() >= 6 && state.CheckBool(6)
	old, positioned, err := r.stagedPosition(entity)
	next := gridCell{
		levelID: coordinates[0],
		x:       coordinates[1],
		y:       coordinates[2],
	}

	if err != nil ||
		!positioned {
		state.RaiseError("move actor %d has no valid position: %v", entity, err)

		return 0
	}

	if !r.stagedHasActor(old, entity) || !r.stagedWalkable(next) {
		state.RaiseError("move actor %d has invalid source or destination", entity)

		return 0
	}

	if occupant, occupied := r.stagedActorAt(next); occupied &&
		occupant != entity && !share {
		state.RaiseError("move actor %d destination is occupied", entity)

		return 0
	}

	oldActors := r.stagedActorsAt(old)
	wasPrimary := len(oldActors) > 0 && oldActors[0] == entity
	r.stageActorPositionShared(entity, &old, &next, share)
	r.pending = append(r.pending, structuralCommand{
		entity:       entity,
		spatialLevel: old.levelID,
		apply: func() error {
			if share {
				return r.services.Grid.MoveActorShared(
					entity, next.levelID, next.x, next.y, true,
				)
			}

			return r.services.Grid.MoveActor(
				entity, next.levelID, next.x, next.y,
			)
		},
		undo: func() error {
			return r.services.Grid.MoveActorShared(
				entity, old.levelID, old.x, old.y, wasPrimary,
			)
		},
	})

	return 0
}

func (r *Runtime) luaGridPlaceActor(state *lua.LState) int {
	entity := r.gridEntity(state)
	coordinates := r.gridIntegersAfterEntity(state, 3)
	share := state.GetTop() >= 6 && state.CheckBool(6)
	next := gridCell{
		levelID: coordinates[0],
		x:       coordinates[1],
		y:       coordinates[2],
	}

	_, positioned, err := r.stagedPosition(entity)

	if err != nil ||
		positioned {
		state.RaiseError("place actor %d is already positioned: %v", entity, err)

		return 0
	}

	feature, _ := r.services.Grid.Cell(next.levelID, next.x, next.y)

	if pending, changed := r.pendingCells[next]; changed {
		feature = pending
	}

	if !r.stagedWalkable(next) && feature != terrain.MalignGateway {
		state.RaiseError("place actor %d destination is blocked", entity)

		return 0
	}

	if _, occupied := r.stagedActorAt(next); occupied && !share {
		state.RaiseError("place actor %d destination is occupied", entity)

		return 0
	}

	r.stageActorPositionShared(entity, nil, &next, false)
	r.pending = append(r.pending, structuralCommand{
		entity:       entity,
		spatialLevel: next.levelID,
		apply: func() error {
			if share {
				return r.services.Grid.PlaceActorShared(
					entity, next.levelID, next.x, next.y, false,
				)
			}

			return r.services.Grid.PlaceActor(
				entity, next.levelID, next.x, next.y,
			)
		},
		undo: func() error {
			return r.services.Grid.RemoveActor(entity, next.levelID)
		},
	})

	return 0
}

func (r *Runtime) luaGridRemoveActor(state *lua.LState) int {
	entity := r.gridEntity(state)
	coordinates := r.gridIntegersAfterEntity(state, 1)
	old, positioned, err := r.stagedPosition(entity)

	if err != nil ||
		!positioned ||
		old.levelID != coordinates[0] {
		state.RaiseError("remove actor %d has invalid position: %v", entity, err)

		return 0
	}

	if !r.stagedHasActor(old, entity) {
		state.RaiseError("remove actor %d is not indexed", entity)

		return 0
	}

	oldActors := r.stagedActorsAt(old)
	wasPrimary := len(oldActors) > 0 && oldActors[0] == entity
	r.stageActorPosition(entity, &old, nil)
	r.pending = append(r.pending, structuralCommand{
		entity:       entity,
		spatialLevel: old.levelID,
		apply: func() error {
			return r.services.Grid.RemoveActor(entity, old.levelID)
		},
		undo: func() error {
			return r.services.Grid.PlaceActorShared(
				entity, old.levelID, old.x, old.y, wasPrimary,
			)
		},
	})

	return 0
}

func (r *Runtime) gridEntity(state *lua.LState) akara.Entity {
	handle := state.CheckUserData(2)
	entity, ok := handle.Value.(akara.Entity)

	if !ok ||
		!r.world.EntityExists(entity) ||
		r.pendingDestroy[entity] {
		state.RaiseError("grid operation requires an existing entity")
	}

	return entity
}

func (r *Runtime) gridIntegersAfterEntity(state *lua.LState, count int) []int {
	if r.services.Grid == nil {
		state.RaiseError("grid service is unavailable")
	}

	coordinates := make([]int, count)

	for index := range coordinates {
		number, err := exactLuaNumber(state.Get(index + 3))

		if err != nil ||
			number < -2147483648 ||
			number > 2147483647 {
			state.RaiseError("grid coordinate %d must be an integer", index+1)
		}

		coordinates[index] = int(number)
	}

	return coordinates
}

func (r *Runtime) luaCurrentAut(state *lua.LState) int {
	if r.services.CurrentAut == nil {
		state.RaiseError("action clock is unavailable")

		return 0
	}

	value := r.services.CurrentAut()

	if value > maxExactLuaInteger || value < -maxExactLuaInteger {
		state.RaiseError("action clock exceeds Lua's exact integer range")

		return 0
	}

	state.Push(lua.LNumber(value))

	return 1
}

func (r *Runtime) luaSetComponent(state *lua.LState) int {
	entity, name, store, host := r.componentArgs(state)

	if !r.componentHas(name, entity) {
		state.RaiseError("entity %d has no %s; use add", entity, name)

		return 0
	}

	values := state.CheckTable(4)
	converted, err := decodeComponentValues(store, host, values)

	if err != nil {
		state.RaiseError("set %s on entity %d: %v", name, entity, err)

		return 0
	}

	converted = withDynamicDefaults(store, converted)

	target := componentTarget{
		entity: entity,
		name:   name,
	}

	if view, queued := r.pendingViews[target]; queued {
		view.values = converted

		return 0
	}

	view := &pendingComponent{
		present: true,
		values:  converted,
	}

	r.pendingViews[target] = view
	r.pending = append(r.pending, componentCommand(entity, store, host, view))

	return 0
}

func (r *Runtime) luaAddComponent(state *lua.LState) int {
	entity, name, store, host := r.componentArgs(state)

	if r.pendingDestroy[entity] {
		state.RaiseError("cannot add %s to destroyed entity %d", name, entity)

		return 0
	}

	if r.componentHas(name, entity) {
		state.RaiseError("entity %d already has %s; use set", entity, name)

		return 0
	}

	values := state.CheckTable(4)
	converted, err := decodeComponentValues(store, host, values)

	if err != nil {
		state.RaiseError("add %s on entity %d: %v", name, entity, err)

		return 0
	}

	converted = withDynamicDefaults(store, converted)

	if !r.world.EntityExists(entity) {
		state.RaiseError("add %s on missing entity %d", name, entity)

		return 0
	}

	view := &pendingComponent{
		present: true,
		values:  converted,
	}

	target := componentTarget{
		entity: entity,
		name:   name,
	}

	r.pendingViews[target] = view
	r.pending = append(r.pending, componentCommand(entity, store, host, view))

	return 0
}

func decodeComponentValues(
	store *akara.DynamicStore,
	host HostComponent,
	values *lua.LTable,
) (map[string]any, error) {
	if store == nil {
		return host.Decode(values)
	}

	return componentValues(store.Schema(), values)
}

func (r *Runtime) luaRemoveComponent(state *lua.LState) int {
	entity, name, store, host := r.componentArgs(state)

	if !r.world.EntityExists(entity) || r.pendingDestroy[entity] {
		state.RaiseError("remove component from missing entity %d", entity)

		return 0
	}

	target := componentTarget{
		entity: entity,
		name:   name,
	}

	view := &pendingComponent{}

	r.pendingViews[target] = view
	r.pending = append(r.pending, componentCommand(entity, store, host, view))

	return 0
}

func (r *Runtime) componentHas(name string, entity akara.Entity) bool {
	if r.pendingDestroy[entity] {
		return false
	}

	target := componentTarget{
		entity: entity,
		name:   name,
	}

	if view, queued := r.pendingViews[target]; queued {
		return view.present
	}

	if store, found := r.components[name]; found {
		return store.Has(entity)
	}

	return r.hostComponents[name].Has(entity)
}

func (r *Runtime) luaDestroyEntity(state *lua.LState) int {
	handle := state.CheckUserData(2)
	entity, ok := handle.Value.(akara.Entity)

	if !ok || !r.world.EntityExists(entity) {
		state.RaiseError("destroy requires an existing entity handle")

		return 0
	}

	r.pendingDestroy[entity] = true
	r.pending = append(r.pending, structuralCommand{
		entity:  entity,
		destroy: true,
		apply: func() error {
			r.world.DestroyEntity(entity)

			return nil
		},
	})

	return 0
}

func (r *Runtime) luaCreateEntity(state *lua.LState) int {
	entity, err := r.world.CreateEntity()

	if err != nil {
		state.RaiseError("create entity: %v", err)

		return 0
	}

	if r.services.EntityCreated != nil {
		r.services.EntityCreated(entity)
	}

	r.created = append(r.created, entity)
	state.Push(r.entityHandle(entity))

	return 1
}

func (r *Runtime) componentEntities(name string) []akara.Entity {
	if store, found := r.components[name]; found {
		return store.Entities()
	}

	return r.hostComponents[name].Entities()
}

func (r *Runtime) componentStore(name string) (*akara.DynamicStore, error) {
	store, found := r.components[name]

	if !found {
		return nil, fmt.Errorf("unknown component %s", name)
	}

	return store, nil
}

func (r *Runtime) luaActiveActor(state *lua.LState) int {
	if r.services.ActiveActor == nil {
		state.RaiseError("active actor is unavailable")

		return 0
	}

	entity := r.services.ActiveActor()

	if entity == 0 {
		state.Push(lua.LNil)

		return 1
	}

	state.Push(r.entityHandle(entity))

	return 1
}

func (r *Runtime) luaPlayerEntity(state *lua.LState) int {
	if r.services.PlayerEntity == nil {
		state.RaiseError("player entity is unavailable")

		return 0
	}

	entity := r.services.PlayerEntity()

	if entity == 0 {
		state.Push(lua.LNil)

		return 1
	}

	state.Push(r.entityHandle(entity))

	return 1
}

func (r *Runtime) luaRandom(state *lua.LState) int {
	if r.services.Random == nil {
		state.RaiseError("named RNG is unavailable")

		return 0
	}

	stream := state.CheckString(2)
	boundNumber, err := exactLuaNumber(state.Get(3))

	if err != nil {
		state.RaiseError("random bound: %v", err)

		return 0
	}

	bound := int(boundNumber)

	if bound < 1 {
		state.RaiseError("random bound must be positive")

		return 0
	}

	r.checkpointRandom()
	value, err := r.services.Random(stream, bound)

	if err != nil {
		state.RaiseError("random stream %s: %v", stream, err)

		return 0
	}

	state.Push(lua.LNumber(value))

	return 1
}

// Create one private seeded PCG stream. Lua owns the policy that consumes
// these draws; the Go kernel only supplies source-compatible random words.
// The table must remain local to the operation because its cursor is not
// saved. A caller saves the generated value or the seed for later replay.
func (r *Runtime) luaSubgenerator(state *lua.LState) int {
	value, err := exactLuaNumber(state.Get(2))

	if err != nil ||
		value < 0 ||
		value > 4294967295 {
		state.RaiseError("subgenerator sequence must be a uint32")

		return 0
	}

	private := newSourceSubgenerator(r.services.GameSeed, uint64(value))
	table := state.NewTable()

	state.SetField(table, "random", state.NewFunction(func(state *lua.LState) int {
		value, err := exactLuaNumber(state.Get(2))

		if err != nil ||
			value < 1 ||
			value > 4294967295 {
			state.RaiseError("subgenerator bound must be a positive uint32")

			return 0
		}

		state.Push(lua.LNumber(private.intn(uint32(value))))

		return 1
	}))

	state.Push(table)

	return 1
}

// Lua numbers can represent each half of a SplitMix64 draw exactly. Keeping
// the halves separate also lets Lua reproduce source rejection sampling.
func (r *Runtime) luaRandomWord(state *lua.LState) int {
	if r.services.RandomWord == nil {
		state.RaiseError("named RNG words are unavailable")

		return 0
	}

	stream := state.CheckString(2)

	if stream == "" {
		state.RaiseError("random stream name is empty")

		return 0
	}

	r.checkpointRandom()
	word := r.services.RandomWord(stream)
	state.Push(lua.LNumber(word >> 32))
	state.Push(lua.LNumber(word & 0xffffffff))

	return 2
}

func (r *Runtime) luaEmit(state *lua.LState) int {
	if r.services.Emit == nil {
		state.RaiseError("event emission is unavailable")

		return 0
	}

	kind := state.CheckString(2)
	message := state.CheckString(3)
	r.services.Emit(kind, message)

	return 0
}

func (r *Runtime) luaSignal(state *lua.LState) int {
	name := state.CheckString(2)
	value := state.Get(3)

	if name == "" || value == lua.LNil {
		state.RaiseError("signal requires a name and value")

		return 0
	}

	if table, ok := value.(*lua.LTable); ok {
		value = copyDefinitionTable(state, table)
	}

	r.signals[name] = append(r.signals[name], value)

	return 0
}

func (r *Runtime) luaSignals(state *lua.LState) int {
	name := state.CheckString(2)
	result := state.NewTable()

	for _, value := range r.signals[name] {
		if table, ok := value.(*lua.LTable); ok {
			value = copyDefinitionTable(state, table)
		}

		result.Append(value)
	}

	state.Push(result)

	return 1
}
