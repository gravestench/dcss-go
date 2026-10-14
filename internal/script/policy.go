package script

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

// Policies are named Lua decisions that run outside the Akara system loop.
// A caller passes plain values; the callback reads live state through ctx.
func (r *Runtime) luaRegisterPolicy(state *lua.LState) int {
	if r.frozen {
		state.RaiseError("Lua registration is closed")

		return 0
	}

	definition := state.CheckTable(1)
	name := requiredString(state, definition, "id")
	callback, ok := state.GetField(definition, "run").(*lua.LFunction)

	if !ok {
		state.RaiseError("policy %s run must be a function", name)

		return 0
	}

	if _, found := r.policies[name]; found {
		state.RaiseError("duplicate Lua policy %s", name)

		return 0
	}

	r.policies[name] = callback

	return 0
}

func (r *Runtime) Policy(name string, input map[string]any) (map[string]any, error) {
	callback, found := r.policies[name]

	if !found {
		return nil, fmt.Errorf("Lua policy %s is missing", name)
	}

	argument, err := r.policyTable(input)

	if err != nil {
		return nil, fmt.Errorf("Lua policy %s input: %w", name, err)
	}

	callbackContext, cancel := context.WithTimeout(
		context.Background(),
		2*time.Second,
	)
	r.state.SetContext(callbackContext)

	err = r.state.CallByParam(lua.P{
		Fn:      callback,
		NRet:    1,
		Protect: true,
	}, r.context, argument)

	r.state.RemoveContext()
	cancel()

	if err != nil {
		r.DiscardPending()

		return nil, fmt.Errorf("Lua policy %s: %w", name, err)
	}

	result := r.state.Get(-1)
	r.state.Pop(1)
	table, ok := result.(*lua.LTable)

	if !ok {
		r.DiscardPending()

		return nil, fmt.Errorf("Lua policy %s must return a table", name)
	}

	output, err := policyValues(table)

	if err != nil {
		r.DiscardPending()

		return nil, fmt.Errorf("Lua policy %s output: %w", name, err)
	}

	return output, nil
}

func (r *Runtime) policyTable(values map[string]any) (*lua.LTable, error) {
	table := r.state.NewTable()

	for name, value := range values {
		converted, err := r.policyValue(value)

		if err != nil {
			return nil, fmt.Errorf("%s: %w", name, err)
		}

		r.state.SetField(table, name, converted)
	}

	return table, nil
}

func (r *Runtime) policyValue(value any) (lua.LValue, error) {
	switch typed := value.(type) {
	case nil:
		return lua.LNil, nil

	case int:
		return r.policyValue(int64(typed))

	case int64, uint64, bool, string, akara.Entity:
		return r.luaFieldValue(typed)

	case map[string]any:
		return r.policyTable(typed)

	case []any:
		table := r.state.NewTable()

		for index, entry := range typed {
			converted, err := r.policyValue(entry)

			if err != nil {
				return nil, fmt.Errorf("entry %d: %w", index+1, err)
			}

			table.Append(converted)
		}

		return table, nil

	case []string:
		entries := make([]any, len(typed))

		for index, entry := range typed {
			entries[index] = entry
		}

		return r.policyValue(entries)

	default:
		return nil, fmt.Errorf("unsupported policy value %T", value)
	}
}

func policyValues(table *lua.LTable) (map[string]any, error) {
	result := make(map[string]any)
	var conversionErr error

	table.ForEach(func(key, value lua.LValue) {
		if conversionErr != nil {
			return
		}

		name, ok := key.(lua.LString)

		if !ok {
			conversionErr = fmt.Errorf("policy result field name must be a string")

			return
		}

		converted, err := policyResultValue(value)

		if err != nil {
			conversionErr = fmt.Errorf("field %s: %w", name, err)

			return
		}

		result[string(name)] = converted
	})

	return result, conversionErr
}

func policyResultValue(value lua.LValue) (any, error) {
	switch typed := value.(type) {
	case lua.LBool:
		return bool(typed), nil

	case lua.LString:
		return string(typed), nil

	case lua.LNumber:
		if math.IsNaN(float64(typed)) || math.IsInf(float64(typed), 0) {
			return nil, fmt.Errorf("non-finite number")
		}

		if math.Trunc(float64(typed)) == float64(typed) &&
			math.Abs(float64(typed)) <= maxExactLuaInteger {
			return int64(typed), nil
		}

		return float64(typed), nil

	case *lua.LUserData:
		entity, ok := typed.Value.(akara.Entity)

		if !ok {
			return nil, fmt.Errorf("unknown userdata")
		}

		return entity, nil

	case *lua.LTable:
		if typed.Len() > 0 {
			entries := make([]any, typed.Len())
			var conversionErr error
			count := 0

			typed.ForEach(func(key, value lua.LValue) {
				if conversionErr != nil {
					return
				}

				index, ok := key.(lua.LNumber)

				if !ok ||
					index < 1 ||
					int(index) > len(entries) ||
					float64(index) != math.Trunc(float64(index)) {
					conversionErr = fmt.Errorf("list has a non-index key")

					return
				}

				converted, err := policyResultValue(value)

				if err != nil {
					conversionErr = err

					return
				}

				entries[int(index)-1] = converted
				count++
			})

			if conversionErr != nil {
				return nil, conversionErr
			}

			if count != len(entries) {
				return nil, fmt.Errorf("list has missing entries")
			}

			return entries, nil
		}

		return policyValues(typed)

	default:
		return nil, fmt.Errorf("unsupported result %s", value.Type())
	}
}
