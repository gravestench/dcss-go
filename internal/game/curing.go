package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type quaffSystem struct {
	game *Game
	turn *TurnContext
}

func (s *quaffSystem) Update(_ *akara.World, _ time.Duration) error {
	g := s.game
	intent, found := g.stores.Intents.Get(s.turn.Actor)
	if !found || intent.Kind != ecs.IntentQuaff {
		return nil
	}
	if s.turn.Actor != g.player || intent.ItemID == 0 {
		return fmt.Errorf("unsupported quaff actor or item")
	}
	item, found := g.stores.Items.Get(intent.ItemID)
	carrier, carried := g.stores.CarriedBy.Get(intent.ItemID)
	if !found || !carried || carrier.Holder != g.player || item.Quantity <= 0 {
		return fmt.Errorf("potion %d is no longer carried", intent.ItemID)
	}
	var message string
	switch item.KindID {
	case "POT_CURING":
		health, found := g.stores.Health.Get(g.player)
		if !found {
			return fmt.Errorf("player has no health for curing")
		}
		newHP, err := character.CuringHP(g.rng, health.Current, health.Max)
		if err != nil {
			return err
		}
		health.Current = newHP
		message = "You feel better."
	case "POT_HEAL_WOUNDS":
		health, found := g.stores.Health.Get(g.player)
		if !found || health.Current == health.Max {
			return fmt.Errorf("player cannot use heal wounds at current health")
		}
		newHP, err := character.HealWoundsHP(g.rng, health.Current, health.Max)
		if err != nil {
			return err
		}
		health.Current = newHP
		message = "You feel much better."
	case "POT_MIGHT":
		durations, found := g.stores.Durations.Get(g.player)
		if !found {
			return fmt.Errorf("player has no duration state for might")
		}
		remaining, text, err := character.MightPotionDuration(g.rng, durations.MightAut)
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
