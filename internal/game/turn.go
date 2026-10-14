package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// Aut is DCSS logical action time, independent of wall-clock durations.
type Aut int64

// TurnScheduler orders actors on the player's current floor. The Position
// store determines membership; inactive floors do not receive no-op turns.
type TurnScheduler struct {
	actors    *akara.Store[ecs.Actor]
	positions *akara.Store[ecs.Position]
}

func (s TurnScheduler) Next(levelID int) (akara.Entity, Aut, bool) {
	var chosen akara.Entity
	var at Aut

	for _, entity := range s.actors.Entities() {
		position, found := s.positions.Get(entity)

		if !found || position.LevelID != levelID {
			continue
		}

		actor, _ := s.actors.Get(entity)

		if chosen == 0 || Aut(actor.NextAut) < at {
			chosen, at = entity, Aut(actor.NextAut)
		}
	}

	return chosen, at, chosen != 0
}

func (s TurnScheduler) ScheduleAfter(entity akara.Entity, cost Aut) error {
	actor, found := s.actors.Get(entity)

	if !found ||
		actor.Speed <= 0 || cost <= 0 {
		return fmt.Errorf("cannot schedule actor %d with cost %d", entity, cost)
	}

	delay := (int64(cost)*10 + int64(actor.Speed) - 1) / int64(actor.Speed)

	if delay < 1 {
		delay = 1
	}

	actor.NextAut += delay

	return nil
}
