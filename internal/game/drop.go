package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type pendingItemDrop struct {
	actor    akara.Entity
	itemID   akara.Entity
	quantity int
}

type dropSystem struct {
	items   *akara.Store[ecs.Item]
	carried *akara.Store[ecs.CarriedBy]
	intents *akara.Store[ecs.Intent]
	catalog content.Catalog
	turn    *TurnContext
}

func (g *Game) prepareDropCommand(command Command) (preparedCommand, error) {
	if command.Quantity < 0 {
		return freeCommand(g.noTime("Drop quantity must be positive.")), nil
	}

	itemID := akara.Entity(command.ItemID)
	item, found := g.stores.Items.Get(itemID)
	carrier, carried := g.stores.CarriedBy.Get(itemID)

	if !found ||
		!carried || carrier.Holder != g.player {
		return freeCommand(g.noTime("You are not carrying that item.")), nil
	}

	kind, err := g.catalog.Item(item.KindID)

	if err != nil {
		return preparedCommand{}, err
	}

	if err := validateItemProperties(*item, kind); err != nil {
		return preparedCommand{}, fmt.Errorf("cannot drop item %d: %w", itemID, err)
	}

	if equipped, found := g.stores.Equipped.Get(itemID); found &&
		equipped.Slot != "weapon" {
		return freeCommand(g.noTime("You will have to take that off first.")), nil
	}

	quantity := command.Quantity

	if quantity == 0 || quantity > item.Quantity {
		quantity = item.Quantity
	}

	return spendingCommand(ecs.Intent{
		Kind:     ecs.IntentDrop,
		ItemID:   itemID,
		Quantity: quantity,
	}, 10), nil
}

func (s *dropSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)

	if !found || intent.Kind != ecs.IntentDrop {
		return nil
	}

	item, found := s.items.Get(intent.ItemID)
	carrier, carried := s.carried.Get(intent.ItemID)

	if !found ||
		!carried ||
		carrier.Holder != s.turn.Actor ||
		intent.Quantity <= 0 || intent.Quantity > item.Quantity {
		return fmt.Errorf("drop actor %d has invalid item %d", s.turn.Actor, intent.ItemID)
	}

	kind, err := s.catalog.Item(item.KindID)

	if err != nil {
		return err
	}

	s.turn.Drop = &pendingItemDrop{
		actor:    s.turn.Actor,
		itemID:   intent.ItemID,
		quantity: intent.Quantity,
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "drop",
		Text: dropMessage(kind.Name, intent.Quantity),
	})

	return nil
}

func dropMessage(name string, quantity int) string {
	return "You drop " + itemActionPhrase(name, quantity) + "."
}

// applyDrop runs after World.Update because the item may gain or lose
// components, or a partial stack may become a new Akara entity.
func (g *Game) applyDrop(drop pendingItemDrop, buffer *akara.CommandBuffer) error {
	item, found := g.stores.Items.Get(drop.itemID)
	carrier, carried := g.stores.CarriedBy.Get(drop.itemID)
	position, located := g.stores.Positions.Get(drop.actor)

	if !found ||
		!carried ||
		carrier.Holder != drop.actor ||
		!located ||
		drop.quantity <= 0 || drop.quantity > item.Quantity {
		return fmt.Errorf("invalid pending drop item %d", drop.itemID)
	}

	if floorID, found := g.compatibleFloorStack(*position, *item, drop.itemID); found {
		floor, _ := g.stores.Items.Get(floorID)
		floor.Quantity += drop.quantity

		if drop.quantity == item.Quantity {
			buffer.Destroy(g.world, drop.itemID)
		} else {
			item.Quantity -= drop.quantity
		}

		return nil
	}

	if drop.quantity == item.Quantity {
		g.stores.Equipped.Remove(drop.itemID)

		if !g.stores.CarriedBy.Remove(drop.itemID) {
			return fmt.Errorf("item %d lost its carrier", drop.itemID)
		}

		_, err := g.stores.Positions.Set(drop.itemID, *position)

		return err
	}

	dropped, err := g.world.CreateEntity()

	if err != nil {
		return err
	}

	copy := *item

	copy.Quantity = drop.quantity

	if _, err := g.stores.Items.Set(dropped, copy); err != nil {
		return err
	}

	if _, err := g.stores.Positions.Set(dropped, *position); err != nil {
		return err
	}

	item.Quantity -= drop.quantity

	return nil
}

func (g *Game) compatibleFloorStack(
	position ecs.Position,
	item ecs.Item,
	exclude akara.Entity,
) (akara.Entity, bool) {
	kind, err := g.catalog.Item(item.KindID)

	if err != nil ||
		!kind.Stackable {
		return 0, false
	}

	for _, entity := range g.stores.Items.Entities() {
		if entity == exclude ||
			g.stores.CarriedBy.Has(entity) ||
			g.stores.Corpses.Has(entity) {
			continue
		}

		location, located := g.stores.Positions.Get(entity)
		floorItem, found := g.stores.Items.Get(entity)

		if !located ||
			!found || *location != position {
			continue
		}

		if matchingItemStack(*floorItem, item) {
			return entity, true
		}
	}

	return 0, false
}
