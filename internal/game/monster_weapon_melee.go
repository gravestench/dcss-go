package game

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/combat"
	"github.com/gravestench/akara"
)

// monsterMeleeWeapon projects one live Akara item into the source attack
// calculation. Ranged weapons cannot contribute to a melee AT_HIT.
func (s *combatSystem) monsterMeleeWeapon(
	monsterID akara.Entity,
) (*combat.MeleeWeapon, error) {
	var selected *combat.MeleeWeapon

	for _, entity := range s.equipped.Entities() {
		carrier, carried := s.carried.Get(entity)

		if !carried || carrier.Holder != monsterID {
			continue
		}

		slot, _ := s.equipped.Get(entity)

		if slot.Slot != "weapon" {
			return nil, fmt.Errorf("monster %d has unsupported equipment slot %q", monsterID, slot.Slot)
		}

		if selected != nil {
			return nil, fmt.Errorf("monster %d has multiple melee weapons", monsterID)
		}

		item, found := s.items.Get(entity)

		if !found {
			return nil, fmt.Errorf("monster %d weapon %d has no item", monsterID, entity)
		}

		kind, err := s.catalog.Item(item.KindID)

		if err != nil {
			return nil, err
		}

		if err := validateItemProperties(*item, kind); err != nil {
			return nil, fmt.Errorf("monster %d weapon %d: %w", monsterID, entity, err)
		}

		if kind.Class != "OBJ_WEAPONS" || kind.Weapon == nil {
			return nil, fmt.Errorf("monster %d has non-weapon item %s equipped", monsterID, kind.ID)
		}

		if slices.Contains(kind.Weapon.DamageFlags, "DAMV_NON_MELEE") {
			continue
		}

		selected = &combat.MeleeWeapon{
			Damage: kind.Weapon.Damage,
			Hit:    kind.Weapon.Hit,
			Plus:   item.Plus,
		}
	}

	return selected, nil
}
