package combat

import "fmt"

// UnresistedWeaponBrandBonus follows attack.cc:apply_damage_brand for the
// supported Fighter, whose current species and equipment grant no fire, cold,
// or electric resistance. The caller adds this after ordinary melee damage.
func UnresistedWeaponBrandBonus(
	r Roller,
	brand string,
	damageDone int,
) (int, error) {
	if r == nil || damageDone < 0 {
		return 0, fmt.Errorf("invalid branded hit damage %d", damageDone)
	}

	switch brand {
	case "SPWPN_FLAMING", "SPWPN_FREEZING":
		if damageDone == 0 {
			return 0, nil
		}

		roll, err := random2(r, damageDone)

		if err != nil {
			return 0, err
		}

		return 1 + roll/2, nil

	case "SPWPN_VORPAL":
		if damageDone == 0 {
			return 0, nil
		}

		roll, err := random2(r, damageDone)

		if err != nil {
			return 0, err
		}

		return 1 + roll/3, nil

	case "SPWPN_ELECTROCUTION":
		trigger, err := random2(r, 4)

		if err != nil {
			return 0, err
		}

		if trigger != 0 {
			return 0, nil
		}

		roll, err := random2(r, 13)

		if err != nil {
			return 0, err
		}

		return 8 + roll, nil

	default:
		return 0, fmt.Errorf("unsupported damage brand %s", brand)
	}
}
