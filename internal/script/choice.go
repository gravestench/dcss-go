package script

import (
	"context"
	"fmt"
	"time"

	lua "github.com/yuin/gopher-lua"
)

// Choice is the menu restriction and current start support returned by Lua.
type Choice struct {
	Restriction string
	Playable    bool
}

func (r *Runtime) luaRegisterChoicePolicy(state *lua.LState) int {
	if r.frozen || r.choicePolicy != nil {
		state.RaiseError("character choice policy is already registered")

		return 0
	}

	r.choicePolicy = state.CheckFunction(1)

	return 0
}

// CharacterChoice asks the effective Lua policy about one species/job pair.
// Copies prevent policy calls from changing registered definitions.
func (r *Runtime) CharacterChoice(
	speciesID, jobID string,
	speciesFirst bool,
) (Choice, error) {
	if r.choicePolicy == nil {
		return Choice{}, fmt.Errorf("Lua character choice policy is missing")
	}

	species, found := r.speciesTables[speciesID]

	if !found {
		return Choice{}, fmt.Errorf("unknown Lua species %s", speciesID)
	}

	job, found := r.jobTables[jobID]

	if !found {
		return Choice{}, fmt.Errorf("unknown Lua job %s", jobID)
	}

	callbackContext, cancel := context.WithTimeout(
		context.Background(),
		2*time.Second,
	)
	r.state.SetContext(callbackContext)

	err := r.state.CallByParam(lua.P{
		Fn:      r.choicePolicy,
		NRet:    2,
		Protect: true,
	}, copyDefinitionTable(r.state, species),
		copyDefinitionTable(r.state, job), lua.LBool(speciesFirst))

	r.state.RemoveContext()
	cancel()

	if err != nil {
		return Choice{}, fmt.Errorf("Lua character choice %s/%s: %w", speciesID, jobID, err)
	}

	restriction, validRestriction := r.state.Get(-2).(lua.LString)
	playable, validPlayable := r.state.Get(-1).(lua.LBool)
	r.state.Pop(2)

	if !validRestriction || !validPlayable {
		return Choice{}, fmt.Errorf("Lua character choice returned invalid types")
	}

	switch restriction {
	case "banned", "restricted", "recommended":

	default:
		return Choice{}, fmt.Errorf("Lua character choice returned %q", restriction)
	}

	if restriction == "banned" && playable {
		return Choice{}, fmt.Errorf("banned Lua character choice is playable")
	}

	return Choice{
		Restriction: string(restriction),
		Playable:    bool(playable),
	}, nil
}

func copyDefinitionTable(state *lua.LState, source *lua.LTable) *lua.LTable {
	copy := state.NewTable()

	source.ForEach(func(key, value lua.LValue) {
		if child, ok := value.(*lua.LTable); ok {
			copy.RawSet(key, copyDefinitionTable(state, child))

			return
		}

		copy.RawSet(key, value)
	})

	return copy
}
