package script

import (
	"fmt"
	"slices"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

func (r *Runtime) installContextAPI() {
	context := r.state.NewTable()

	r.state.SetField(context, "get", r.state.NewFunction(r.luaGetComponent))
	r.state.SetField(context, "set", r.state.NewFunction(r.luaSetComponent))
	r.state.SetField(context, "add", r.state.NewFunction(r.luaAddComponent))
	r.state.SetField(context, "remove", r.state.NewFunction(r.luaRemoveComponent))
	r.state.SetField(context, "has", r.state.NewFunction(r.luaHasComponent))
	r.state.SetField(context, "actor", r.state.NewFunction(r.luaActiveActor))
	r.state.SetField(context, "random", r.state.NewFunction(r.luaRandom))
	r.state.SetField(context, "emit", r.state.NewFunction(r.luaEmit))

	r.context = context
}

func (r *Runtime) componentArgs(
	state *lua.LState,
) (akara.Entity, string, *akara.DynamicStore) {
	handle := state.CheckUserData(2)
	entity, ok := handle.Value.(akara.Entity)

	if !ok {
		state.RaiseError("expected entity handle")

		return 0, "", nil
	}

	name := state.CheckString(3)
	store, found := r.components[name]

	if !found {
		state.RaiseError("unknown Lua component %s", name)

		return 0, "", nil
	}

	return entity, name, store
}

func (r *Runtime) luaGetComponent(state *lua.LState) int {
	entity, name, store := r.componentArgs(state)
	component, found := store.Get(entity)

	if !found {
		state.Push(lua.LNil)

		return 1
	}

	values, err := component.Snapshot()

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
	entity, _, store := r.componentArgs(state)
	state.Push(lua.LBool(store.Has(entity)))

	return 1
}

func (r *Runtime) luaSetComponent(state *lua.LState) int {
	entity, name, store := r.componentArgs(state)

	if !store.Has(entity) {
		state.RaiseError("entity %d has no %s; use add", entity, name)

		return 0
	}

	values := state.CheckTable(4)
	converted, err := componentValues(store.Schema(), values)

	if err != nil {
		state.RaiseError("set %s on entity %d: %v", name, entity, err)

		return 0
	}

	if _, err := store.Set(entity, converted); err != nil {
		state.RaiseError("set %s on entity %d: %v", name, entity, err)
	}

	return 0
}

func (r *Runtime) luaAddComponent(state *lua.LState) int {
	entity, name, store := r.componentArgs(state)

	if store.Has(entity) {
		state.RaiseError("entity %d already has %s; use set", entity, name)

		return 0
	}

	values := state.CheckTable(4)
	converted, err := componentValues(store.Schema(), values)

	if err != nil {
		state.RaiseError("add %s on entity %d: %v", name, entity, err)

		return 0
	}

	if !r.world.EntityExists(entity) {
		state.RaiseError("add %s on missing entity %d", name, entity)

		return 0
	}

	r.pending.AddDynamic(store, entity, converted)
	r.pendingTargets = append(r.pendingTargets, entity)

	return 0
}

func (r *Runtime) luaRemoveComponent(state *lua.LState) int {
	entity, _, store := r.componentArgs(state)

	if !r.world.EntityExists(entity) {
		state.RaiseError("remove component from missing entity %d", entity)

		return 0
	}

	r.pending.Remove(store, entity)
	r.pendingTargets = append(r.pendingTargets, entity)

	return 0
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
