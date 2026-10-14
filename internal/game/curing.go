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
	if !found || !carried || carrier.Holder != g.player || item.KindID != "POT_CURING" || item.Quantity <= 0 {
		return fmt.Errorf("curing potion %d is no longer carried", intent.ItemID)
	}
	health, found := g.stores.Health.Get(g.player)
	if !found {
		return fmt.Errorf("player has no health for curing")
	}
	newHP, err := character.CuringHP(g.rng, health.Current, health.Max)
	if err != nil {
		return err
	}
	health.Current = newHP
	s.turn.Consume = intent.ItemID
	s.turn.Events = append(s.turn.Events, Event{Kind: "quaff", Text: "You feel better."})
	return nil
}
