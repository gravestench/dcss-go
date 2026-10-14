package script

import (
	"fmt"
	"reflect"
	"strings"
	"unicode"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

// HostComponent exposes one existing typed Akara store to Lua. It reads and
// writes that store directly, so Lua systems and Go engine code share state.
type HostComponent struct {
	Schema   akara.Schema
	Decode   func(*lua.LTable) (map[string]any, error)
	Has      func(akara.Entity) bool
	Entities func() []akara.Entity
	Get      func(akara.Entity) (map[string]any, bool)
	Set      func(akara.Entity, map[string]any) error
	Remove   func(akara.Entity) bool
}

// HostBinding names one typed engine store for the shared Lua component API.
type HostBinding struct {
	name string
	bind func() (HostComponent, error)
}

func Host[T any](name string, store *akara.Store[T]) HostBinding {
	return HostBinding{
		name: name,
		bind: func() (HostComponent, error) {
			return BindHostComponent(name, store)
		},
	}
}

func BindHosts(bindings []HostBinding) (map[string]HostComponent, error) {
	components := make(map[string]HostComponent, len(bindings))

	for _, binding := range bindings {
		if _, found := components[binding.name]; found {
			return nil, fmt.Errorf("duplicate host component %s", binding.name)
		}

		component, err := binding.bind()

		if err != nil {
			return nil, err
		}

		components[binding.name] = component
	}

	return components, nil
}

// BindHostComponent projects exported typed fields, including nested records
// and lists, through one shared schema-aware component interface.
func BindHostComponent[T any](
	name string,
	store *akara.Store[T],
) (HostComponent, error) {
	if store == nil {
		return HostComponent{}, fmt.Errorf("host component %s has no store", name)
	}

	var zero T
	kind := reflect.TypeOf(zero)

	if kind == nil || kind.Kind() != reflect.Struct {
		return HostComponent{}, fmt.Errorf("host component %s must be a struct", name)
	}

	fields := make([]akara.Field, 0, kind.NumField())
	indices := make(map[string]int, kind.NumField())
	fieldTypes := make(map[string]reflect.Type, kind.NumField())

	for index := range kind.NumField() {
		field := kind.Field(index)

		if !field.IsExported() {
			return HostComponent{}, fmt.Errorf("host component %s has private field %s", name, field.Name)
		}

		if err := validateHostType(field.Type); err != nil {
			return HostComponent{}, fmt.Errorf("host component %s.%s: %w", name, field.Name, err)
		}

		fieldName := snakeCase(field.Name)
		fieldKind, scalar := hostFieldKind(field.Type)

		if scalar == nil {
			fields = append(fields, akara.Field{
				Name: fieldName,
				Kind: fieldKind,
			})
		}

		indices[fieldName] = index
		fieldTypes[fieldName] = field.Type
	}

	return HostComponent{
		Schema: akara.Schema{
			Name:    name,
			Version: 1,
			Fields:  fields,
		},
		Decode: func(table *lua.LTable) (map[string]any, error) {
			return decodeHostFields(table, fieldTypes)
		},
		Has:      store.Has,
		Entities: store.Entities,
		Remove:   store.Remove,
		Get: func(entity akara.Entity) (map[string]any, bool) {
			component, found := store.Get(entity)

			if !found {
				return nil, false
			}

			value := reflect.ValueOf(component).Elem()
			result := make(map[string]any, len(indices))

			for fieldName, index := range indices {
				result[fieldName] = snapshotHostValue(value.Field(index))
			}

			return result, true
		},
		Set: func(entity akara.Entity, values map[string]any) error {
			component, found := store.Get(entity)
			updated := zero

			if found {
				updated = *component
			}

			value := reflect.ValueOf(&updated).Elem()

			for fieldName, entry := range values {
				index, known := indices[fieldName]

				if !known {
					return fmt.Errorf("unknown host field %s.%s", name, fieldName)
				}

				field := value.Field(index)
				converted, err := hostReflectValue(entry, field.Type())

				if err != nil {
					return fmt.Errorf("host field %s.%s: %w", name, fieldName, err)
				}

				field.Set(converted)
			}

			if found {
				*component = updated

				return nil
			}

			_, err := store.Set(entity, updated)

			return err
		},
	}, nil
}

func hostFieldKind(kind reflect.Type) (akara.FieldKind, error) {
	if kind == reflect.TypeOf(akara.Entity(0)) {
		return akara.FieldEntity, nil
	}

	switch kind.Kind() {
	case reflect.Int, reflect.Int64:
		return akara.FieldInt64, nil

	case reflect.Uint8:
		return akara.FieldUint64, nil

	case reflect.String:
		return akara.FieldString, nil

	case reflect.Bool:
		return akara.FieldBool, nil

	default:
		return 0, fmt.Errorf("unsupported field type %s", kind)
	}
}

func snakeCase(name string) string {
	var result strings.Builder
	letters := []rune(name)

	for index, letter := range letters {
		previousLower := index > 0 && unicode.IsLower(letters[index-1])
		acronymEnd := index > 0 &&
			index+1 < len(letters) &&
			unicode.IsUpper(letters[index-1]) &&
			unicode.IsLower(letters[index+1])

		if unicode.IsUpper(letter) && (previousLower || acronymEnd) {
			result.WriteByte('_')
		}

		result.WriteRune(unicode.ToLower(letter))
	}

	return result.String()
}
