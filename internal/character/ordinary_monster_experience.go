package character

import "fmt"

// OrdinaryMonsterXPInput contains the source stats for a monster with no
// spells, equipment, zombie state, or per-instance XP adjustment. The caller
// decides whether that ordinary subset applies and whether the kill grants XP.
type OrdinaryMonsterXPInput struct {
	HitDice      int
	MaxHP        int
	Speed        int
	Modifier     int
	AttackDamage [4]int
	FastRegen    bool
}

// OrdinaryMonsterExperience follows the integer stages of exper_value in
// mon-util.cc for its no-spell, no-item, unmerged ordinary-monster path.
func OrdinaryMonsterExperience(in OrdinaryMonsterXPInput) (int, error) {
	// These generous bounds cover the committed catalog while keeping every
	// intermediate product below signed 64-bit range on supported platforms.
	if in.HitDice <= 0 || in.HitDice > 1000 || in.MaxHP <= 0 || in.MaxHP > 10000 ||
		in.Speed <= 0 || in.Speed > 1000 || in.Modifier < 0 || in.Modifier > 1000 {
		return 0, fmt.Errorf("invalid ordinary monster XP stats %+v", in)
	}
	maxMelee := 0
	for _, damage := range in.AttackDamage {
		if damage < 0 || damage > 1000 {
			return 0, fmt.Errorf("invalid ordinary monster attack damage %d", damage)
		}
		maxMelee += damage
	}
	xp := (16 + in.MaxHP) * in.HitDice * in.HitDice / 10
	difficulty := 0
	if in.FastRegen {
		difficulty += 15
	}
	if in.Speed >= 10 && maxMelee > 30 {
		if in.Speed == 10 {
			difficulty += maxMelee / 2
		} else {
			difficulty += maxMelee
		}
	}
	if difficulty > 100 {
		difficulty = 100
	}
	xp = xp * (100 + difficulty) / 100
	xp = xp * in.Speed / 10
	if in.Speed < 10 {
		xp /= 2
	}
	if in.Modifier > 0 {
		xp = xp * in.Modifier / 10
	}
	if xp > 100 {
		xp = 100 + (xp-100)*3/4
	}
	if xp > 750 {
		xp = 750 + (xp-750)/6
	}
	return max(1, xp), nil
}
