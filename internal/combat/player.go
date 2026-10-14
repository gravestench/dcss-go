package combat

import "fmt"

// PlayerAttackInput is the ordinary Human Fighter primary attack projected
// from live character state, one equipped weapon, and the current defender.
type PlayerAttackInput struct {
	Strength  int
	Dexterity int

	FightingSkill100 int
	WeaponSkill100   int
	UnarmedSkill256  int

	WeaponSkillID string
	WeaponDamage  int
	WeaponHit     int
	WeaponPlus    int
	Unarmed       bool

	DefenderEV int
	DefenderAC int

	Mighty bool
}

// Validate rejects inputs outside the supported Human Fighter scenario.
func (in PlayerAttackInput) Validate() error {
	invalidStats := in.Strength <= 0 || in.Dexterity < 0 ||
		in.FightingSkill100 < 0 || in.WeaponSkill100 < 0 || in.UnarmedSkill256 < 0
	invalidDefender := in.DefenderEV < 0 || in.DefenderAC < 0
	invalidWeapon := in.WeaponPlus < -100 || in.WeaponPlus > 100

	if invalidStats ||
		invalidDefender || invalidWeapon {
		return fmt.Errorf("invalid Human Fighter attack %+v", in)
	}

	if in.Unarmed {
		if in.WeaponSkillID != "SK_UNARMED_COMBAT" ||
			in.WeaponDamage != 0 ||
			in.WeaponHit != 0 ||
			in.WeaponPlus != 0 {
			return fmt.Errorf("invalid unarmed attack %+v", in)
		}

		return nil
	}

	if in.WeaponDamage <= 0 || in.UnarmedSkill256 != 0 {
		return fmt.Errorf("invalid equipped weapon attack %+v", in)
	}

	if SupportsPrimaryWeaponSkill(in.WeaponSkillID) {
		return nil
	}

	return fmt.Errorf("unsupported weapon skill %s", in.WeaponSkillID)
}

// SupportsPrimaryWeaponSkill names the melee weapon families whose ordinary
// attacks and action delay are currently ported together.
func SupportsPrimaryWeaponSkill(id string) bool {
	switch id {
	case "SK_SHORT_BLADES", "SK_LONG_BLADES", "SK_MACES_FLAILS", "SK_AXES", "SK_POLEARMS":
		return true

	default:
		return false
	}
}

// PlayerMelee follows the supported C++ primary attack phases. Rat shields,
// auxiliary strikes, brands, and statuses beyond might are absent in this slice.
func PlayerMelee(r Roller, in PlayerAttackInput) (Outcome, error) {
	if r == nil {
		return Outcome{}, fmt.Errorf("player melee requires a roller")
	}

	if err := in.Validate(); err != nil {
		return Outcome{}, err
	}

	hit, err := playerHitRoll(r, in)

	if err != nil {
		return Outcome{}, err
	}

	if !hit {
		return Outcome{Kind: Miss}, nil
	}

	damage, err := playerDamageRoll(r, in)

	if err != nil {
		return Outcome{}, err
	}

	saved, err := playerArmourReduction(r, in.DefenderAC)

	if err != nil {
		return Outcome{}, err
	}

	return Outcome{
		Kind:   Hit,
		Damage: max(0, damage-saved),
	}, nil
}

func maybeRandomDiv(r Roller, numerator, denominator int) (int, error) {
	if numerator <= 0 {
		return 0, nil
	}

	roll, err := random2(r, numerator+denominator)

	return roll / denominator, err
}
