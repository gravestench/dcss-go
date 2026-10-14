package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// validateItemProperties is shared by save restore and live equipment use.
func validateItemProperties(item ecs.Item, kind content.ItemDef) error {
	if item.Quantity <= 0 || (!kind.Stackable && item.Quantity != 1) {
		return fmt.Errorf("impossible quantity")
	}
	if item.Charges < 0 || (item.Charges != 0 && kind.Class != "OBJ_WANDS") {
		return fmt.Errorf("impossible charges")
	}
	if item.Plus != 0 && kind.Class != "OBJ_WEAPONS" && kind.Class != "OBJ_ARMOUR" {
		return fmt.Errorf("impossible enchantment")
	}
	if item.Ego != "" {
		switch item.Ego {
		case "poisoned", "curare", "dispersal":
			if kind.Class != "OBJ_MISSILES" {
				return fmt.Errorf("incompatible ego")
			}
		default:
			return fmt.Errorf("unknown ego %q", item.Ego)
		}
	}
	return nil
}

func (g *Game) floorItemAt(position ecs.Position) (akara.Entity, bool) {
	for _, entity := range g.stores.Items.Entities() {
		itemPosition, located := g.stores.Positions.Get(entity)
		if located && *itemPosition == position && !g.stores.CarriedBy.Has(entity) {
			return entity, true
		}
	}
	return 0, false
}

type pickupSystem struct {
	positions *akara.Store[ecs.Position]
	items     *akara.Store[ecs.Item]
	carried   *akara.Store[ecs.CarriedBy]
	intents   *akara.Store[ecs.Intent]
	turn      *TurnContext
}

func (s *pickupSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)
	if !found || intent.Kind != ecs.IntentPickup {
		return nil
	}
	position, found := s.positions.Get(s.turn.Actor)
	if !found {
		return fmt.Errorf("pickup actor %d has no position", s.turn.Actor)
	}
	for _, entity := range s.items.Entities() {
		itemPosition, located := s.positions.Get(entity)
		if located && *itemPosition == *position && !s.carried.Has(entity) {
			s.turn.Pickup = entity
			s.turn.Events = append(s.turn.Events, Event{Kind: "pickup", Text: "You pick up a potion of curing."})
			return nil
		}
	}
	return fmt.Errorf("pickup actor %d has no floor item", s.turn.Actor)
}
