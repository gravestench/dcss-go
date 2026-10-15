package script

import (
	"fmt"
	"math"
	"slices"

	lua "github.com/yuin/gopher-lua"
)

// mod.null keeps an explicit null distinct from an omitted Lua field.
type definitionNull struct{}

func (r *Runtime) luaRegisterSpecies(state *lua.LState) int {
	return r.registerDefinition(state, "species")
}

func (r *Runtime) luaRegisterJob(state *lua.LState) int {
	return r.registerDefinition(state, "jobs")
}

func (r *Runtime) registerDefinition(state *lua.LState, category string) int {
	if r.frozen {
		state.RaiseError("Lua registration is closed")

		return 0
	}

	table := state.CheckTable(1)
	id := requiredString(state, table, "id")
	entries := r.definitions[category]

	if _, found := entries[id]; found {
		state.RaiseError("duplicate %s %s", category, id)

		return 0
	}

	if _, err := luaDefinitionValue(table, make(map[*lua.LTable]bool)); err != nil {
		state.RaiseError("%s %s in %s: %v", category, id, r.currentModule(), err)

		return 0
	}

	entries[id] = copyDefinitionTable(state, table)
	r.definitionOrigins[category][id] = r.currentModule()

	return 0
}

func (r *Runtime) DefinitionIDs(category string) []string {
	entries := r.definitions[category]
	ids := make([]string, 0, len(entries))

	for id := range entries {
		ids = append(ids, id)
	}

	slices.Sort(ids)

	return ids
}

func (r *Runtime) luaRegisteredIDs(state *lua.LState) int {
	category := state.CheckString(1)

	if _, found := r.definitions[category]; !found {
		state.RaiseError("unknown registered content category %s", category)

		return 0
	}

	result := state.NewTable()

	for index, id := range r.DefinitionIDs(category) {
		result.RawSetInt(index+1, lua.LString(id))
	}

	state.Push(result)

	return 1
}

func (r *Runtime) luaRegisteredOrigin(state *lua.LState) int {
	category := state.CheckString(1)
	id := state.CheckString(2)
	origins, found := r.definitionOrigins[category]

	if !found {
		state.RaiseError("unknown registered %s ID %s", category, id)

		return 0
	}

	origin, found := origins[id]

	if !found {
		state.RaiseError("unknown registered %s ID %s", category, id)

		return 0
	}

	state.Push(lua.LString(origin))

	return 1
}

func (r *Runtime) luaRegisteredDefinition(state *lua.LState) int {
	category := state.CheckString(1)
	id := state.CheckString(2)
	entries, found := r.definitions[category]

	if !found {
		state.RaiseError("unknown registered content category %s", category)

		return 0
	}

	definition, found := entries[id]

	if !found {
		state.RaiseError("unknown registered %s ID %s", category, id)

		return 0
	}

	state.Push(copyDefinitionTable(state, definition))

	return 1
}

func (r *Runtime) currentModule() string {
	if len(r.moduleStack) == 0 {
		return "<unknown Lua module>"
	}

	return r.moduleStack[len(r.moduleStack)-1]
}

func luaDefinitionValue(
	value lua.LValue,
	visiting map[*lua.LTable]bool,
) (any, error) {
	switch typed := value.(type) {
	case lua.LBool:
		return bool(typed), nil

	case lua.LString:
		return string(typed), nil

	case lua.LNumber:
		number := float64(typed)

		if math.IsNaN(number) || math.IsInf(number, 0) {
			return nil, fmt.Errorf("definition contains nonfinite number")
		}

		if math.Abs(number) > maxExactLuaInteger {
			return nil, fmt.Errorf("definition number exceeds Lua's exact range")
		}

		if math.Trunc(number) == number {
			return int64(number), nil
		}

		return number, nil

	case *lua.LTable:
		return luaDefinitionTable(typed, visiting)

	case *lua.LUserData:
		if _, ok := typed.Value.(definitionNull); ok {
			return nil, nil
		}

		return nil, fmt.Errorf("unsupported Lua definition userdata")

	default:
		return nil, fmt.Errorf("unsupported Lua definition value %s", value.Type())
	}
}

func luaDefinitionTable(
	table *lua.LTable,
	visiting map[*lua.LTable]bool,
) (any, error) {
	if visiting[table] {
		return nil, fmt.Errorf("cyclic Lua definition table")
	}

	visiting[table] = true
	defer delete(visiting, table)

	strings := make(map[string]any)
	numbers := make(map[int]any)
	var conversionErr error

	table.ForEach(func(key, value lua.LValue) {
		if conversionErr != nil {
			return
		}

		converted, err := luaDefinitionValue(value, visiting)

		if err != nil {
			conversionErr = err

			return
		}

		switch typed := key.(type) {
		case lua.LString:
			strings[string(typed)] = converted

		case lua.LNumber:
			index, err := exactLuaNumber(typed)

			if err != nil {
				conversionErr = fmt.Errorf("definition array index must be an exact integer")

				return
			}

			if index < 1 || index > 1<<20 {
				conversionErr = fmt.Errorf("definition array index must be 1..1048576")

				return
			}

			numbers[int(index)] = converted

		default:
			conversionErr = fmt.Errorf("definition table has nonstring, nonarray key")
		}
	})

	if conversionErr != nil {
		return nil, conversionErr
	}

	if len(strings) > 0 && len(numbers) > 0 {
		return nil, fmt.Errorf("definition table mixes object and array keys")
	}

	if len(strings) > 0 {
		return strings, nil
	}

	array := make([]any, len(numbers))

	for index := 1; index <= len(numbers); index++ {
		value, found := numbers[index]

		if !found {
			return nil, fmt.Errorf("definition array has a missing index")
		}

		array[index-1] = value
	}

	return array, nil
}
