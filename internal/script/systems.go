package script

import (
	"context"
	"fmt"
	"time"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

const callbackTimeout = 2 * time.Second

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
	for _, name := range names {
		if !r.components[name].Has(entity) {
			return false
		}
	}

	return true
}

func (r *Runtime) queryEntities(names []string) []akara.Entity {
	if len(names) == 0 {
		return r.world.Entities()
	}

	first := r.components[names[0]]
	entities := first.Entities()
	matched := make([]akara.Entity, 0, len(entities))

	for _, entity := range entities {
		all := true

		for _, name := range names[1:] {
			if !r.components[name].Has(entity) {
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
			if _, found := r.components[component]; !found {
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
		r.pending = akara.NewCommandBuffer()
		r.pendingTargets = nil
	}
}

// ApplyPending commits Lua structural changes after Akara finishes an update.
func (r *Runtime) ApplyPending() error {
	if r == nil {
		return nil
	}

	for _, entity := range r.pendingTargets {
		if !r.world.EntityExists(entity) {
			r.DiscardPending()

			return fmt.Errorf("Lua component command targets missing entity %d", entity)
		}
	}

	pending := r.pending

	r.pending = akara.NewCommandBuffer()
	r.pendingTargets = nil

	return pending.Apply()
}
