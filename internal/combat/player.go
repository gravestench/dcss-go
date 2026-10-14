package combat

import "fmt"

// PlayerAttackInput is the ordinary Human Fighter primary attack projected
// from live character state, one equipped weapon, and the current defender.
type PlayerAttackInput struct {
	Strength, Dexterity                 int
	FightingSkill100, WeaponSkill100    int
	UnarmedSkill256                     int
	WeaponSkillID                       string
	WeaponDamage, WeaponHit, WeaponPlus int
	Unarmed                             bool
	DefenderEV, DefenderAC              int
}

// Validate rejects inputs outside the supported Human Fighter scenario.
func (in PlayerAttackInput) Validate() error {
	if in.Strength <= 0 || in.Dexterity < 0 || in.FightingSkill100 < 0 || in.WeaponSkill100 < 0 ||
		in.UnarmedSkill256 < 0 || in.DefenderEV < 0 || in.DefenderAC < 0 ||
		in.WeaponPlus < -100 || in.WeaponPlus > 100 {
		return fmt.Errorf("invalid Human Fighter attack %+v", in)
	}
	if in.Unarmed {
		if in.WeaponSkillID != "SK_UNARMED_COMBAT" || in.WeaponDamage != 0 || in.WeaponHit != 0 || in.WeaponPlus != 0 {
			return fmt.Errorf("invalid unarmed attack %+v", in)
		}
		return nil
	}
	if in.WeaponDamage <= 0 || in.UnarmedSkill256 != 0 {
		return fmt.Errorf("invalid equipped weapon attack %+v", in)
	}
	switch in.WeaponSkillID {
	case "SK_SHORT_BLADES", "SK_LONG_BLADES", "SK_MACES_FLAILS", "SK_AXES", "SK_POLEARMS":
		return nil
	default:
		return fmt.Errorf("unsupported weapon skill %s", in.WeaponSkillID)
	}
}

// PlayerMelee follows the supported C++ primary attack phases. Rat shields,
// status effects, auxiliary strikes, and brands are absent in this slice.
func PlayerMelee(r Roller, in PlayerAttackInput) (Outcome, error) {
	if r == nil {
		return Outcome{}, fmt.Errorf("player melee requires a roller")
	}
	if err := in.Validate(); err != nil {
		return Outcome{}, err
	}
	fighting, err := maybeRandomDiv(r, in.FightingSkill100, 100)
	if err != nil {
		return Outcome{}, err
	}
	weaponSkill, err := maybeRandomDiv(r, in.WeaponSkill100, 100)
	if err != nil {
		return Outcome{}, err
	}
	toHitBase := 15 + in.Dexterity/2 + fighting + weaponSkill
	if in.Unarmed {
		toHitBase += 2
	} else {
		toHitBase += in.WeaponHit + in.WeaponPlus
	}
	toHit, err := random2(r, toHitBase)
	if err != nil {
		return Outcome{}, err
	}
	autoChance, err := random2(r, 100)
	if err != nil {
		return Outcome{}, err
	}
	autoMiss, autoHit := false, false
	if autoChance < 5 {
		coin, coinErr := random2(r, 2)
		if coinErr != nil {
			return Outcome{}, coinErr
		}
		autoMiss, autoHit = coin == 0, coin != 0
	}
	// attack_shield_blocked still draws the bypass roll for a shieldless rat.
	if _, err := random2(r, 15+toHit/2); err != nil {
		return Outcome{}, err
	}
	if autoMiss || (!autoHit && toHit < in.DefenderEV) {
		return Outcome{Kind: Miss}, nil
	}

	potential := in.WeaponDamage
	if in.Unarmed {
		potential = 3 + in.UnarmedSkill256/256
		if rem := in.UnarmedSkill256 % 256; rem != 0 {
			roll, rollErr := random2(r, 256)
			if rollErr != nil {
				return Outcome{}, rollErr
			}
			if roll < rem {
				potential++
			}
		}
	}
	stat := in.Strength
	if !in.Unarmed && (in.WeaponSkillID == "SK_SHORT_BLADES" || in.WeaponSkillID == "SK_LONG_BLADES") {
		stat = in.Dexterity
	}
	potential = potential * max(2, 150+5*stat) / 2 / 100
	damage, err := random2(r, potential+1)
	if err != nil {
		return Outcome{}, err
	}
	if !in.Unarmed {
		bonus, bonusErr := random2(r, in.WeaponSkill100+1)
		if bonusErr != nil {
			return Outcome{}, bonusErr
		}
		damage = damage * (2500 + bonus) / 2500
	}
	fightingBonus, err := random2(r, in.FightingSkill100+1)
	if err != nil {
		return Outcome{}, err
	}
	damage = damage * (3000 + fightingBonus) / 3000
	if in.WeaponPlus >= 0 {
		bonus, bonusErr := random2(r, 1+in.WeaponPlus)
		if bonusErr != nil {
			return Outcome{}, bonusErr
		}
		damage += bonus
	} else {
		penalty, penaltyErr := random2(r, 1-in.WeaponPlus)
		if penaltyErr != nil {
			return Outcome{}, penaltyErr
		}
		damage -= penalty
	}
	saved, err := random2(r, in.DefenderAC+1)
	if err != nil {
		return Outcome{}, err
	}
	// actor::apply_ac evaluates div_rand_round(AC,2) even with zero GDR.
	if in.DefenderAC%2 != 0 {
		if _, err := random2(r, 2); err != nil {
			return Outcome{}, err
		}
	}
	return Outcome{Kind: Hit, Damage: max(0, damage-saved)}, nil
}

func maybeRandomDiv(r Roller, numerator, denominator int) (int, error) {
	if numerator <= 0 {
		return 0, nil
	}
	roll, err := random2(r, numerator+denominator)
	return roll / denominator, err
}
