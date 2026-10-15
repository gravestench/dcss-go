package script

import (
	"fmt"
	"math"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

const maxExactLuaInteger = 1 << 53

func goFieldValue(kind akara.FieldKind, value lua.LValue) (any, error) {
	if value == lua.LNil {
		return nil, nil
	}

	switch kind {
	case akara.FieldBool:
		result, ok := value.(lua.LBool)

		if !ok {
			return nil, fmt.Errorf("expected bool")
		}

		return bool(result), nil

	case akara.FieldInt64:
		number, err := exactLuaNumber(value)

		if err != nil {
			return nil, err
		}

		return int64(number), nil

	case akara.FieldUint64:
		number, err := exactLuaNumber(value)

		if err != nil {
			return nil, err
		}

		if number < 0 {
			return nil, fmt.Errorf("expected nonnegative exact integer")
		}

		return uint64(number), nil

	case akara.FieldFloat64:
		number, ok := value.(lua.LNumber)

		if !ok {
			return nil, fmt.Errorf("expected finite number")
		}

		if math.IsNaN(float64(number)) || math.IsInf(float64(number), 0) {
			return nil, fmt.Errorf("expected finite number")
		}

		return float64(number), nil

	case akara.FieldString:
		result, ok := value.(lua.LString)

		if !ok {
			return nil, fmt.Errorf("expected string")
		}

		return string(result), nil

	case akara.FieldEntity:
		handle, ok := value.(*lua.LUserData)

		if !ok {
			return nil, fmt.Errorf("expected entity handle")
		}

		entity, ok := handle.Value.(akara.Entity)

		if !ok {
			return nil, fmt.Errorf("expected entity handle")
		}

		return entity, nil

	default:
		return nil, fmt.Errorf("unsupported Akara field type %d", kind)
	}
}

func goComponentFieldValue(field akara.Field, value lua.LValue) (any, error) {
	if field.Kind != akara.FieldList && field.Kind != akara.FieldMap {
		return goFieldValue(field.Kind, value)
	}

	if value == lua.LNil {
		return nil, nil
	}

	table, ok := value.(*lua.LTable)

	if !ok {
		return nil, fmt.Errorf("expected table for collection")
	}

	if field.Kind == akara.FieldList {
		length := table.Len()
		count := 0
		valid := true

		table.ForEach(func(key, _ lua.LValue) {
			count++

			number, ok := key.(lua.LNumber)

			if !ok ||
				number < 1 ||
				number > lua.LNumber(length) ||
				math.Trunc(float64(number)) != float64(number) {
				valid = false
			}
		})

		if !valid || count != length {
			return nil, fmt.Errorf("expected dense list with integer keys from 1")
		}

		entries := make([]any, length)

		for index := 1; index <= length; index++ {
			entry, err := goFieldValue(field.ElementKind, table.RawGetInt(index))

			if err != nil {
				return nil, fmt.Errorf("entry %d: %w", index, err)
			}

			entries[index-1] = entry
		}

		return entries, nil
	}

	entries := make(map[string]any)
	var conversionErr error

	table.ForEach(func(key, value lua.LValue) {
		if conversionErr != nil {
			return
		}

		name, ok := key.(lua.LString)

		if !ok {
			conversionErr = fmt.Errorf("expected string map key")

			return
		}

		entry, err := goFieldValue(field.ElementKind, value)

		if err != nil {
			conversionErr = fmt.Errorf("key %s: %w", name, err)

			return
		}

		entries[string(name)] = entry
	})

	return entries, conversionErr
}

func exactLuaNumber(value lua.LValue) (float64, error) {
	number, ok := value.(lua.LNumber)

	if !ok {
		return 0, fmt.Errorf("expected integer within Lua's exact numeric range")
	}

	if math.IsNaN(float64(number)) ||
		math.IsInf(float64(number), 0) ||
		math.Abs(float64(number)) > maxExactLuaInteger ||
		math.Trunc(float64(number)) != float64(number) {
		return 0, fmt.Errorf("expected integer within Lua's exact numeric range")
	}

	return float64(number), nil
}

func (r *Runtime) luaFieldValue(value any) (lua.LValue, error) {
	switch typed := value.(type) {
	case nil:
		return lua.LNil, nil

	case bool:
		return lua.LBool(typed), nil

	case int64:
		if typed > maxExactLuaInteger || typed < -maxExactLuaInteger {
			return lua.LString(fmt.Sprint(typed)), nil
		}

		return lua.LNumber(typed), nil

	case uint64:
		if typed > maxExactLuaInteger {
			return lua.LString(fmt.Sprint(typed)), nil
		}

		return lua.LNumber(typed), nil

	case float64:
		return lua.LNumber(typed), nil

	case string:
		return lua.LString(typed), nil

	case akara.Entity:
		return r.entityHandle(typed), nil

	case []any:
		table := r.state.NewTable()

		for index, entry := range typed {
			converted, err := r.luaFieldValue(entry)

			if err != nil {
				return nil, fmt.Errorf("entry %d: %w", index+1, err)
			}

			table.Append(converted)
		}

		return table, nil

	case map[string]any:
		table := r.state.NewTable()

		for name, entry := range typed {
			converted, err := r.luaFieldValue(entry)

			if err != nil {
				return nil, fmt.Errorf("field %s: %w", name, err)
			}

			r.state.SetField(table, name, converted)
		}

		return table, nil

	default:
		return nil, fmt.Errorf("unsupported component value %T", value)
	}
}

func componentValues(
	schema akara.Schema,
	table *lua.LTable,
) (map[string]any, error) {
	fields := make(map[string]akara.Field, len(schema.Fields))

	for _, field := range schema.Fields {
		fields[field.Name] = field
	}

	values := make(map[string]any)
	var conversionErr error

	table.ForEach(func(key, value lua.LValue) {
		if conversionErr != nil {
			return
		}

		name, ok := key.(lua.LString)

		if !ok {
			conversionErr = fmt.Errorf("component field name must be a string")

			return
		}

		field, found := fields[string(name)]

		if !found {
			conversionErr = fmt.Errorf("unknown component field %q", name)

			return
		}

		converted, err := goComponentFieldValue(field, value)

		if err != nil {
			conversionErr = fmt.Errorf("field %s: %w", name, err)

			return
		}

		fieldName := string(name)

		values[fieldName] = converted
	})

	return values, conversionErr
}

// Pending Lua reads must see the same defaults that Akara applies at commit.
func withDynamicDefaults(store *akara.DynamicStore, values map[string]any) map[string]any {
	if store == nil {
		return values
	}

	for _, field := range store.Schema().Fields {
		if _, supplied := values[field.Name]; !supplied {
			values[field.Name] = field.Default
		}
	}

	return values
}
