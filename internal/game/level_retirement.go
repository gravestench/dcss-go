package game

import (
	"fmt"
	"sort"

	"github.com/gravestench/akara"
)

// levelOwnedEntities follows the common ECS location and ownership links.
// Dynamic mod components with a level_id field join automatically, so a new
// cloud or vault effect cannot silently outlive its retired region.
func (g *Game) levelOwnedEntities(levelID int) (map[akara.Entity]bool, error) {
	owned := make(map[akara.Entity]bool)

	for _, entity := range g.world.Entities() {
		if entity == g.player {
			continue
		}

		position, found := g.stores.Positions.Get(entity)

		if found && position.LevelID == levelID {
			owned[entity] = true
		}
	}

	components := g.scripts.Components()
	names := make([]string, 0, len(components))

	for name := range components {
		names = append(names, name)
	}

	sort.Strings(names)

	for _, name := range names {
		store := components[name]
		found := false

		for _, field := range store.Schema().Fields {
			if field.Name == "level_id" &&
				(field.Kind == akara.FieldInt64 ||
					field.Kind == akara.FieldUint64) {
				found = true
				break
			}
		}

		if !found {
			continue
		}

		for _, entity := range store.Entities() {
			if entity == g.player {
				continue
			}

			component, present := store.Get(entity)

			if !present {
				continue
			}

			value, err := component.Get("level_id")

			if err != nil {
				return nil, fmt.Errorf("%s entity %d level: %w",
					name, entity, err)
			}

			matches := value == int64(levelID) ||
				value == uint64(levelID)

			if !matches {
				continue
			}

			position, positioned := g.stores.Positions.Get(entity)

			if !positioned || position.LevelID == levelID {
				owned[entity] = true
			}
		}
	}

	// Carried items, reserved offers, and shop stock have owners instead of
	// floor positions. Follow those links until the ownership closure is full.
	for changed := true; changed; {
		changed = false

		for _, entity := range g.world.Entities() {
			if entity == g.player || owned[entity] {
				continue
			}

			if carrier, found := g.stores.CarriedBy.Get(entity); found &&
				owned[carrier.Holder] {
				owned[entity] = true
				changed = true
				continue
			}

			if reservation, found := g.stores.ReservedBy.Get(entity); found &&
				owned[reservation.Owner] {
				owned[entity] = true
				changed = true
				continue
			}

			stock := components["shop.stock"]

			if stock == nil {
				continue
			}

			value, found := stock.Get(entity)

			if !found {
				continue
			}

			owner, err := value.Get("shop_id")

			if err != nil {
				return nil, fmt.Errorf("shop stock %d owner: %w",
					entity, err)
			}

			if shopID, okay := owner.(uint64); okay &&
				owned[akara.Entity(shopID)] {
				owned[entity] = true
				changed = true
			}
		}
	}

	return owned, nil
}

// retireLevel discards one replaced region only after its player has left.
// The Lua policy first prunes shopping-list references, then Akara removes
// all old live entities and Go drops the unreachable terrain grid.
func (g *Game) retireLevel(levelID int) error {
	if g.levels[levelID] == nil {
		return fmt.Errorf("retired level %d is missing", levelID)
	}

	if position, found := g.stores.Positions.Get(g.player); found &&
		position.LevelID == levelID {
		return fmt.Errorf("cannot retire the player's current level")
	}

	owned, err := g.levelOwnedEntities(levelID)

	if err != nil {
		return err
	}

	ids := make([]akara.Entity, 0, len(owned))

	for entity := range owned {
		ids = append(ids, entity)
	}

	sort.Slice(ids, func(i, j int) bool {
		return ids[i] < ids[j]
	})

	values := make([]any, 0, len(ids))

	for _, entity := range ids {
		values = append(values, uint64(entity))
	}

	if _, err := g.scripts.Policy("world.prune_retired_stock",
		map[string]any{"entity_ids": values}); err != nil {
		return err
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return err
	}

	for _, entity := range ids {
		if !g.world.DestroyEntity(entity) {
			return fmt.Errorf("could not retire level %d entity %d",
				levelID, entity)
		}
	}

	delete(g.levels, levelID)

	return nil
}
