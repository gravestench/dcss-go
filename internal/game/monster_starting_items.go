package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

type monsterStartingItem struct {
	kindID   string
	quantity int
	plus     int
	ego      string
	slot     string
}

// createEarlyHumanoidItems turns one pure loadout into live Akara items.
// Every created item has exactly one carrier and one source inventory slot.
func (f ordinaryMonsterFactory) createEarlyHumanoidItems(
	holder akara.Entity,
	loadout monster.EarlyHumanoidLoadout,
) (_ []akara.Entity, err error) {
	specs := []monsterStartingItem{
		{
			kindID:   loadout.Primary.KindID,
			quantity: 1,
			plus:     loadout.Primary.Quality.Plus,
			ego:      loadout.Primary.Quality.Ego,
			slot:     "weapon",
		},
	}

	if loadout.Alternate.KindID != "" {
		specs = append(specs, monsterStartingItem{
			kindID:   loadout.Alternate.KindID,
			quantity: 1,
			plus:     loadout.Alternate.Quality.Plus,
			ego:      loadout.Alternate.Quality.Ego,
			slot:     "alternate_weapon",
		})
	}

	if loadout.Ammunition.KindID != "" {
		specs = append(specs, monsterStartingItem{
			kindID:   loadout.Ammunition.KindID,
			quantity: loadout.Ammunition.Quantity,
			ego:      loadout.Ammunition.Ego,
			slot:     "missile",
		})
	}

	created := make([]akara.Entity, 0, len(specs))

	defer func() {
		if err == nil {
			return
		}

		for _, itemID := range created {
			f.world.DestroyEntity(itemID)
		}
	}()

	for _, spec := range specs {
		itemID, createErr := f.createMonsterStartingItem(holder, spec)

		if createErr != nil {
			return nil, createErr
		}

		created = append(created, itemID)
	}

	return created, nil
}

func (f ordinaryMonsterFactory) createMonsterStartingItem(
	holder akara.Entity,
	spec monsterStartingItem,
) (_ akara.Entity, err error) {
	kind, err := f.catalog.Item(spec.kindID)

	if err != nil {
		return 0, err
	}

	switch spec.slot {
	case "weapon", "alternate_weapon":
		if kind.Class != "OBJ_WEAPONS" {
			return 0, fmt.Errorf("item %s is not a monster weapon", spec.kindID)
		}

	case "missile":
		if kind.Class != "OBJ_MISSILES" {
			return 0, fmt.Errorf("item %s is not monster ammunition", spec.kindID)
		}

	default:
		return 0, fmt.Errorf("unsupported monster inventory slot %s", spec.slot)
	}

	item := ecs.Item{
		KindID:   spec.kindID,
		Quantity: spec.quantity,
		Plus:     spec.plus,
		Ego:      spec.ego,
	}

	if err := validateItemProperties(item, kind); err != nil {
		return 0, fmt.Errorf("monster item %s: %w", spec.kindID, err)
	}

	entity, err := f.world.CreateEntity()

	if err != nil {
		return 0, err
	}

	defer func() {
		if err != nil {
			f.world.DestroyEntity(entity)
		}
	}()

	if _, err = f.stores.Items.Set(entity, item); err != nil {
		return 0, err
	}

	if _, err = f.stores.CarriedBy.Set(entity, ecs.CarriedBy{
		Holder: holder,
	}); err != nil {
		return 0, err
	}

	if _, err = f.stores.Equipped.Set(entity, ecs.Equipped{
		Slot: spec.slot,
	}); err != nil {
		return 0, err
	}

	return entity, nil
}
