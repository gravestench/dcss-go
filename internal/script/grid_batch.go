package script

import (
	"fmt"
	"math"

	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

type stagedActorMove struct {
	actor akara.Entity
	old   gridCell
	next  gridCell
}

func batchInteger(table *lua.LTable, name string) (int, error) {
	value, ok := table.RawGetString(name).(lua.LNumber)

	if !ok || math.Trunc(float64(value)) != float64(value) ||
		math.Abs(float64(value)) > maxExactLuaInteger {
		return 0, fmt.Errorf("batch move %s must be an exact integer", name)
	}

	return int(value), nil
}

func (r *Runtime) decodeActorMove(table *lua.LTable) (stagedActorMove, error) {
	handle, ok := table.RawGetString("actor").(*lua.LUserData)

	if !ok {
		return stagedActorMove{}, fmt.Errorf("batch move actor must be an entity")
	}

	actor, ok := handle.Value.(akara.Entity)

	if !ok || !r.world.EntityExists(actor) || r.pendingDestroy[actor] {
		return stagedActorMove{}, fmt.Errorf("batch move actor is not live")
	}

	levelID, err := batchInteger(table, "level_id")

	if err != nil {
		return stagedActorMove{}, err
	}

	x, err := batchInteger(table, "x")

	if err != nil {
		return stagedActorMove{}, err
	}

	y, err := batchInteger(table, "y")

	if err != nil {
		return stagedActorMove{}, err
	}

	old, positioned, err := r.stagedPosition(actor)

	if err != nil {
		return stagedActorMove{}, fmt.Errorf("batch move actor %d position: %w", actor, err)
	}

	if !positioned {
		return stagedActorMove{}, fmt.Errorf("batch move actor %d has no position", actor)
	}

	indexed, found := r.stagedActorAt(old)

	if !found || indexed != actor {
		return stagedActorMove{}, fmt.Errorf("batch move actor %d is not indexed", actor)
	}

	return stagedActorMove{
		actor: actor,
		old:   old,
		next: gridCell{
			levelID: levelID,
			x:       x,
			y:       y,
		},
	}, nil
}

// luaGridMoveActors validates a permutation before staging any position.
// Destinations may contain only actors moving in this same batch.
func (r *Runtime) luaGridMoveActors(state *lua.LState) int {
	if r.services.Grid == nil {
		state.RaiseError("grid is unavailable")

		return 0
	}

	entries := state.CheckTable(2)
	moves := make([]stagedActorMove, 0, entries.Len())
	moving := make(map[akara.Entity]bool, entries.Len())
	destinations := make(map[gridCell]bool, entries.Len())

	for index := 1; index <= entries.Len(); index++ {
		entry, ok := entries.RawGetInt(index).(*lua.LTable)

		if !ok {
			state.RaiseError("batch move %d must be a table", index)

			return 0
		}

		move, err := r.decodeActorMove(entry)

		if err != nil {
			state.RaiseError("invalid batch move %d: %v", index, err)

			return 0
		}

		if moving[move.actor] || destinations[move.next] ||
			!r.stagedWalkable(move.next) {
			state.RaiseError("invalid batch move %d", index)

			return 0
		}

		moving[move.actor] = true
		destinations[move.next] = true
		moves = append(moves, move)
	}

	for index, move := range moves {
		occupant, occupied := r.stagedActorAt(move.next)

		if occupied && !moving[occupant] {
			state.RaiseError("batch move %d destination is occupied", index+1)

			return 0
		}
	}

	forward := make([]ActorMove, 0, len(moves))
	reverse := make([]ActorMove, 0, len(moves))

	for _, move := range moves {
		r.pendingActors[move.old] = 0
	}

	for _, move := range moves {
		r.stageActorPosition(move.actor, nil, &move.next)
		forward = append(forward, ActorMove{
			Actor:   move.actor,
			LevelID: move.next.levelID,
			X:       move.next.x,
			Y:       move.next.y,
		})
		reverse = append(reverse, ActorMove{
			Actor:   move.actor,
			LevelID: move.old.levelID,
			X:       move.old.x,
			Y:       move.old.y,
		})
	}

	if len(moves) > 0 {
		r.pending = append(r.pending, structuralCommand{
			apply: func() error {
				return r.services.Grid.MoveActors(forward)
			},
			undo: func() error {
				return r.services.Grid.MoveActors(reverse)
			},
		})
	}

	return 0
}
