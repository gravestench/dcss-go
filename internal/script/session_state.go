package script

import lua "github.com/yuin/gopher-lua"

// session_state gives Lua a detached copy of one named saved record.
// The pending view wins so several policies in one action see the same
// proposed state before the game owner has committed it.
func (r *Runtime) luaSessionState(state *lua.LState) int {
	name := state.CheckString(2)
	host, found := r.services.SessionStates[name]

	if !found || host.Read == nil {
		state.RaiseError("session state %s is unavailable", name)

		return 0
	}

	values, pending := r.pendingSession[name]

	if !pending {
		var err error

		values, err = host.Read()

		if err != nil {
			state.RaiseError("read session state %s: %v", name, err)

			return 0
		}
	}

	if values == nil {
		state.Push(lua.LNil)

		return 1
	}

	table, err := r.policyTable(values)

	if err != nil {
		state.RaiseError("encode session state %s: %v", name, err)

		return 0
	}

	state.Push(table)

	return 1
}

// replace_session_state stages a validated owner change behind the same
// action barrier as terrain and ECS changes. A later error calls Undo in
// reverse order, restoring state before its old region is restored.
func (r *Runtime) luaReplaceSessionState(state *lua.LState) int {
	name := state.CheckString(2)
	host, found := r.services.SessionStates[name]

	if !found || host.Prepare == nil {
		state.RaiseError("session state %s is unavailable", name)

		return 0
	}

	table := state.CheckTable(3)
	values, err := policyValues(table)

	if err != nil {
		state.RaiseError("session state %s: %v", name, err)

		return 0
	}

	change, err := host.Prepare(values)

	if err != nil {
		state.RaiseError("invalid session state %s: %v", name, err)

		return 0
	}

	if r.pendingSession == nil {
		r.pendingSession = make(map[string]map[string]any)
	}

	r.pendingSession[name] = values
	r.pending = append(r.pending, structuralCommand{
		apply: change.Apply,
		undo:  change.Undo,
	})

	return 0
}
