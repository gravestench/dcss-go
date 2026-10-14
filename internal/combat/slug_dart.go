package combat

import "fmt"

// ResolveSlugDart follows the ordinary beam phase order in beam.cc. The
// source zap has 14 + power/35 to hit and 2d(3 + power/25) damage, where a
// natural monster spell has power 12 * HD. The zap's power cap applies only
// to player casts. Physical beams use ordinary AC
// without the melee guaranteed damage reduction.
func ResolveSlugDart(r Roller, hitDice int, defense Defense) (Outcome, error) {
	if r == nil ||
		hitDice <= 0 ||
		hitDice > 1000 ||
		defense.EV < 0 ||
		defense.AC < 0 ||
		defense.ShieldClass < 0 ||
		defense.ShieldBlocks < 0 {
		return Outcome{}, fmt.Errorf("invalid Slug Dart HD %d or defense %+v", hitDice, defense)
	}

	power := 12 * hitDice
	toHit := 14 + power/35
	dieSides := 3 + power/25

	if defense.ShieldClass > 0 {
		bypass := toHit*130/100 + 5*defense.ShieldBlocks*defense.ShieldBlocks
		bypassRoll, err := slugDartRoll(r, bypass)

		if err != nil {
			return Outcome{}, err
		}

		shieldRoll, err := slugDartAverageTwo(r, defense.ShieldClass*2)

		if err != nil {
			return Outcome{}, err
		}

		shieldBonus := shieldRoll/3 - 1

		if bypassRoll < shieldBonus {
			return Outcome{
				Kind:         Block,
				ShieldBlocks: defense.ShieldBlocks + 1,
			}, nil
		}
	}

	attackRoll, err := slugDartRoll(r, toHit)

	if err != nil {
		return Outcome{}, err
	}

	evasionRoll, err := slugDartAverageTwo(r, defense.EV)

	if err != nil {
		return Outcome{}, err
	}

	if attackRoll < evasionRoll {
		return Outcome{
			Kind:         Miss,
			ShieldBlocks: defense.ShieldBlocks,
		}, nil
	}

	first, err := slugDartRoll(r, dieSides)

	if err != nil {
		return Outcome{}, err
	}

	second, err := slugDartRoll(r, dieSides)

	if err != nil {
		return Outcome{}, err
	}

	armour, err := slugDartRoll(r, defense.AC+1)

	if err != nil {
		return Outcome{}, err
	}

	return Outcome{
		Kind:         Hit,
		Damage:       max(0, 2+first+second-armour),
		ShieldBlocks: defense.ShieldBlocks,
	}, nil
}

func slugDartAverageTwo(r Roller, bound int) (int, error) {
	first, err := slugDartRoll(r, bound)

	if err != nil {
		return 0, err
	}

	second, err := slugDartRoll(r, bound+1)

	if err != nil {
		return 0, err
	}

	return (first + second) / 2, nil
}

func slugDartRoll(r Roller, bound int) (int, error) {
	if bound <= 1 {
		return 0, nil
	}

	value, err := r.Intn("monster_spell", bound)

	if err != nil {
		return 0, err
	}

	if value < 0 || value >= bound {
		return 0, fmt.Errorf("Slug Dart draw %d outside [0,%d)", value, bound)
	}

	return value, nil
}
