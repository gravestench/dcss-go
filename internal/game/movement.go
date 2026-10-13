package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type movementSystem struct {
	positions *akara.Store[ecs.Position]
	intents   *akara.Store[ecs.Intent]
	levels    map[int]*Level
	turn      *TurnContext
}

func (s *movementSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)
	if !found || intent.Kind != ecs.IntentMove {
		return nil
	}
	position, found := s.positions.Get(s.turn.Actor)
	if !found {
		return fmt.Errorf("moving actor %d has no position", s.turn.Actor)
	}
	level := s.levels[position.LevelID]
	x, y := position.X+intent.DX, position.Y+intent.DY
	if _, occupied := level.ActorAt(x, y); occupied {
		intent.Kind = ecs.IntentMelee
		return nil
	}
	return level.MoveActor(s.turn.Actor, x, y)
}

type stairSystem struct {
	positions *akara.Store[ecs.Position]
	intents   *akara.Store[ecs.Intent]
	levels    map[int]*Level
	turn      *TurnContext
}

func (s *stairSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)
	if !found || (intent.Kind != ecs.IntentUpstairs && intent.Kind != ecs.IntentDownstairs) {
		return nil
	}
	position, found := s.positions.Get(s.turn.Actor)
	if !found {
		return fmt.Errorf("stair actor %d has no position", s.turn.Actor)
	}
	from := s.levels[position.LevelID]
	toID, x, y := 2, 1, 1
	if intent.Kind == ecs.IntentUpstairs {
		toID, x, y = 1, 7, 3
	}
	to := s.levels[toID]
	if !to.Walkable(x, y) {
		return fmt.Errorf("destination stair is blocked")
	}
	if _, occupied := to.ActorAt(x, y); occupied {
		return fmt.Errorf("destination stair is occupied")
	}
	oldX, oldY := position.X, position.Y
	if err := from.RemoveActor(s.turn.Actor); err != nil {
		return err
	}
	if err := to.PlaceActor(s.turn.Actor, x, y); err != nil {
		_ = from.PlaceActor(s.turn.Actor, oldX, oldY)
		return err
	}
	s.turn.Events = append(s.turn.Events, Event{Kind: "stairs", Text: "You take the stairs."})
	return nil
}
