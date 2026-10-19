package script

import lua "github.com/yuin/gopher-lua"

// Shoals elevation is level data, while Lua decides how water uses it.
func (r *Runtime) luaGridShoalsHeight(state *lua.LState) int {
	levelID := state.CheckInt(2)
	x := state.CheckInt(3)
	y := state.CheckInt(4)
	height, found := r.services.Grid.ShoalsHeight(levelID, x, y)

	if !found {
		state.Push(lua.LNil)

		return 1
	}

	state.Push(lua.LNumber(height))

	return 1
}

// The raw clock is independent of the current water feature and survives
// loading a saved Shoals floor.
func (r *Runtime) luaGridShoalsTideClock(state *lua.LState) int {
	levelID := state.CheckInt(2)
	height, velocity, lastAut, found := r.services.Grid.ShoalsTideClock(levelID)

	if !found {
		state.Push(lua.LNil)
		state.Push(lua.LNil)
		state.Push(lua.LNil)

		return 3
	}

	state.Push(lua.LNumber(height))
	state.Push(lua.LNumber(velocity))
	state.Push(lua.LNumber(lastAut))

	return 3
}

func (r *Runtime) luaGridSetShoalsTideClock(state *lua.LState) int {
	levelID := state.CheckInt(2)
	height := state.CheckInt(3)
	velocity := state.CheckInt(4)
	lastAut := int64(state.CheckNumber(5))

	if err := r.services.Grid.SetShoalsTideClock(
		levelID, height, velocity, lastAut,
	); err != nil {
		state.RaiseError("set Shoals tide clock: %v", err)
	}

	return 0
}
