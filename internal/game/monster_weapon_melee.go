package game

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/combat"
	"github.com/gravestench/akara"
)

// monsterMeleeWeapon projects a live Akara item into the source attack
// calculation. A ranged primary leaves the alternate melee weapon available.
func (s *combatSystem) monsterMeleeWeapon(
	monsterID akara.Entity,
) (*combat.MeleeWeapon, error) {
	var primary *combat.MeleeWeapon
	var alternate *combat.MeleeWeapon

	seen := make(map[string]bool)

	for _, entity := range s.equipped.Entities() {
		carrier, carried := s.carried.Get(entity)

		if !carried || carrier.Holder != monsterID {
			continue
		}

		slot, _ := s.equipped.Get(entity)

		if slot.Slot != "weapon" && slot.Slot != "alternate_weapon" {
			if slot.Slot == "missile" {
				continue
			}

			return nil, fmt.Errorf("monster %d has unsupported equipment slot %q", monsterID, slot.Slot)
		}

		if seen[slot.Slot] {
			return nil, fmt.Errorf("monster %d has duplicate %s slot", monsterID, slot.Slot)
		}

		seen[slot.Slot] = true

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

		weapon := &combat.MeleeWeapon{
			Damage: kind.Weapon.Damage,
			Hit:    kind.Weapon.Hit,
			Plus:   item.Plus,
		}

		if slot.Slot == "weapon" {
			primary = weapon
		} else {
			alternate = weapon
		}
	}

	if primary != nil {
		return primary, nil
	}

	return alternate, nil
}
