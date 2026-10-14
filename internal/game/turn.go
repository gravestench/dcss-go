package game

import (
	"fmt"
	"sort"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// Aut is DCSS logical action time, independent of wall-clock durations.
type Aut int64

type schedulerPolicy func(string, map[string]any) (map[string]any, error)

// TurnScheduler projects Akara state into the active Lua scheduler rules.
type TurnScheduler struct {
	actors    *akara.Store[ecs.Actor]
	positions *akara.Store[ecs.Position]
	energies  *akara.Store[ecs.MonsterEnergy]
	policy    schedulerPolicy
}

// Grant retains the store's entity order so named RNG draws remain stable.
func (s TurnScheduler) Grant(levelID int, elapsed Aut) error {
	if elapsed <= 0 || int64(int(elapsed)) != int64(elapsed) {
		return fmt.Errorf("invalid player action time %d", elapsed)
	}

	entities := s.energies.Entities()
	monsters := make([]any, 0, len(entities))

	for _, entity := range entities {
		position, found := s.positions.Get(entity)

		if !found {
			return fmt.Errorf("monster %d has energy but no position", entity)
		}

		energy, _ := s.energies.Get(entity)
		speed := 0

		if position.LevelID == levelID {
			actor, found := s.actors.Get(entity)

			if !found {
				return fmt.Errorf("monster %d has energy but no actor", entity)
			}

			speed = actor.Speed
		}

		monsters = append(monsters, map[string]any{
			"level_id": position.LevelID,
			"speed":    speed,
			"points":   energy.Points,
		})
	}

	result, err := s.policy("scheduler.grant", map[string]any{
		"active_level": levelID,
		"elapsed":      int(elapsed),
		"monsters":     monsters,
	})

	if err != nil {
		return err
	}

	points, err := schedulerPoints(result["points"], len(entities))

	if err != nil {
		return err
	}

	for index, entity := range entities {
		energy, _ := s.energies.Get(entity)

		energy.Points = points[index]
	}

	return nil
}

// NextReady gives Lua candidates in entity order for the stable tie break.
func (s TurnScheduler) NextReady(levelID int) (akara.Entity, bool, error) {
	entities := append([]akara.Entity(nil), s.energies.Entities()...)
	sort.Slice(entities, func(left, right int) bool {
		return entities[left] < entities[right]
	})

	monsters := make([]any, 0, len(entities))

	for _, entity := range entities {
		position, found := s.positions.Get(entity)

		if !found {
			monsters = append(monsters, map[string]any{
				"level_id": -1,
				"points":   0,
			})

			continue
		}

		energy, _ := s.energies.Get(entity)
		monsters = append(monsters, map[string]any{
			"level_id": position.LevelID,
			"points":   energy.Points,
		})
	}

	result, err := s.policy("scheduler.next_ready", map[string]any{
		"active_level": levelID,
		"monsters":     monsters,
	})

	if err != nil {
		return 0, false, fmt.Errorf("next monster energy: %w", err)
	}

	index, ok := result["index"].(int64)

	if !ok ||
		index < 0 ||
		index > int64(len(entities)) {
		return 0, false, fmt.Errorf("invalid next monster index %v", result["index"])
	}

	if index == 0 {
		return 0, false, nil
	}

	return entities[index-1], true, nil
}

// Spend uses the final intent after movement has turned a bump into melee.
func (s TurnScheduler) Spend(entity akara.Entity, intent ecs.IntentKind) error {
	actor, found := s.actors.Get(entity)

	if !found {
		return fmt.Errorf("monster %d has no actor", entity)
	}

	energy, found := s.energies.Get(entity)

	if !found {
		return fmt.Errorf("monster %d has no energy", entity)
	}

	result, err := s.policy("scheduler.spend", map[string]any{
		"kind_id": actor.KindID,
		"intent":  int(intent),
		"points":  energy.Points,
	})

	if err != nil {
		return fmt.Errorf("monster %d energy spend: %w", entity, err)
	}

	points, ok := result["points"].(int64)

	if !ok {
		return fmt.Errorf("monster %d energy spend returned %T", entity, result["points"])
	}

	energy.Points = int(points)

	return nil
}

func schedulerPoints(value any, count int) ([]int, error) {
	if count == 0 {
		if empty, ok := value.(map[string]any); ok && len(empty) == 0 {
			return nil, nil
		}
	}

	rows, ok := value.([]any)

	if !ok || len(rows) != count {
		return nil, fmt.Errorf("monster energy grant returned %T for %d monsters", value, count)
	}

	points := make([]int, count)

	for index, row := range rows {
		value, ok := row.(int64)

		if !ok {
			return nil, fmt.Errorf("monster energy %d has type %T", index, row)
		}

		points[index] = int(value)
	}

	return points, nil
}
