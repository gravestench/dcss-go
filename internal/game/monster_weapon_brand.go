package game

import (
	"dcrawl-go/internal/combat"
	"github.com/gravestench/akara"
)

// monsterProtectionAC follows monster.cc:armour_class and wield_melee_weapon.
// A ranged primary gives way to its alternate melee weapon on placement.
func (s *combatSystem) monsterProtectionAC(monsterID akara.Entity) (int, error) {
	weapon, err := s.monsterMeleeWeapon(monsterID)

	if err != nil {
		return 0, err
	}

	if weapon != nil && weapon.Brand == "SPWPN_PROTECTION" {
		return 5, nil
	}

	return 0, nil
}

// Monster brands are admitted as their combat behavior is ported. Rejecting
// unsupported brands keeps a generated weapon from silently acting mundane.
func supportedMonsterMeleeBrand(brand string) bool {
	switch brand {
	case "", "SPWPN_NORMAL", "SPWPN_PROTECTION", "SPWPN_VENOM":
		return true

	default:
		return false
	}
}

func (s *combatSystem) applyMonsterWeaponBrand(
	brand string,
	damageDone int,
	sourceID string,
) error {
	if brand != "SPWPN_VENOM" {
		return nil
	}

	amount, err := combat.VenomBrandPoisonAmount(s.roller, damageDone)

	if err != nil {
		return err
	}

	if amount == 0 {
		return nil
	}

	return s.addPlayerPoison(amount, sourceID)
}
