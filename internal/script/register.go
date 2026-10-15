package script

import (
	"fmt"
	"math"
	"slices"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

func (r *Runtime) installRegistrationAPI() {
	register := r.state.NewTable()

	r.state.SetField(register, "component", r.state.NewFunction(r.luaRegisterComponent))
	r.state.SetField(register, "system", r.state.NewFunction(r.luaRegisterSystem))
	r.state.SetField(register, "definition", r.state.NewFunction(r.luaRegisterDefinition))
	r.state.SetField(register, "get", r.state.NewFunction(r.luaRegisteredDefinition))
	r.state.SetField(register, "ids", r.state.NewFunction(r.luaRegisteredIDs))
	r.state.SetField(register, "ordered_ids", r.state.NewFunction(r.luaRegisteredOrderedIDs))
	r.state.SetField(register, "reference", r.state.NewFunction(r.luaRegisteredReference))
	r.state.SetField(register, "validate_references", r.state.NewFunction(r.luaValidateDefinitionReferences))
	r.state.SetField(register, "origin", r.state.NewFunction(r.luaRegisteredOrigin))
	r.state.SetField(register, "choice_policy", r.state.NewFunction(r.luaRegisterChoicePolicy))
	r.state.SetField(register, "policy", r.state.NewFunction(r.luaRegisterPolicy))
	r.state.SetGlobal("register", register)
}

func (r *Runtime) luaRegisterComponent(state *lua.LState) int {
	if r.frozen {
		state.RaiseError("Lua registration is closed")

		return 0
	}

	definition := state.CheckTable(1)
	name := requiredString(state, definition, "id")

	if _, found := r.hostComponents[name]; found {
		state.RaiseError("Lua component %s conflicts with a host component", name)

		return 0
	}

	version := requiredUint32(state, definition, "version")
	fields, ok := state.GetField(definition, "fields").(*lua.LTable)

	if !ok {
		state.RaiseError("component %s fields must be a table", name)

		return 0
	}

	schemaFields, err := parseFields(fields)

	if err != nil {
		state.RaiseError("component %s: %v", name, err)

		return 0
	}

	store, err := akara.RegisterSchema(r.world, akara.Schema{
		Name:    name,
		Version: version,
		Fields:  schemaFields,
	})

	if err != nil {
		state.RaiseError("component %s: %v", name, err)

		return 0
	}

	if _, found := r.components[name]; found {
		state.RaiseError("duplicate Lua component %s", name)

		return 0
	}

	r.components[name] = store

	return 0
}

func (r *Runtime) luaRegisterSystem(state *lua.LState) int {
	if r.frozen {
		state.RaiseError("Lua registration is closed")

		return 0
	}

	definition := state.CheckTable(1)
	name := requiredString(state, definition, "id")
	callback, ok := state.GetField(definition, "update").(*lua.LFunction)

	if !ok {
		state.RaiseError("system %s update must be a function", name)

		return 0
	}

	query, err := stringList(state.GetField(definition, "query"))

	if err != nil {
		state.RaiseError("system %s query: %v", name, err)

		return 0
	}

	after, err := stringList(state.GetField(definition, "after"))

	if err != nil {
		state.RaiseError("system %s after: %v", name, err)

		return 0
	}

	before, err := stringList(state.GetField(definition, "before"))

	if err != nil {
		state.RaiseError("system %s before: %v", name, err)

		return 0
	}

	scope := "all"

	if value := state.GetField(definition, "scope"); value != lua.LNil {
		text, ok := value.(lua.LString)

		if !ok {
			state.RaiseError("system %s scope must be all or active", name)

			return 0
		}

		if text != "all" && text != "active" {
			state.RaiseError("system %s scope must be all or active", name)

			return 0
		}

		scope = string(text)
	}

	for _, existing := range r.systems {
		if existing.Name == name {
			state.RaiseError("duplicate Lua system %s", name)

			return 0
		}
	}

	r.systems = append(r.systems, System{
		Name:   name,
		After:  after,
		Before: before,

		query:    query,
		scope:    scope,
		callback: callback,
		runtime:  r,
	})

	return 0
}

func requiredString(state *lua.LState, table *lua.LTable, field string) string {
	value := state.GetField(table, field)
	stringValue, ok := value.(lua.LString)

	if !ok || stringValue == "" {
		state.RaiseError("registration field %s must be a nonempty string", field)

		return ""
	}

	return string(stringValue)
}

func requiredUint32(state *lua.LState, table *lua.LTable, field string) uint32 {
	value := state.GetField(table, field)
	number, ok := value.(lua.LNumber)

	if !ok {
		state.RaiseError("registration field %s must be a positive uint32", field)

		return 0
	}

	if number < 1 || number > math.MaxUint32 {
		state.RaiseError("registration field %s must be a positive uint32", field)

		return 0
	}

	if float64(number) != math.Trunc(float64(number)) {
		state.RaiseError("registration field %s must be a positive uint32", field)

		return 0
	}

	return uint32(number)
}

func parseFields(table *lua.LTable) ([]akara.Field, error) {
	byName := make(map[string]akara.Field)
	var parseErr error

	table.ForEach(func(key, value lua.LValue) {
		if parseErr != nil {
			return
		}

		name, ok := key.(lua.LString)

		if !ok || name == "" {
			parseErr = fmt.Errorf("field name must be a nonempty string")

			return
		}

		options, ok := value.(*lua.LTable)

		if !ok {
			parseErr = fmt.Errorf("field %s must be a table", name)

			return
		}

		kindName, ok := options.RawGetString("type").(lua.LString)

		if !ok {
			parseErr = fmt.Errorf("field %s has no type", name)

			return
		}

		kind, err := fieldKind(string(kindName))

		if err != nil {
			parseErr = fmt.Errorf("field %s: %w", name, err)

			return
		}

		var defaultValue any
		defaultLua := options.RawGetString("default")

		if defaultLua != lua.LNil {
			defaultValue, err = goFieldValue(kind, defaultLua)

			if err != nil {
				parseErr = fmt.Errorf("field %s default: %w", name, err)

				return
			}
		}

		byName[string(name)] = akara.Field{
			Name:    string(name),
			Kind:    kind,
			Default: defaultValue,
		}
	})

	if parseErr != nil {
		return nil, parseErr
	}

	names := make([]string, 0, len(byName))

	for name := range byName {
		names = append(names, name)
	}

	slices.Sort(names)

	fields := make([]akara.Field, 0, len(names))

	for _, name := range names {
		fields = append(fields, byName[name])
	}

	return fields, nil
}

func fieldKind(name string) (akara.FieldKind, error) {
	switch name {
	case "bool":
		return akara.FieldBool, nil

	case "int64":
		return akara.FieldInt64, nil

	case "uint64":
		return akara.FieldUint64, nil

	case "float64":
		return akara.FieldFloat64, nil

	case "string":
		return akara.FieldString, nil

	case "entity":
		return akara.FieldEntity, nil

	default:
		return 0, fmt.Errorf("unsupported field type %q", name)
	}
}

func stringList(value lua.LValue) ([]string, error) {
	if value == lua.LNil {
		return nil, nil
	}

	table, ok := value.(*lua.LTable)

	if !ok {
		return nil, fmt.Errorf("must be a list")
	}

	result := make([]string, 0, table.Len())

	for index := 1; index <= table.Len(); index++ {
		item, ok := table.RawGetInt(index).(lua.LString)

		if !ok || item == "" {
			return nil, fmt.Errorf("entry %d must be a nonempty string", index)
		}

		result = append(result, string(item))
	}

	return result, nil
}
