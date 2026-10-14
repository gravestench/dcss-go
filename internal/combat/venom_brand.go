package combat

import (
	"fmt"
	"math"
)

// VenomBrandPoisonAmount follows attack.cc:apply_poison_damage_brand.
// Venom triggers on three of four landed hits, even when base damage is zero.
func VenomBrandPoisonAmount(r Roller, damageDone int) (int, error) {
	if r == nil ||
		damageDone < 0 ||
		damageDone > math.MaxInt/3 {
		return 0, fmt.Errorf("invalid venom damage %d", damageDone)
	}

	trigger, err := random2(r, 4)

	if err != nil {
		return 0, err
	}

	if trigger == 0 {
		return 0, nil
	}

	base, err := random2(r, 8)

	if err != nil {
		return 0, err
	}

	bonus, err := random2(r, damageDone*3/2)

	if err != nil {
		return 0, err
	}

	return 6 + base + bonus, nil
}
