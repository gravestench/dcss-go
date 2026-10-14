package game

import (
	"fmt"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/ecs"
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
	case "", "SPWPN_NORMAL", "SPWPN_PROTECTION", "SPWPN_VENOM",
		"SPWPN_FLAMING", "SPWPN_FREEZING", "SPWPN_ELECTROCUTION",
		"SPWPN_VORPAL":
		return true

	default:
		return false
	}
}

func brandCanTriggerAfterDeath(brand string) bool {
	switch brand {
	case "SPWPN_FLAMING", "SPWPN_FREEZING", "SPWPN_ELECTROCUTION":
		return true

	default:
		return false
	}
}

func (s *combatSystem) applyMonsterWeaponBrand(
	brand string,
	damageDone int,
	sourceID string,
	attackerName string,
	victim *ecs.Health,
) error {
	switch brand {
	case "", "SPWPN_NORMAL", "SPWPN_PROTECTION":
		return nil

	case "SPWPN_VENOM":
		amount, err := combat.VenomBrandPoisonAmount(s.roller, damageDone)

		if err != nil {
			return err
		}

		if amount == 0 {
			return nil
		}

		return s.addPlayerPoison(amount, sourceID)

	case "SPWPN_FLAMING", "SPWPN_FREEZING", "SPWPN_ELECTROCUTION", "SPWPN_VORPAL":
		bonus, err := combat.UnresistedWeaponBrandBonus(
			s.roller,
			brand,
			damageDone,
		)

		if err != nil {
			return err
		}

		victim.Current = max(0, victim.Current-bonus)

		message := monsterDamageBrandMessage(brand, attackerName, bonus)

		if bonus > 0 &&
			message != "" {
			s.turn.Events = append(s.turn.Events, Event{
				Kind: "combat",
				Text: message,
			})
		}

		return nil

	default:
		return fmt.Errorf("unsupported monster melee brand %s", brand)
	}
}

func monsterDamageBrandMessage(brand, attackerName string, bonus int) string {
	switch brand {
	case "SPWPN_FLAMING":
		return fmt.Sprintf("The %s burns you.", attackerName)

	case "SPWPN_FREEZING":
		return fmt.Sprintf("The %s freezes you.", attackerName)

	case "SPWPN_ELECTROCUTION":
		// attack.cc:attack_strength_punctuation switches at 18 damage.
		if bonus >= 18 {
			return "You are electrocuted!!"
		}

		return "You are electrocuted!"

	default:
		return ""
	}
}
