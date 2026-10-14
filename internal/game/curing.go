package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type quaffSystem struct {
	player    akara.Entity
	intents   *akara.Store[ecs.Intent]
	items     *akara.Store[ecs.Item]
	carried   *akara.Store[ecs.CarriedBy]
	health    *akara.Store[ecs.Health]
	durations *akara.Store[ecs.Durations]
	rng       character.Roller
	turn      *TurnContext
}

func (s *quaffSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)
	if !found || intent.Kind != ecs.IntentQuaff {
		return nil
	}
	if s.turn.Actor != s.player || intent.ItemID == 0 {
		return fmt.Errorf("unsupported quaff actor or item")
	}
	item, found := s.items.Get(intent.ItemID)
	carrier, carried := s.carried.Get(intent.ItemID)
	if !found || !carried || carrier.Holder != s.player || item.Quantity <= 0 {
		return fmt.Errorf("potion %d is no longer carried", intent.ItemID)
	}
	var message string
	switch item.KindID {
	case "POT_CURING":
		health, found := s.health.Get(s.player)
		if !found {
			return fmt.Errorf("player has no health for curing")
		}
		newHP, err := character.CuringHP(s.rng, health.Current, health.Max)
		if err != nil {
			return err
		}
		health.Current = newHP
		message = "You feel better."
	case "POT_HEAL_WOUNDS":
		health, found := s.health.Get(s.player)
		if !found || health.Current == health.Max {
			return fmt.Errorf("player cannot use heal wounds at current health")
		}
		newHP, err := character.HealWoundsHP(s.rng, health.Current, health.Max)
		if err != nil {
			return err
		}
		health.Current = newHP
		message = "You feel much better."
	case "POT_MIGHT":
		durations, found := s.durations.Get(s.player)
		if !found {
			return fmt.Errorf("player has no duration state for might")
		}
		remaining, text, err := character.MightPotionDuration(s.rng, durations.MightAut)
		if err != nil {
			return err
		}
		durations.MightAut, message = remaining, text
	default:
		return fmt.Errorf("unsupported potion %s", item.KindID)
	}
	s.turn.Consume = intent.ItemID
	s.turn.Events = append(s.turn.Events, Event{Kind: "quaff", Text: message})
	return nil
}
