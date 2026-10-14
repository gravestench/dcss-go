package script

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"slices"

	"dcrawl-go/internal/content"
	lua "github.com/yuin/gopher-lua"
)

// mod.null keeps a present JSON null distinct from an omitted Lua field.
type definitionNull struct{}

// The Lua files are the authority. These typed values are projections for
// existing engine readers while their rule domains migrate to Lua.
func (r *Runtime) SpeciesDefinitions() []content.SpeciesDef {
	ids := make([]string, 0, len(r.species))

	for id := range r.species {
		ids = append(ids, id)
	}

	slices.Sort(ids)

	definitions := make([]content.SpeciesDef, 0, len(ids))

	for _, id := range ids {
		definitions = append(definitions, r.species[id])
	}

	return definitions
}

func (r *Runtime) JobDefinitions() []content.JobDef {
	ids := make([]string, 0, len(r.jobs))

	for id := range r.jobs {
		ids = append(ids, id)
	}

	slices.Sort(ids)

	definitions := make([]content.JobDef, 0, len(ids))

	for _, id := range ids {
		definitions = append(definitions, r.jobs[id])
	}

	return definitions
}

func (r *Runtime) luaRegisterSpecies(state *lua.LState) int {
	if r.frozen {
		state.RaiseError("Lua registration is closed")

		return 0
	}

	table := state.CheckTable(1)
	id := requiredString(state, table, "id")

	if _, found := r.species[id]; found {
		state.RaiseError("duplicate species %s", id)

		return 0
	}

	var definition content.SpeciesDef

	if err := requiredDefinitionFields(table, &definition); err != nil {
		state.RaiseError("species %s in %s: %v", id, r.currentModule(), err)

		return 0
	}

	if err := decodeDefinition(table, &definition); err != nil {
		state.RaiseError("species %s in %s: %v", id, r.currentModule(), err)

		return 0
	}

	if err := definition.Validate(); err != nil {
		state.RaiseError("species %s in %s: %v", id, r.currentModule(), err)

		return 0
	}

	if definition.ID != id {
		state.RaiseError("species registration ID changed during decode")

		return 0
	}

	r.species[id] = definition
	r.speciesTables[id] = copyDefinitionTable(state, table)
	r.definitions["species"][id] = r.speciesTables[id]

	return 0
}

func (r *Runtime) luaRegisterJob(state *lua.LState) int {
	if r.frozen {
		state.RaiseError("Lua registration is closed")

		return 0
	}

	table := state.CheckTable(1)
	id := requiredString(state, table, "id")

	if _, found := r.jobs[id]; found {
		state.RaiseError("duplicate job %s", id)

		return 0
	}

	var definition content.JobDef

	if err := requiredDefinitionFields(table, &definition); err != nil {
		state.RaiseError("job %s in %s: %v", id, r.currentModule(), err)

		return 0
	}

	if err := decodeDefinition(table, &definition); err != nil {
		state.RaiseError("job %s in %s: %v", id, r.currentModule(), err)

		return 0
	}

	if err := definition.Validate(); err != nil {
		state.RaiseError("job %s in %s: %v", id, r.currentModule(), err)

		return 0
	}

	if definition.ID != id {
		state.RaiseError("job registration ID changed during decode")

		return 0
	}

	r.jobs[id] = definition
	r.jobTables[id] = copyDefinitionTable(state, table)
	r.definitions["jobs"][id] = r.jobTables[id]

	return 0
}

// Lua policy reads the same registered definitions used by the character
// menu, so a same-path mod override cannot split menu and gameplay rules.
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

func decodeDefinition(table *lua.LTable, target any) error {
	value, err := luaDefinitionValue(table, make(map[*lua.LTable]bool))

	if err != nil {
		return err
	}

	data, err := json.Marshal(value)

	if err != nil {
		return err
	}

	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()

	if err := decoder.Decode(target); err != nil {
		return err
	}

	var trailing any

	if err := decoder.Decode(&trailing); err != io.EOF {
		return fmt.Errorf("definition has trailing JSON data")
	}

	return nil
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
