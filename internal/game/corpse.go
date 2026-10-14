package game

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

type pendingCorpse struct {
	MonsterID  string
	Position   ecs.Position
	Appearance int
}

func (g *Game) placeCorpse(drop pendingCorpse) error {
	if _, err := g.catalog.Item("CORPSE_BODY"); err != nil {
		return err
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		return err
	}

	if _, err := g.stores.Items.Set(entity, ecs.Item{
		KindID:   "CORPSE_BODY",
		Quantity: 1,
	}); err != nil {
		return err
	}

	if _, err := ordinaryAnimal(g.catalog, drop.MonsterID); err != nil {
		return err
	}

	if _, err := g.stores.Corpses.Set(entity, ecs.Corpse{
		MonsterID:  drop.MonsterID,
		Freshness:  monster.FreshestCorpse,
		Appearance: drop.Appearance,
	}); err != nil {
		return err
	}

	if _, err := g.stores.Positions.Set(entity, drop.Position); err != nil {
		return err
	}

	return nil
}

// corpseTickElapsed keeps the source's 200-aut phase. The action coordinator
// calls this after all intervening monster actions, never during each actor's
// Akara update.
func corpseTickElapsed(startAut, endAut Aut) int {
	if endAut < startAut ||
		endAut/monster.CorpseRotIntervalAut == startAut/monster.CorpseRotIntervalAut {
		return 0
	}

	lastTick := startAut / monster.CorpseRotIntervalAut * monster.CorpseRotIntervalAut

	return int(endAut - lastTick)
}

// corpseAgingSystem owns corpse/item state transitions and entity removal.
// The turn coordinator invokes it at the post-action timer barrier, so rot
// never runs once for each monster that acts between player turns.
type corpseAgingSystem struct {
	world     *akara.World
	items     *akara.Store[ecs.Item]
	corpses   *akara.Store[ecs.Corpse]
	positions *akara.Store[ecs.Position]
	catalog   content.Catalog
	rng       monster.Roller
}

func (s corpseAgingSystem) TickLevel(levelID, elapsed int) error {
	for _, entity := range s.corpses.Entities() {
		corpse, found := s.corpses.Get(entity)
		item, itemFound := s.items.Get(entity)
		position, located := s.positions.Get(entity)

		if !found ||
			!itemFound || !located {
			return fmt.Errorf("corpse %d is not a floor item", entity)
		}

		if position.LevelID != levelID {
			continue
		}

		definition, err := ordinaryAnimal(s.catalog, corpse.MonsterID)

		if err != nil {
			return fmt.Errorf("corpse %d: %w", entity, err)
		}

		canSkeleton := !slices.Contains(definition.Flags, "M_NO_SKELETON")
		kind, freshness, appearance, alive, err := monster.AgeCorpse(
			s.rng,
			item.KindID,
			canSkeleton,
			corpse.Freshness,
			elapsed,
		)

		if err != nil {
			return err
		}

		if !alive {
			if !s.world.DestroyEntity(entity) {
				return fmt.Errorf("corpse %d could not be destroyed", entity)
			}

			continue
		}

		item.KindID = kind
		corpse.Freshness = freshness

		if appearance != 0 {
			corpse.Appearance = appearance
		}
	}

	return nil
}
