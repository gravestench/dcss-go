package game

import (
	"fmt"
	"strings"
	"time"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// validateItemProperties is shared by save restore and live equipment use.
func validateItemProperties(item ecs.Item, kind content.ItemDef) error {
	if item.Quantity <= 0 ||
		(!kind.Stackable && item.Quantity != 1) {
		return fmt.Errorf("impossible quantity")
	}

	if item.Charges < 0 ||
		(item.Charges != 0 && kind.Class != "OBJ_WANDS") {
		return fmt.Errorf("impossible charges")
	}

	if item.Plus != 0 &&
		kind.Class != "OBJ_WEAPONS" &&
		kind.Class != "OBJ_ARMOUR" {
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
	var stationary akara.Entity

	for _, entity := range g.stores.Items.Entities() {
		itemPosition, located := g.stores.Positions.Get(entity)

		if located &&
			*itemPosition == position && !g.stores.CarriedBy.Has(entity) {
			if g.stores.Corpses.Has(entity) {
				stationary = entity
				continue
			}

			return entity, true
		}
	}

	return stationary, stationary != 0
}

type pickupSystem struct {
	positions *akara.Store[ecs.Position]
	items     *akara.Store[ecs.Item]
	corpses   *akara.Store[ecs.Corpse]
	carried   *akara.Store[ecs.CarriedBy]
	intents   *akara.Store[ecs.Intent]
	catalog   content.Catalog
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

		if located &&
			*itemPosition == *position &&
			!s.carried.Has(entity) && !s.corpses.Has(entity) {
			item, found := s.items.Get(entity)

			if !found {
				return fmt.Errorf("pickup item %d has no item component", entity)
			}

			kind, err := s.catalog.Item(item.KindID)

			if err != nil {
				return err
			}

			s.turn.Pickup = entity
			s.turn.Events = append(s.turn.Events, Event{
				Kind: "pickup",
				Text: "You pick up " + itemActionPhrase(kind.Name, item.Quantity) + ".",
			})

			return nil
		}
	}

	return fmt.Errorf("pickup actor %d has no floor item", s.turn.Actor)
}

// applyPickup runs after Akara's systems, where carrier and position
// components can change without invalidating an active query.
func (g *Game) applyPickup(actor, itemID akara.Entity, buffer *akara.CommandBuffer) error {
	item, found := g.stores.Items.Get(itemID)
	_, located := g.stores.Positions.Get(itemID)

	if !found || !located {
		return fmt.Errorf("item has no floor location")
	}

	if carriedID, found := g.compatibleCarriedStack(actor, *item); found {
		carried, _ := g.stores.Items.Get(carriedID)

		carried.Quantity += item.Quantity
		buffer.Destroy(g.world, itemID)

		return nil
	}

	if !g.stores.Positions.Remove(itemID) {
		return fmt.Errorf("item lost its position")
	}

	_, err := g.stores.CarriedBy.Set(itemID, ecs.CarriedBy{Holder: actor})

	return err
}

func (g *Game) compatibleCarriedStack(actor akara.Entity, item ecs.Item) (akara.Entity, bool) {
	kind, err := g.catalog.Item(item.KindID)

	if err != nil ||
		!kind.Stackable {
		return 0, false
	}

	for _, entity := range g.stores.CarriedBy.Entities() {
		carrier, _ := g.stores.CarriedBy.Get(entity)
		carried, found := g.stores.Items.Get(entity)

		if carrier.Holder == actor &&
			found && matchingItemStack(*carried, item) {
			return entity, true
		}
	}

	return 0, false
}

func matchingItemStack(left, right ecs.Item) bool {
	// DCSS items_stack refuses merges that would exceed item quantity's range.
	// See items.cc:1577-1584 in the pinned source.
	maxQuantity := int(^uint(0) >> 1)

	return left.Quantity > 0 &&
		right.Quantity > 0 &&
		left.Quantity <= maxQuantity-right.Quantity &&
		left.KindID == right.KindID &&
		left.Plus == right.Plus &&
		left.Charges == right.Charges &&
		left.Ego == right.Ego
}

func itemActionPhrase(name string, quantity int) string {
	if quantity > 1 {
		if index := strings.Index(name, " of "); index > 0 {
			return fmt.Sprintf("%d %ss%s", quantity, name[:index], name[index:])
		}

		return fmt.Sprintf("%d %ss", quantity, name)
	}

	article := "a"

	if name != "" && strings.ContainsRune("aeiouAEIOU", rune(name[0])) {
		article = "an"
	}

	return article + " " + name
}
