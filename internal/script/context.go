package script

import (
	"fmt"
	"slices"

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
	r.state.SetField(context, "marker_property", r.state.NewFunction(r.luaGridMarkerProperty))
	r.state.SetField(context, "level_size", r.state.NewFunction(r.luaGridLevelSize))
	r.state.SetField(context, "level_branch", r.state.NewFunction(r.luaGridLevelBranch))
	r.state.SetField(context, "level_depth", r.state.NewFunction(r.luaGridLevelDepth))
	r.state.SetField(context, "shoals_height", r.state.NewFunction(r.luaGridShoalsHeight))
	r.state.SetField(context, "shoals_tide_clock", r.state.NewFunction(r.luaGridShoalsTideClock))
	r.state.SetField(context, "set_shoals_tide_clock", r.state.NewFunction(r.luaGridSetShoalsTideClock))
	r.state.SetField(context, "set_cell", r.state.NewFunction(r.luaGridSetCell))
	r.state.SetField(context, "set_cell_colour", r.state.NewFunction(r.luaGridSetCellColour))
	r.state.SetField(context, "map_cell", r.state.NewFunction(r.luaGridMapCell))
	r.state.SetField(context, "walkable", r.state.NewFunction(r.luaGridWalkable))
	r.state.SetField(context, "actor_at", r.state.NewFunction(r.luaGridActorAt))
	r.state.SetField(context, "stair_at", r.state.NewFunction(r.luaGridStairAt))
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
	r.state.SetField(context, "random_u64", r.state.NewFunction(r.luaRandomWord))
	r.state.SetField(context, "emit", r.state.NewFunction(r.luaEmit))
	r.state.SetField(context, "signal", r.state.NewFunction(r.luaSignal))
	r.state.SetField(context, "signals", r.state.NewFunction(r.luaSignals))

	r.context = context
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
		apply: func() error {
			return r.services.Grid.SetCellColour(levelID, x, y, colour)
		},
		undo: func() error {
			return r.services.Grid.SetCellColour(levelID, x, y, previous)
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

	indexed, found := r.stagedActorAt(old)

	if !found ||
		indexed != entity ||
		!r.stagedWalkable(next) {
		state.RaiseError("move actor %d has invalid source or destination", entity)

		return 0
	}

	if occupant, occupied := r.stagedActorAt(next); occupied &&
		occupant != entity {
		state.RaiseError("move actor %d destination is occupied", entity)

		return 0
	}

	r.stageActorPosition(entity, &old, &next)
	r.pending = append(r.pending, structuralCommand{
		entity: entity,
		apply: func() error {
			return r.services.Grid.MoveActor(
				entity, next.levelID, next.x, next.y,
			)
		},
		undo: func() error {
			return r.services.Grid.MoveActor(
				entity, old.levelID, old.x, old.y,
			)
		},
	})

	return 0
}

func (r *Runtime) luaGridPlaceActor(state *lua.LState) int {
	entity := r.gridEntity(state)
	coordinates := r.gridIntegersAfterEntity(state, 3)
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

	if _, occupied := r.stagedActorAt(next); occupied {
		state.RaiseError("place actor %d destination is occupied", entity)

		return 0
	}

	r.stageActorPosition(entity, nil, &next)
	r.pending = append(r.pending, structuralCommand{
		entity: entity,
		apply: func() error {
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

	indexed, found := r.stagedActorAt(old)

	if !found || indexed != entity {
		state.RaiseError("remove actor %d is not indexed", entity)

		return 0
	}

	r.stageActorPosition(entity, &old, nil)
	r.pending = append(r.pending, structuralCommand{
		entity: entity,
		apply: func() error {
			return r.services.Grid.RemoveActor(entity, old.levelID)
		},
		undo: func() error {
			return r.services.Grid.PlaceActor(
				entity, old.levelID, old.x, old.y,
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

	value, err := r.services.Random(stream, bound)

	if err != nil {
		state.RaiseError("random stream %s: %v", stream, err)

		return 0
	}

	state.Push(lua.LNumber(value))

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
