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
	case bool:
		return lua.LBool(typed), nil

	case int64:
		if typed > maxExactLuaInteger || typed < -maxExactLuaInteger {
			return nil, fmt.Errorf("int64 exceeds Lua's exact numeric range")
		}

		return lua.LNumber(typed), nil

	case uint64:
		if typed > maxExactLuaInteger {
			return nil, fmt.Errorf("uint64 exceeds Lua's exact numeric range")
		}

		return lua.LNumber(typed), nil

	case float64:
		return lua.LNumber(typed), nil

	case string:
		return lua.LString(typed), nil

	case akara.Entity:
		return r.entityHandle(typed), nil

	default:
		return nil, fmt.Errorf("unsupported component value %T", value)
	}
}

func componentValues(
	schema akara.Schema,
	table *lua.LTable,
) (map[string]any, error) {
	fields := make(map[string]akara.FieldKind, len(schema.Fields))

	for _, field := range schema.Fields {
		fields[field.Name] = field.Kind
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

		kind, found := fields[string(name)]

		if !found {
			conversionErr = fmt.Errorf("unknown component field %q", name)

			return
		}

		converted, err := goFieldValue(kind, value)

		if err != nil {
			conversionErr = fmt.Errorf("field %s: %w", name, err)

			return
		}

		fieldName := string(name)

		values[fieldName] = converted
	})

	return values, conversionErr
}
