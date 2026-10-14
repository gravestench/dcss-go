package game

import (
	"fmt"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// equippedMonsterItem projects one source inventory slot from live ECS state.
// It leaves weapon and missile-specific rules to the caller.
func equippedMonsterItem(
	monsterID akara.Entity,
	slotName string,
	catalog content.Catalog,
	items *akara.Store[ecs.Item],
	carried *akara.Store[ecs.CarriedBy],
	equipped *akara.Store[ecs.Equipped],
) (akara.Entity, ecs.Item, content.ItemDef, bool, error) {
	for _, itemID := range equipped.Entities() {
		slot, _ := equipped.Get(itemID)

		if slot.Slot != slotName {
			continue
		}

		carrier, found := carried.Get(itemID)

		if !found || carrier.Holder != monsterID {
			continue
		}

		item, found := items.Get(itemID)

		if !found {
			return 0, ecs.Item{}, content.ItemDef{}, false,
				fmt.Errorf("monster equipped item %d has no item", itemID)
		}

		kind, err := catalog.Item(item.KindID)

		if err != nil {
			return 0, ecs.Item{}, content.ItemDef{}, false, err
		}

		if err := validateItemProperties(*item, kind); err != nil {
			return 0, ecs.Item{}, content.ItemDef{}, false, err
		}

		return itemID, *item, kind, true, nil
	}

	return 0, ecs.Item{}, content.ItemDef{}, false, nil
}

type rangedPlayerTarget struct {
	definition content.MonsterDef
	defense    combat.Defense
	health     *ecs.Health
}

// rangedTarget checks that the current ECS attacker can reach the live
// player and projects the player's current defense once for the shot.
func (s *combatSystem) rangedTarget(kindID string) (rangedPlayerTarget, error) {
	actor, found := s.actors.Get(s.turn.Actor)

	if !found || actor.KindID != kindID {
		return rangedPlayerTarget{}, fmt.Errorf("unsupported ranged attacker %d", s.turn.Actor)
	}

	monsterPosition, monsterLocated := s.positions.Get(s.turn.Actor)
	playerPosition, playerLocated := s.positions.Get(s.player)
	monsterHealth, monsterAlive := s.health.Get(s.turn.Actor)
	playerHealth, playerAlive := s.health.Get(s.player)

	if !monsterLocated ||
		!playerLocated ||
		!monsterAlive ||
		!playerAlive ||
		monsterHealth.Current <= 0 ||
		playerHealth.Current <= 0 ||
		monsterPosition.LevelID != playerPosition.LevelID ||
		adjacentActors(*monsterPosition, *playerPosition) {
		return rangedPlayerTarget{}, fmt.Errorf("monster cannot shoot distant or dead player")
	}

	level := s.levels[monsterPosition.LevelID]

	if level == nil ||
		!level.ClearProjectilePath(
			monsterPosition.X,
			monsterPosition.Y,
			playerPosition.X,
			playerPosition.Y,
		) {
		return rangedPlayerTarget{}, fmt.Errorf("monster has no clear shot")
	}

	definition, err := s.catalog.Monster(kindID)

	if err != nil {
		return rangedPlayerTarget{}, err
	}

	defense, err := s.fighter.defense()

	if err != nil {
		return rangedPlayerTarget{}, err
	}

	return rangedPlayerTarget{
		definition: definition,
		defense:    defense,
		health:     playerHealth,
	}, nil
}
