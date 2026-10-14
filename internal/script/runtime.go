// Package script runs the effective Lua ruleset against one Akara world.
package script

import (
	"context"
	"fmt"
	"io/fs"
	"strings"
	"time"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

const bootstrapTimeout = 5 * time.Second

// Services are the session operations made available to Lua callbacks.
// A nil operation is unavailable to that particular runtime.
type Services struct {
	ActiveActor func() akara.Entity
	Random      func(stream string, bound int) (int, error)
	Emit        func(kind, text string)
}

// Runtime owns one Lua VM and its Akara registrations for one game session.
// The VM is confined to the game's serial update path.
type Runtime struct {
	world    *akara.World
	rules    modfs.Ruleset
	state    *lua.LState
	services Services

	components     map[string]*akara.DynamicStore
	systems        []System
	context        *lua.LTable
	handles        map[akara.Entity]*lua.LUserData
	pending        *akara.CommandBuffer
	pendingTargets []akara.Entity
	loaded         map[string]lua.LValue
	loading        map[string]bool
	frozen         bool
}

// New loads and validates the effective Lua source tree for one world.
func New(
	world *akara.World,
	rules modfs.Ruleset,
	services Services,
) (_ *Runtime, err error) {
	if world == nil {
		return nil, fmt.Errorf("Lua runtime has no Akara world")
	}

	state := lua.NewState(lua.Options{SkipOpenLibs: true})

	runtime := &Runtime{
		world:    world,
		rules:    rules,
		state:    state,
		services: services,

		components: make(map[string]*akara.DynamicStore),
		loaded:     make(map[string]lua.LValue),
		loading:    make(map[string]bool),
		handles:    make(map[akara.Entity]*lua.LUserData),
		pending:    akara.NewCommandBuffer(),
	}

	defer func() {
		if err != nil {
			state.Close()
		}
	}()

	runtime.openLibraries()
	runtime.installModuleAPI()
	runtime.installRegistrationAPI()
	runtime.installContextAPI()

	bootstrapContext, cancel := context.WithTimeout(
		context.Background(),
		bootstrapTimeout,
	)
	runtime.state.SetContext(bootstrapContext)

	_, err = runtime.runModule("init.lua")

	runtime.state.RemoveContext()
	cancel()

	if err != nil {
		return nil, err
	}

	runtime.frozen = true

	if err := runtime.validateSystems(); err != nil {
		return nil, err
	}

	return runtime, nil
}

func (r *Runtime) Close() {
	if r != nil && r.state != nil {
		r.state.Close()
		r.state = nil
	}
}

func (r *Runtime) Components() map[string]*akara.DynamicStore {
	copy := make(map[string]*akara.DynamicStore, len(r.components))

	for name, store := range r.components {
		copy[name] = store
	}

	return copy
}

func (r *Runtime) Systems() []System {
	systems := make([]System, len(r.systems))

	for index, system := range r.systems {
		system.After = append([]string(nil), system.After...)
		system.Before = append([]string(nil), system.Before...)
		system.query = append([]string(nil), system.query...)
		systems[index] = system
	}

	return systems
}

func (r *Runtime) openLibraries() {
	state := r.state

	state.Push(state.NewFunction(lua.OpenBase))
	state.Push(lua.LString(lua.BaseLibName))
	state.Call(1, 0)

	state.Push(state.NewFunction(lua.OpenTable))
	state.Push(lua.LString(lua.TabLibName))
	state.Call(1, 0)

	state.Push(state.NewFunction(lua.OpenString))
	state.Push(lua.LString(lua.StringLibName))
	state.Call(1, 0)

	state.Push(state.NewFunction(lua.OpenMath))
	state.Push(lua.LString(lua.MathLibName))
	state.Call(1, 0)

	state.SetGlobal("dofile", lua.LNil)
	state.SetGlobal("loadfile", lua.LNil)

	math := state.GetGlobal("math")

	if table, ok := math.(*lua.LTable); ok {
		state.SetField(table, "random", lua.LNil)
		state.SetField(table, "randomseed", lua.LNil)
	}
}

func (r *Runtime) installModuleAPI() {
	mod := r.state.NewTable()

	r.state.SetField(mod, "load_tree", r.state.NewFunction(r.luaLoadTree))
	r.state.SetGlobal("mod", mod)
	r.state.SetGlobal("require", r.state.NewFunction(r.luaRequire))
}

func (r *Runtime) luaLoadTree(state *lua.LState) int {
	root := state.CheckString(1)

	if !fs.ValidPath(root) || root == "." {
		state.RaiseError("invalid Lua tree %q", root)

		return 0
	}

	prefix := root + "/"

	for _, name := range r.rules.Paths() {
		if !strings.HasPrefix(name, prefix) {
			continue
		}

		if _, err := r.runModule(name); err != nil {
			state.RaiseError("load %s: %v", name, err)

			return 0
		}
	}

	return 0
}

func (r *Runtime) luaRequire(state *lua.LState) int {
	module := state.CheckString(1)
	name := strings.ReplaceAll(module, ".", "/") + ".lua"

	if !fs.ValidPath(name) {
		state.RaiseError("invalid module %q", module)

		return 0
	}

	value, err := r.runModule(name)

	if err != nil {
		state.RaiseError("require %s: %v", module, err)

		return 0
	}

	state.Push(value)

	return 1
}

func (r *Runtime) runModule(name string) (lua.LValue, error) {
	if value, found := r.loaded[name]; found {
		return value, nil
	}

	if r.loading[name] {
		return nil, fmt.Errorf("cyclic Lua module load at %s", name)
	}

	data, err := r.rules.ReadFile(name)

	if err != nil {
		return nil, fmt.Errorf("Lua module %s: %w", name, err)
	}

	r.loading[name] = true

	defer delete(r.loading, name)

	chunk, err := r.state.Load(strings.NewReader(string(data)), name)

	if err != nil {
		return nil, fmt.Errorf("compile Lua module %s: %w", name, err)
	}

	if err := r.state.CallByParam(lua.P{
		Fn:      chunk,
		NRet:    1,
		Protect: true,
	}); err != nil {
		return nil, fmt.Errorf("run Lua module %s: %w", name, err)
	}

	value := r.state.Get(-1)
	r.state.Pop(1)

	if value == lua.LNil {
		value = lua.LTrue
	}

	r.loaded[name] = value

	return value, nil
}
