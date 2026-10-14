package combat

import "fmt"

// HeadbuttInput is a live projection of innate horns, player combat state,
// and the adjacent target. The catalog owns the innate mutation levels.
type HeadbuttInput struct {
	Level            int
	Horns            int
	Reflexive        bool
	Strength         int
	Dexterity        int
	FightingSkill100 int
	FightingSkill30  int
	DefenderEV       int
	DefenderAC       int
	Mighty           bool
}

func (in HeadbuttInput) Validate() error {
	if in.Level < 1 ||
		in.Level > 27 ||
		in.Horns < 0 ||
		in.Horns > 3 ||
		in.Strength <= 0 ||
		in.Dexterity < 0 ||
		in.FightingSkill100 < 0 ||
		in.FightingSkill30 < 0 ||
		in.DefenderEV < 0 ||
		in.DefenderAC < 0 {
		return fmt.Errorf("invalid headbutt input %+v", in)
	}

	return nil
}

// HeadbuttOutcome distinguishes an absent attack from an attempted miss.
type HeadbuttOutcome struct {
	Attempted bool
	Hit       bool
	Damage    int
}

// AuxiliaryHeadbutt follows the source's XL-scaled trigger, accuracy,
// Strength, Fighting, might, and target AC phases.
func AuxiliaryHeadbutt(r Roller, in HeadbuttInput) (HeadbuttOutcome, error) {
	if r == nil {
		return HeadbuttOutcome{}, fmt.Errorf("headbutt requires a roller")
	}

	if err := in.Validate(); err != nil {
		return HeadbuttOutcome{}, err
	}

	if in.Horns == 0 {
		return HeadbuttOutcome{}, nil
	}

	chance := 67 * (30 + in.Level) / 59
	trigger, err := random2(r, 100)

	if err != nil {
		return HeadbuttOutcome{}, err
	}

	if trigger >= chance {
		return HeadbuttOutcome{}, nil
	}

	result := HeadbuttOutcome{Attempted: true}
	toHitBase := (1300 + in.Dexterity*75 + in.FightingSkill30) / 100
	toHit, err := random2(r, toHitBase)

	if err != nil {
		return HeadbuttOutcome{}, err
	}

	autoHit, err := random2(r, 30)

	if err != nil {
		return HeadbuttOutcome{}, err
	}

	if toHit < in.DefenderEV && autoHit != 0 {
		return result, nil
	}

	// attack_shield_blocked draws the bypass roll even for a shieldless
	// ordinary animal. This draw precedes auxiliary damage in DCSS.
	if _, err := random2(r, 15+toHit/2); err != nil {
		return HeadbuttOutcome{}, err
	}

	result.Hit = true
	result.Damage, err = headbuttDamage(r, in)

	return result, err
}

// ReflexiveHeadbutt applies after an eligible adjacent first attack misses.
// It has no accuracy contest; the caller decides dodge eligibility.
func ReflexiveHeadbutt(r Roller, in HeadbuttInput) (HeadbuttOutcome, error) {
	if r == nil {
		return HeadbuttOutcome{}, fmt.Errorf("headbutt requires a roller")
	}

	if err := in.Validate(); err != nil {
		return HeadbuttOutcome{}, err
	}

	if !in.Reflexive || in.Horns == 0 {
		return HeadbuttOutcome{}, nil
	}

	trigger, err := random2(r, 100)

	if err != nil {
		return HeadbuttOutcome{}, err
	}

	if trigger >= 23+in.Level {
		return HeadbuttOutcome{}, nil
	}

	damage, err := headbuttDamage(r, in)

	return HeadbuttOutcome{
		Attempted: true,
		Hit:       true,
		Damage:    damage,
	}, err
}

func headbuttDamage(r Roller, in HeadbuttInput) (int, error) {
	base := 5 + in.Horns*3
	potential := base * max(2, 150+5*in.Strength) / 2 / 100
	damage, err := random2(r, potential)

	if err != nil {
		return 0, err
	}

	fighting, err := random2(r, in.FightingSkill100+1)

	if err != nil {
		return 0, err
	}

	damage = damage * (4000 + fighting) / 4000

	if in.Mighty {
		bonus, bonusErr := random2(r, 10)

		if bonusErr != nil {
			return 0, bonusErr
		}

		damage += 1 + bonus
	}

	saved, err := playerArmourReduction(r, in.DefenderAC)

	if err != nil {
		return 0, err
	}

	return max(0, damage-saved), nil
}
