package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// poisonSystem follows regeneration in the player's end-of-action phase.
// Monster actions do not decay the player's poison a second time.
type poisonSystem struct {
	player akara.Entity
	health *akara.Store[ecs.Health]
	poison *akara.Store[ecs.Poison]
	turn   *TurnContext
}

func (s *poisonSystem) Update(_ *akara.World, delta time.Duration) error {
	if s.turn.Actor != s.player {
		return nil
	}

	status, found := s.poison.Get(s.player)

	if !found {
		return nil
	}

	health, found := s.health.Get(s.player)

	if !found {
		return fmt.Errorf("poisoned player has no health")
	}

	next, damage, err := character.DecayHumanPoison(
		status.AmountScaled,
		int(delta),
	)

	if err != nil {
		return err
	}

	beforeHP := health.Current

	health.Current = max(0, health.Current-damage)

	if health.Current < beforeHP {
		s.turn.Events = append(s.turn.Events, Event{
			Kind: "poison",
			Text: poisonSicknessMessage(damage),
		})
	}

	if next == 0 {
		s.poison.Remove(s.player)

		if health.Current > 0 {
			s.turn.Events = append(s.turn.Events, Event{
				Kind: "poison",
				Text: "You are no longer poisoned.",
			})
		}
	} else {
		status.AmountScaled = next
	}

	if health.Current == 0 {
		s.turn.Events = append(s.turn.Events, Event{
			Kind: "death",
			Text: "You die.",
		})
	}

	return nil
}

func poisonSicknessMessage(damage int) string {
	if damage > 6 {
		return "You feel extremely sick."
	}

	if damage > 2 {
		return "You feel very sick."
	}

	return "You feel sick."
}
