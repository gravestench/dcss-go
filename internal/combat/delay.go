package combat

import "fmt"

// AttackDelayInput contains the ordinary Fighter's selected weapon or hands,
// stored skill values at scale 10, and the equipped buckler's EV property.
type AttackDelayInput struct {
	Unarmed                    bool
	WeaponSkillID              string
	WeaponSpeed, WeaponSkill10 int
	ShieldEV, ShieldsSkill10   int
}

// Validate rejects timing inputs outside the supported normal Human start.
func (in AttackDelayInput) Validate() error {
	if in.WeaponSkill10 < 0 || in.WeaponSkill10 > 270 || in.ShieldsSkill10 < 0 || in.ShieldsSkill10 > 270 ||
		in.ShieldEV > 0 || in.ShieldEV < -1000 {
		return fmt.Errorf("invalid Human Fighter attack delay %+v", in)
	}
	if in.Unarmed {
		if in.WeaponSkillID != "SK_UNARMED_COMBAT" || in.WeaponSpeed != 0 {
			return fmt.Errorf("invalid unarmed delay %+v", in)
		}
		return nil
	}
	if in.WeaponSpeed <= 0 {
		return fmt.Errorf("invalid weapon speed %d", in.WeaponSpeed)
	}
	switch in.WeaponSkillID {
	case "SK_SHORT_BLADES", "SK_LONG_BLADES", "SK_MACES_FLAILS", "SK_AXES", "SK_POLEARMS":
		return nil
	default:
		return fmt.Errorf("unsupported attack-delay weapon skill %s", in.WeaponSkillID)
	}
}

func randomRoundDivision(r Roller, numerator, denominator int) (int, error) {
	whole, remainder := numerator/denominator, numerator%denominator
	if remainder == 0 {
		return whole, nil
	}
	roll, err := random2(r, denominator)
	if err != nil {
		return 0, err
	}
	if roll < remainder {
		whole++
	}
	return whole, nil
}

func minimumWeaponDelay(speed int, skillID string) int {
	minimum := speed / 2
	if skillID == "SK_SHORT_BLADES" && minimum > 5 {
		minimum = 5
	}
	if minimum > 7 {
		minimum = 7
	}
	return max(3, minimum, speed-14) // MAX_SKILL_LEVEL 27, rounded half 14
}

// PlayerAttackDelay is the normal-speed primary attack cost in auts.
func PlayerAttackDelay(r Roller, in AttackDelayInput) (int, error) {
	if r == nil {
		return 0, fmt.Errorf("attack delay requires a roller")
	}
	if err := in.Validate(); err != nil {
		return 0, err
	}
	delay := 10
	if in.Unarmed {
		reduction, err := randomRoundDivision(r, in.WeaponSkill10, 54)
		if err != nil {
			return 0, err
		}
		delay -= reduction
	} else {
		minimum := minimumWeaponDelay(in.WeaponSpeed, in.WeaponSkillID)
		cappedSkill := min(in.WeaponSkill10, 10*(in.WeaponSpeed-minimum)*2)
		reduction, err := randomRoundDivision(r, cappedSkill, 20)
		if err != nil {
			return 0, err
		}
		delay = in.WeaponSpeed - reduction
	}
	delay = max(delay, 3)
	baseShieldPenalty := -in.ShieldEV / 10
	shieldPenalty20 := 2 * baseShieldPenalty * baseShieldPenalty *
		(270 - in.ShieldsSkill10) * 20 / (5 * 20) / 270
	shieldDelay, err := randomRoundDivision(r, shieldPenalty20, 20)
	if err != nil {
		return 0, err
	}
	return max(2, delay+shieldDelay), nil
}
