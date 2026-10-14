package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// durationSystem runs after the player's action effects, mirroring source
// player_reacts: the action that grants might also consumes its own aut.
type durationSystem struct {
	player    akara.Entity
	durations *akara.Store[ecs.Durations]
	turn      *TurnContext
}

func (s *durationSystem) Update(_ *akara.World, delta time.Duration) error {
	if s.turn.Actor != s.player {
		return nil
	}
	status, found := s.durations.Get(s.player)
	if !found {
		return fmt.Errorf("player has no duration state")
	}
	remaining, ended, err := character.DecayMight(status.MightAut, int(delta))
	if err != nil {
		return err
	}
	status.MightAut = remaining
	if ended {
		s.turn.Events = append(s.turn.Events, Event{Kind: "duration", Text: "You feel a little less mighty now."})
	}
	return nil
}
