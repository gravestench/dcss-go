// Package script runs the effective Lua ruleset against one Akara world.
package script

import (
	"context"
	"fmt"
	"io/fs"
	"strings"
	"time"

	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/terrain"
	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

const bootstrapTimeout = 5 * time.Second

// Services are the session operations made available to Lua callbacks.
// A nil operation is unavailable to that particular runtime.
type Services struct {
	ActiveActor    func() akara.Entity
	PlayerEntity   func() akara.Entity
	CurrentAut     func() int64
	Random         func(stream string, bound int) (int, error)
	RandomWord     func(stream string) uint64
	Emit           func(kind, text string)
	Grid           Grid
	HostComponents map[string]HostComponent
}

// Grid exposes reusable spatial reads. Game rules decide how to interpret
// terrain features, stair links, occupancy, and walkability.
type Grid interface {
	Cell(levelID, x, y int) (terrain.ID, bool)
	Remembered(levelID, x, y int) (terrain.ID, bool)
	MapCell(levelID, x, y int) error
	RestoreRemembered(levelID, x, y int, feature terrain.ID) error
	Size(levelID int) (int, int, bool)
	Branch(levelID int) (string, bool)
	Walkable(levelID, x, y int) bool
	ActorAt(levelID, x, y int) (akara.Entity, bool)
	StairAt(levelID, x, y int) (Stair, bool)
	Visible(levelID, fromX, fromY, radius, targetX, targetY int) (bool, error)
	VisibleCells(levelID, fromX, fromY, radius int) ([]VisibleCell, error)
	RouteStep(levelID, fromX, fromY, toX, toY int, goal akara.Entity) (int, int, bool)
	ProjectileClear(levelID, fromX, fromY, toX, toY int) bool
	SetCell(levelID, x, y int, feature terrain.ID) error
	MoveActor(entity akara.Entity, levelID, x, y int) error
	MoveActors(moves []ActorMove) error
	PlaceActor(entity akara.Entity, levelID, x, y int) error
	RemoveActor(entity akara.Entity, levelID int) error
}

// VisibleCell is one grid coordinate in a line-of-sight result.
type VisibleCell struct {
	X int
	Y int
}

// ActorMove is one destination in an atomic simultaneous grid movement.
type ActorMove struct {
	Actor   akara.Entity
	LevelID int
	X       int
	Y       int
}

type gridCell struct {
	levelID int
	x       int
	y       int
}

type Stair struct {
	ToLevelID   int
	ToX         int
	ToY         int
	Unavailable string
}

// Runtime owns one Lua VM and its Akara registrations for one game session.
// The VM is confined to the game's serial update path.
type Runtime struct {
	world    *akara.World
	rules    modfs.Ruleset
	state    *lua.LState
	services Services

	components        map[string]*akara.DynamicStore
	hostComponents    map[string]HostComponent
	definitions       map[string]map[string]*lua.LTable
	definitionOrigins map[string]map[string]string
	definitionOrder   map[string][]string
	definitionRefs    []definitionReference
	definitionsReady  bool
	choicePolicy      *lua.LFunction
	policies          map[string]*lua.LFunction
	systems           []System
	context           *lua.LTable
	handles           map[akara.Entity]*lua.LUserData
	pending           []structuralCommand
	pendingViews      map[componentTarget]*pendingComponent
	pendingDestroy    map[akara.Entity]bool
	pendingCells      map[gridCell]terrain.ID
	pendingActors     map[gridCell]akara.Entity
	pendingPositions  map[akara.Entity]*gridCell
	created           []akara.Entity
	signals           map[string][]lua.LValue
	loaded            map[string]lua.LValue
	loading           map[string]bool
	moduleStack       []string
	frozen            bool
}

// New loads and validates the effective Lua source tree for one world.
func New(
	world *akara.World,
	rules modfs.Ruleset,
	services Services,
) (_ *Runtime, err error) {
	return newRuntime(world, rules, services, true)
}

// NewCatalog loads character definitions for the menu before a game world
// exists. It loads the same effective Lua tree but does not validate or run
// systems that require gameplay components.
func NewCatalog(
	world *akara.World,
	rules modfs.Ruleset,
) (*Runtime, error) {
	return newRuntime(world, rules, Services{}, false)
}

func newRuntime(
	world *akara.World,
	rules modfs.Ruleset,
	services Services,
	validateSystems bool,
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

		components:        make(map[string]*akara.DynamicStore),
		hostComponents:    services.HostComponents,
		definitions:       make(map[string]map[string]*lua.LTable),
		definitionOrigins: make(map[string]map[string]string),
		definitionOrder:   make(map[string][]string),
		policies:          make(map[string]*lua.LFunction),
		loaded:            make(map[string]lua.LValue),
		loading:           make(map[string]bool),
		handles:           make(map[akara.Entity]*lua.LUserData),
		pendingViews:      make(map[componentTarget]*pendingComponent),
		pendingDestroy:    make(map[akara.Entity]bool),
		pendingCells:      make(map[gridCell]terrain.ID),
		pendingActors:     make(map[gridCell]akara.Entity),
		pendingPositions:  make(map[akara.Entity]*gridCell),
		signals:           make(map[string][]lua.LValue),
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

	if validateSystems {
		if err := runtime.validateSystems(); err != nil {
			return nil, err
		}
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
	null := r.state.NewUserData()

	null.Value = definitionNull{}

	r.state.SetField(mod, "load_tree", r.state.NewFunction(r.luaLoadTree))
	r.state.SetField(mod, "paths", r.state.NewFunction(r.luaModPaths))
	r.state.SetField(mod, "read", r.state.NewFunction(r.luaModRead))
	r.state.SetField(mod, "bundled", r.state.NewFunction(r.luaModBundled))
	r.state.SetField(mod, "null", null)
	r.state.SetGlobal("mod", mod)
	r.state.SetGlobal("require", r.state.NewFunction(r.luaRequire))
}

func (r *Runtime) luaModBundled(state *lua.LState) int {
	name := state.CheckString(1)
	data, found := r.rules.BundledFile(name)

	if !found {
		state.Push(lua.LNil)

		return 1
	}

	state.Push(lua.LString(data))

	return 1
}

func (r *Runtime) luaLoadTree(state *lua.LState) int {
	root := state.CheckString(1)

	if !fs.ValidPath(root) || root == "." {
		state.RaiseError("invalid Lua tree %q", root)

		return 0
	}

	prefix := root + "/"

	for _, name := range r.rules.Paths() {
		if !strings.HasPrefix(name, prefix) ||
			!strings.HasSuffix(name, ".lua") {
			continue
		}

		if _, err := r.runModule(name); err != nil {
			state.RaiseError("load %s: %v", name, err)

			return 0
		}
	}

	return 0
}

func (r *Runtime) luaModPaths(state *lua.LState) int {
	root := state.CheckString(1)
	suffix := state.CheckString(2)

	if !fs.ValidPath(root) ||
		root == "." ||
		(suffix != ".lua" && suffix != ".des") {
		state.RaiseError("invalid rule path filter %q, %q", root, suffix)

		return 0
	}

	paths := state.NewTable()
	prefix := root + "/"

	for _, name := range r.rules.Paths() {
		if strings.HasPrefix(name, prefix) &&
			strings.HasSuffix(name, suffix) {
			paths.Append(lua.LString(name))
		}
	}

	state.Push(paths)

	return 1
}

func (r *Runtime) luaModRead(state *lua.LState) int {
	name := state.CheckString(1)
	data, err := r.rules.ReadFile(name)

	if err != nil {
		state.RaiseError("read rule %q: %v", name, err)

		return 0
	}

	state.Push(lua.LString(data))

	return 1
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
	r.moduleStack = append(r.moduleStack, name)

	defer func() {
		delete(r.loading, name)
		r.moduleStack = r.moduleStack[:len(r.moduleStack)-1]
	}()

	proto, err := compiledPrototype(r.state, name, data)

	if err != nil {
		return nil, fmt.Errorf("compile Lua module %s: %w", name, err)
	}

	chunk := r.state.NewFunctionFromProto(proto)

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
