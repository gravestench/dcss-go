package monster

import "fmt"

// FreezeDamage follows mon-cast.cc power 6*spell HD and
// spl-damage.cc's one die with 3 + power/3 sides.
func FreezeDamage(roller Roller, spellHD int) (int, error) {
	if roller == nil ||
		spellHD <= 0 ||
		spellHD > 1000 {
		return 0, fmt.Errorf("invalid Freeze spell HD %d", spellHD)
	}

	sides := 3 + 6*spellHD/3
	roll, err := roller.Intn("monster_spell", sides)

	if err != nil {
		return 0, err
	}

	if roll < 0 || roll >= sides {
		return 0, fmt.Errorf("Freeze damage roll %d outside [0,%d)", roll, sides)
	}

	return roll + 1, nil
}
