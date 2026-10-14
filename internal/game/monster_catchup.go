package game

import (
	"fmt"
	"slices"
	"sort"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

// monsterCatchupSystem applies the supported part of update_monster once
// when the player returns to a visited floor. It never schedules ordinary
// missed turns. Source: timed-effects.cc:432-540 and 733-759.
type monsterCatchupSystem struct {
	actors    *akara.Store[ecs.Actor]
	health    *akara.Store[ecs.Health]
	positions *akara.Store[ecs.Position]
	ai        *akara.Store[ecs.MonsterAI]
	catalog   content.Catalog
	rng       monster.Roller
}

func (s monsterCatchupSystem) TickLevel(level *Level, turns int) error {
	if level == nil || turns < 0 {
		return fmt.Errorf("invalid monster catch-up level or turns")
	}

	entities := s.ai.Entities()
	sort.Slice(entities, func(i, j int) bool {
		return entities[i] < entities[j]
	})

	for _, entity := range entities {
		position, found := s.positions.Get(entity)

		if !found {
			return fmt.Errorf("monster %d has no position for catch-up", entity)
		}

		if position.LevelID != level.ID {
			continue
		}

		actor, found := s.actors.Get(entity)

		if !found {
			return fmt.Errorf("monster %d has no actor for catch-up", entity)
		}

		health, found := s.health.Get(entity)

		if !found {
			return fmt.Errorf("monster %d has no health for catch-up", entity)
		}

		ai, _ := s.ai.Get(entity)
		definition, err := ordinaryAnimal(s.catalog, actor.KindID)

		if err != nil {
			return fmt.Errorf("monster %d catch-up: %w", entity, err)
		}

		if actor.Speed != definition.Speed {
			return fmt.Errorf("monster %d has incorrect catch-up speed", entity)
		}

		rate := 10

		if slices.Contains(definition.Flags, "M_FAST_REGEN") {
			rate = 100
		}

		recovery, err := monster.OffLevelRecovery(s.rng, turns, rate)

		if err != nil {
			return err
		}

		health.Current += min(recovery, health.Max-health.Current)

		moves := monster.OffLevelMoveCount(turns, actor.Speed)

		if err := catchUpMonsterMoves(level, entity, position, ai, moves); err != nil {
			return err
		}
	}

	return nil
}

func catchUpMonsterMoves(
	level *Level,
	entity akara.Entity,
	position *ecs.Position,
	ai *ecs.MonsterAI,
	moves int,
) error {
	if ai.TargetX == 0 && ai.TargetY == 0 {
		return nil
	}

	for range moves {
		dx := sign(ai.TargetX - position.X)
		dy := sign(ai.TargetY - position.Y)

		if dx == 0 && dy == 0 {
			break
		}

		nextX := position.X + dx
		nextY := position.Y + dy

		if !level.Walkable(nextX, nextY) {
			break
		}

		if _, occupied := level.ActorAt(nextX, nextY); occupied {
			break
		}

		if err := level.MoveActor(entity, nextX, nextY); err != nil {
			return err
		}
	}

	return nil
}
