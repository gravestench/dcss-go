package script

import (
	"context"
	"fmt"
	"slices"
	"time"

	"crawl/internal/terrain"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

// A combat system can trigger a full Abyss arrival through distortion.
// Its authored DES selection needs more time than a simple turn effect,
// while a stuck Lua callback still has a finite deadline.
const callbackTimeout = 8 * time.Second

type structuralCommand struct {
	entity  akara.Entity
	apply   func() error
	undo    func() error
	destroy bool
	// spatialLevel marks commands whose read or write depends on a level's
	// current grid. Region replacement may follow unrelated ECS commands.
	spatialLevel int
}

type componentTarget struct {
	entity akara.Entity
	name   string
}

type pendingComponent struct {
	present bool
	values  map[string]any
}

// BeginAction clears transient facts before the next actor enters the
// ordered system chain. Lua rules can share signals within one action.
func (r *Runtime) BeginAction() {
	r.DiscardPending()
	r.signals = make(map[string][]lua.LValue)
}

// System is a Lua callback with stable ordering constraints. Game composes
// these descriptors with its remaining Go systems before Akara registration.
type System struct {
	Name   string
	After  []string
	Before []string

	query    []string
	scope    string
	callback *lua.LFunction
	runtime  *Runtime
}

func (s System) Update(_ *akara.World, delta time.Duration) error {
	runtime := s.runtime
	entities := runtime.queryEntities(s.query)

	if s.scope == "active" {
		if runtime.services.ActiveActor == nil {
			return fmt.Errorf("Lua system %s has no active actor service", s.Name)
		}

		active := runtime.services.ActiveActor()
		entities = nil

		if active != 0 && runtime.entityMatches(active, s.query) {
			entities = []akara.Entity{active}
		}
	}

	for _, entity := range entities {
		args := []lua.LValue{
			runtime.context,
			runtime.entityHandle(entity),
			lua.LNumber(delta),
		}

		callbackContext, cancel := context.WithTimeout(
			context.Background(),
			callbackTimeout,
		)
		runtime.state.SetContext(callbackContext)

		err := runtime.state.CallByParam(lua.P{
			Fn:      s.callback,
			NRet:    0,
			Protect: true,
		}, args...)

		runtime.state.RemoveContext()
		cancel()

		if err != nil {
			runtime.DiscardPending()

			return fmt.Errorf("Lua system %s entity %d: %w", s.Name, entity, err)
		}
	}

	return nil
}

func (r *Runtime) entityMatches(entity akara.Entity, names []string) bool {
	if r.pendingDestroy[entity] {
		return false
	}

	for _, name := range names {
		if !r.componentHas(name, entity) {
			return false
		}
	}

	return true
}

func (r *Runtime) queryEntities(names []string) []akara.Entity {
	if len(names) == 0 {
		entities := r.world.Entities()
		matched := make([]akara.Entity, 0, len(entities))

		for _, entity := range entities {
			if !r.pendingDestroy[entity] {
				matched = append(matched, entity)
			}
		}

		return matched
	}

	entities := append([]akara.Entity(nil), r.componentEntities(names[0])...)
	seen := make(map[akara.Entity]bool, len(entities))

	for _, entity := range entities {
		seen[entity] = true
	}

	for target, view := range r.pendingViews {
		if target.name == names[0] &&
			view.present &&
			!seen[target.entity] {
			entities = append(entities, target.entity)
			seen[target.entity] = true
		}
	}

	slices.Sort(entities)
	matched := make([]akara.Entity, 0, len(entities))

	for _, entity := range entities {
		all := r.componentHas(names[0], entity)

		for _, name := range names[1:] {
			if !r.componentHas(name, entity) {
				all = false

				break
			}
		}

		if all {
			matched = append(matched, entity)
		}
	}

	return matched
}

func (r *Runtime) validateSystems() error {
	names := make(map[string]bool, len(r.systems))

	for _, system := range r.systems {
		names[system.Name] = true

		for _, component := range system.query {
			_, dynamic := r.components[component]
			_, host := r.hostComponents[component]

			if !dynamic && !host {
				return fmt.Errorf("Lua system %s queries unknown component %s", system.Name, component)
			}
		}
	}

	// External Go system names are validated when game composes the full order.
	graph := make(map[string][]string, len(r.systems))

	for _, system := range r.systems {
		for _, after := range system.After {
			if names[after] {
				graph[after] = append(graph[after], system.Name)
			}
		}

		for _, before := range system.Before {
			if names[before] {
				graph[system.Name] = append(graph[system.Name], before)
			}
		}
	}

	visited := make(map[string]uint8, len(r.systems))

	var visit func(string) error

	visit = func(name string) error {
		if visited[name] == 1 {
			return fmt.Errorf("cycle in Lua system order at %s", name)
		}

		if visited[name] == 2 {
			return nil
		}

		visited[name] = 1

		for _, next := range graph[name] {
			if err := visit(next); err != nil {
				return err
			}
		}

		const complete = 2
		visited[name] = complete

		return nil
	}

	for name := range names {
		if err := visit(name); err != nil {
			return err
		}
	}

	return nil
}

func (r *Runtime) entityHandle(entity akara.Entity) *lua.LUserData {
	if handle, found := r.handles[entity]; found {
		return handle
	}

	handle := r.state.NewUserData()

	handle.Value = entity

	r.handles[entity] = handle

	return handle
}

// DiscardPending forgets structural changes from a failed update.
func (r *Runtime) DiscardPending() {
	if r != nil {
		if r.randomDrawn && r.services.RestoreRandom != nil {
			r.services.RestoreRandom(r.randomCheckpoint)
		}

		r.randomCheckpoint = nil
		r.randomDrawn = false

		for _, entity := range r.created {
			r.world.DestroyEntity(entity)
		}

		r.created = nil
		r.pending = nil
		r.pendingViews = make(map[componentTarget]*pendingComponent)
		r.pendingDestroy = make(map[akara.Entity]bool)
		r.pendingCells = make(map[gridCell]terrain.ID)
		r.pendingActors = make(map[gridCell][]akara.Entity)
		r.pendingPositions = make(map[akara.Entity]*gridCell)
		r.pendingSession = make(map[string]map[string]any)
		r.pendingRegions = make(map[int]RegionChange)
	}
}

// ApplyPending commits Lua structural changes after Akara finishes an update.
func (r *Runtime) ApplyPending() error {
	if r == nil {
		return nil
	}

	for _, command := range r.pending {
		if command.entity != 0 && !r.world.EntityExists(command.entity) {
			r.DiscardPending()

			return fmt.Errorf("Lua component command targets missing entity %d", command.entity)
		}
	}

	var applied []structuralCommand
	var destroys []structuralCommand

	for index, command := range r.pending {
		if command.destroy {
			destroys = append(destroys, command)

			continue
		}

		if err := command.apply(); err != nil {
			var rollbackErr error

			for rollback := len(applied) - 1; rollback >= 0; rollback-- {
				if applied[rollback].undo == nil {
					continue
				}

				if undoErr := applied[rollback].undo(); undoErr != nil {
					rollbackErr = undoErr
				}
			}

			r.DiscardPending()

			if rollbackErr != nil {
				return fmt.Errorf(
					"Lua structural command %d: %w; rollback: %v",
					index, err, rollbackErr,
				)
			}

			return fmt.Errorf("Lua structural command %d: %w", index, err)
		}

		applied = append(applied, command)
	}

	for _, command := range destroys {
		if err := command.apply(); err != nil {
			return fmt.Errorf("Lua destroy command: %w", err)
		}
	}

	r.pending = nil
	r.created = nil
	r.pendingViews = make(map[componentTarget]*pendingComponent)
	r.pendingDestroy = make(map[akara.Entity]bool)
	r.pendingCells = make(map[gridCell]terrain.ID)
	r.pendingActors = make(map[gridCell][]akara.Entity)
	r.pendingPositions = make(map[akara.Entity]*gridCell)
	r.pendingSession = make(map[string]map[string]any)
	r.pendingRegions = make(map[int]RegionChange)
	r.randomCheckpoint = nil
	r.randomDrawn = false

	return nil
}

// The first draw captures every stream. A failed Lua callback can then
// restore streams that did not exist before the callback as well as old ones.
func (r *Runtime) checkpointRandom() {
	if r.randomDrawn || r.services.RandomSnapshot == nil {
		return
	}

	r.randomCheckpoint = r.services.RandomSnapshot()
	r.randomDrawn = true
}
