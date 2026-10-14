package script

import (
	"fmt"
	"reflect"
	"strconv"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

func validateHostType(kind reflect.Type) error {
	if _, err := hostFieldKind(kind); err == nil {
		return nil
	}

	switch kind.Kind() {
	case reflect.Slice:
		return validateHostType(kind.Elem())

	case reflect.Struct:
		for index := range kind.NumField() {
			field := kind.Field(index)

			if !field.IsExported() {
				return fmt.Errorf("nested field %s is private", field.Name)
			}

			if err := validateHostType(field.Type); err != nil {
				return fmt.Errorf("%s: %w", field.Name, err)
			}
		}

		return nil

	default:
		return fmt.Errorf("unsupported field type %s", kind)
	}
}

func snapshotHostValue(value reflect.Value) any {
	if value.Type() == reflect.TypeOf(akara.Entity(0)) {
		return akara.Entity(value.Uint())
	}

	switch value.Kind() {
	case reflect.Int, reflect.Int64:
		return value.Int()

	case reflect.Uint8, reflect.Uint64:
		return value.Uint()

	case reflect.String:
		return value.String()

	case reflect.Bool:
		return value.Bool()

	case reflect.Slice:
		if value.IsNil() {
			return nil
		}

		entries := make([]any, value.Len())

		for index := range entries {
			entries[index] = snapshotHostValue(value.Index(index))
		}

		return entries

	case reflect.Struct:
		fields := make(map[string]any, value.NumField())

		for index := range value.NumField() {
			field := value.Type().Field(index)
			name := snakeCase(field.Name)

			fields[name] = snapshotHostValue(value.Field(index))
		}

		return fields
	}

	panic("validated host type became unsupported")
}

func decodeHostFields(
	table *lua.LTable,
	fieldTypes map[string]reflect.Type,
) (map[string]any, error) {
	values := make(map[string]any)
	var conversionErr error

	table.ForEach(func(key, value lua.LValue) {
		if conversionErr != nil {
			return
		}

		name, ok := key.(lua.LString)

		if !ok {
			conversionErr = fmt.Errorf("host field name must be a string")

			return
		}

		kind, known := fieldTypes[string(name)]

		if !known {
			conversionErr = fmt.Errorf("unknown host field %s", name)

			return
		}

		decoded, err := decodeHostValue(value, kind)

		if err != nil {
			conversionErr = fmt.Errorf("field %s: %w", name, err)

			return
		}

		values[string(name)] = decoded
	})

	return values, conversionErr
}

func decodeHostValue(value lua.LValue, kind reflect.Type) (any, error) {
	if kind == reflect.TypeOf(akara.Entity(0)) {
		return goFieldValue(akara.FieldEntity, value)
	}

	switch kind.Kind() {
	case reflect.Int, reflect.Int64:
		if text, ok := value.(lua.LString); ok {
			parsed, err := strconv.ParseInt(string(text), 10, 64)

			if err != nil {
				return nil, fmt.Errorf("expected integer")
			}

			return parsed, nil
		}

		return goFieldValue(akara.FieldInt64, value)

	case reflect.Uint8, reflect.Uint64:
		if text, ok := value.(lua.LString); ok {
			parsed, err := strconv.ParseUint(string(text), 10, 64)

			if err != nil {
				return nil, fmt.Errorf("expected unsigned integer")
			}

			return parsed, nil
		}

		return goFieldValue(akara.FieldUint64, value)

	case reflect.String:
		return goFieldValue(akara.FieldString, value)

	case reflect.Bool:
		return goFieldValue(akara.FieldBool, value)

	case reflect.Slice:
		table, ok := value.(*lua.LTable)

		if !ok {
			return nil, fmt.Errorf("expected list")
		}

		entries := make([]any, table.Len())

		for index := range entries {
			decoded, err := decodeHostValue(table.RawGetInt(index+1), kind.Elem())

			if err != nil {
				return nil, fmt.Errorf("entry %d: %w", index+1, err)
			}

			entries[index] = decoded
		}

		return entries, nil

	case reflect.Struct:
		table, ok := value.(*lua.LTable)

		if !ok {
			return nil, fmt.Errorf("expected record")
		}

		fields := make(map[string]reflect.Type, kind.NumField())

		for index := range kind.NumField() {
			field := kind.Field(index)
			name := snakeCase(field.Name)

			fields[name] = field.Type
		}

		return decodeHostFields(table, fields)

	default:
		return nil, fmt.Errorf("unsupported host field type %s", kind)
	}
}

func hostReflectValue(value any, kind reflect.Type) (reflect.Value, error) {
	if value == nil {
		if kind.Kind() == reflect.Slice {
			return reflect.Zero(kind), nil
		}

		return reflect.Value{}, fmt.Errorf("missing scalar value")
	}

	if kind == reflect.TypeOf(akara.Entity(0)) {
		entity, ok := value.(akara.Entity)

		if !ok {
			return reflect.Value{}, fmt.Errorf("expected entity handle")
		}

		return reflect.ValueOf(entity), nil
	}

	result := reflect.New(kind).Elem()

	switch kind.Kind() {
	case reflect.Int, reflect.Int64:
		number, ok := value.(int64)

		if !ok || result.OverflowInt(number) {
			return reflect.Value{}, fmt.Errorf("integer outside %s range", kind)
		}

		result.SetInt(number)

	case reflect.Uint8, reflect.Uint64:
		number, ok := value.(uint64)

		if !ok || result.OverflowUint(number) {
			return reflect.Value{}, fmt.Errorf("unsigned integer outside %s range", kind)
		}

		result.SetUint(number)

	case reflect.String:
		text, ok := value.(string)

		if !ok {
			return reflect.Value{}, fmt.Errorf("expected string")
		}

		result.SetString(text)

	case reflect.Bool:
		flag, ok := value.(bool)

		if !ok {
			return reflect.Value{}, fmt.Errorf("expected bool")
		}

		result.SetBool(flag)

	case reflect.Slice:
		entries, ok := value.([]any)

		if !ok {
			return reflect.Value{}, fmt.Errorf("expected list")
		}

		result = reflect.MakeSlice(kind, len(entries), len(entries))

		for index, entry := range entries {
			converted, err := hostReflectValue(entry, kind.Elem())

			if err != nil {
				return reflect.Value{}, fmt.Errorf("entry %d: %w", index+1, err)
			}

			result.Index(index).Set(converted)
		}

	case reflect.Struct:
		fields, ok := value.(map[string]any)

		if !ok {
			return reflect.Value{}, fmt.Errorf("expected record")
		}

		for name, entry := range fields {
			index := -1

			for candidate := range kind.NumField() {
				if snakeCase(kind.Field(candidate).Name) == name {
					index = candidate

					break
				}
			}

			if index < 0 {
				return reflect.Value{}, fmt.Errorf("unknown record field %s", name)
			}

			converted, err := hostReflectValue(entry, kind.Field(index).Type)

			if err != nil {
				return reflect.Value{}, fmt.Errorf("%s: %w", name, err)
			}

			result.Field(index).Set(converted)
		}

	default:
		return reflect.Value{}, fmt.Errorf("unsupported host field type %s", kind)
	}

	return result, nil
}
