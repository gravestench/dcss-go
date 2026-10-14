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

type weightedDelay struct {
	value, weight int
}

// roundedValues mirrors div_rand_round(random_var, d): it multiplies every
// source weight by d even when division is exact. No draw occurs here.
func roundedValues(numerator, denominator int) []weightedDelay {
	whole, remainder := numerator/denominator, numerator%denominator
	values := []weightedDelay{
		{
			value:  whole,
			weight: denominator - remainder,
		},
	}
	if remainder > 0 {
		values = append(values, weightedDelay{
			value:  whole + 1,
			weight: remainder,
		})
	}

	return values
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

	base := 10
	reductionNumerator, reductionDenominator := in.WeaponSkill10, 54
	if in.Unarmed {
		// Unarmed Combat uses 27*2 rather than the weapon's DELAY_SCALE.
	} else {
		minimum := minimumWeaponDelay(in.WeaponSpeed, in.WeaponSkillID)
		reductionNumerator = min(in.WeaponSkill10, 10*(in.WeaponSpeed-minimum)*2)
		reductionDenominator = 20
		base = in.WeaponSpeed
	}

	baseShieldPenalty := -in.ShieldEV / 10
	shieldPenalty20 := 2 * baseShieldPenalty * baseShieldPenalty *
		(270 - in.ShieldsSkill10) * 20 / (5 * 20) / 270
	// C++ builds one random_var: skill reduction, max(3), and shield
	// penalty combine as weighted distributions. The final normal-speed
	// div_rand_round(attk_delay*10, 10) multiplies all weights by 10.
	weights := make(map[int]int)
	for _, reduction := range roundedValues(reductionNumerator, reductionDenominator) {
		for _, shield := range roundedValues(shieldPenalty20, 20) {
			delay := max(2, max(3, base-reduction.value)+shield.value)
			weights[delay] += reduction.weight * shield.weight * 10
		}
	}

	low, high := 1<<31-1, 0
	for delay := range weights {
		low = min(low, delay)
		high = max(high, delay)
	}

	total := 0
	for delay := low; delay <= high; delay++ {
		total += weights[delay]
	}

	roll, err := random2(r, total)
	if err != nil {
		return 0, err
	}

	for delay := low; delay <= high; delay++ {
		if roll < weights[delay] {
			return delay, nil
		}

		roll -= weights[delay]
	}

	return 0, fmt.Errorf("attack delay distribution was empty")
}
