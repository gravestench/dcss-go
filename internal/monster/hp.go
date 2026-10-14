package monster

import "fmt"

// Roller supplies a deterministic, saveable stream for monster creation.
type Roller interface {
	Intn(stream string, bound int) (int, error)
}

const maxMonsterHP = 10000
const maxSafeAverageHP = int(^uint(0)>>1) / 33

// RollHP follows mon-util.cc's hit_points(avg_hp_10x) and the live cap from
// mon-place.cc. A source average of zero is a special monster case and cannot
// be used to create an ordinary live monster.
func RollHP(roller Roller, averageHP10x int) (int, error) {
	if roller == nil || averageHP10x <= 0 || averageHP10x > maxSafeAverageHP {
		return 0, fmt.Errorf("invalid monster average HP %d", averageHP10x)
	}

	variance, err := divRandRound(roller, averageHP10x*33, 100)

	if err != nil {
		return 0, err
	}

	sum, err := roll(roller, variance*2)

	if err != nil {
		return 0, err
	}

	for range 7 {
		part, partErr := roll(roller, variance*2+1)

		if partErr != nil {
			return 0, partErr
		}

		sum += part
	}

	raw := averageHP10x - variance + sum/8
	hp, err := divRandRound(roller, raw, 10)

	if err != nil {
		return 0, err
	}

	return min(maxMonsterHP, max(1, hp)), nil
}

func divRandRound(roller Roller, numerator, denominator int) (int, error) {
	if denominator <= 0 || numerator < 0 {
		return 0, fmt.Errorf("invalid random division %d/%d", numerator, denominator)
	}

	quotient, remainder := numerator/denominator, numerator%denominator

	if remainder == 0 {
		return quotient, nil
	}

	value, err := roll(roller, denominator)

	if err != nil {
		return 0, err
	}

	if value < remainder {
		quotient++
	}

	return quotient, nil
}

func roll(roller Roller, bound int) (int, error) {
	if bound <= 1 {
		return 0, nil
	}

	value, err := roller.Intn("monster_hp", bound)

	if err != nil {
		return 0, err
	}

	if value < 0 || value >= bound {
		return 0, fmt.Errorf("monster HP roll %d outside [0,%d)", value, bound)
	}

	return value, nil
}
