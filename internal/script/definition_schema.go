package script

import (
	"fmt"
	"reflect"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

// The JSON tags on projection types specify which Lua fields must exist.
// mod.null is valid for a nil slice or map, not for a scalar.
func requiredDefinitionFields(table *lua.LTable, target any) error {
	definition := reflect.TypeOf(target).Elem()

	return checkRequiredValue(table, definition, "definition")
}

func checkRequiredValue(value lua.LValue, kind reflect.Type, path string) error {
	if userData, ok := value.(*lua.LUserData); ok {
		if _, isNull := userData.Value.(definitionNull); isNull {
			if kind.Kind() == reflect.Slice || kind.Kind() == reflect.Map {
				return nil
			}

			return fmt.Errorf("%s cannot be null", path)
		}
	}

	switch kind.Kind() {
	case reflect.Struct:
		return checkRequiredStruct(value, kind, path)

	case reflect.Slice, reflect.Map:
		table, ok := value.(*lua.LTable)

		if !ok {
			return fmt.Errorf("%s must be a table", path)
		}

		var fieldErr error

		table.ForEach(func(key, child lua.LValue) {
			if fieldErr != nil {
				return
			}

			fieldErr = checkRequiredValue(
				child,
				kind.Elem(),
				fmt.Sprintf("%s[%s]", path, key.String()),
			)
		})

		return fieldErr

	default:
		return nil
	}
}

func checkRequiredStruct(value lua.LValue, kind reflect.Type, path string) error {
	table, ok := value.(*lua.LTable)

	if !ok {
		return fmt.Errorf("%s must be a table", path)
	}

	for index := range kind.NumField() {
		field := kind.Field(index)
		tag := field.Tag.Get("json")
		name, options, _ := strings.Cut(tag, ",")

		if name == "" || name == "-" {
			continue
		}

		child := table.RawGetString(name)
		fieldPath := path + "." + name

		if child == lua.LNil {
			if strings.Contains(options, "omitempty") {
				continue
			}

			return fmt.Errorf("missing required field %s", fieldPath)
		}

		if err := checkRequiredValue(child, field.Type, fieldPath); err != nil {
			return err
		}
	}

	return nil
}
