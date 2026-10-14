package combat

func playerHitRoll(r Roller, in PlayerAttackInput) (bool, error) {
	fighting, err := maybeRandomDiv(r, in.FightingSkill100, 100)

	if err != nil {
		return false, err
	}

	weaponSkill, err := maybeRandomDiv(r, in.WeaponSkill100, 100)

	if err != nil {
		return false, err
	}

	toHitBase := 15 + in.Dexterity/2 + fighting + weaponSkill

	if in.Unarmed {
		toHitBase += 2
	} else {
		toHitBase += in.WeaponHit + in.WeaponPlus
	}

	toHit, err := random2(r, toHitBase)

	if err != nil {
		return false, err
	}

	autoChance, err := random2(r, 100)

	if err != nil {
		return false, err
	}

	autoMiss, autoHit := false, false

	if autoChance < 5 {
		coin, coinErr := random2(r, 2)

		if coinErr != nil {
			return false, coinErr
		}

		autoMiss, autoHit = coin == 0, coin != 0
	}

	// attack_shield_blocked still draws the bypass roll for a shieldless rat.
	if _, err := random2(r, 15+toHit/2); err != nil {
		return false, err
	}

	return !autoMiss && (autoHit || toHit >= in.DefenderEV), nil
}

func playerDamageRoll(r Roller, in PlayerAttackInput) (int, error) {
	potential, err := playerBasePotential(r, in)

	if err != nil {
		return 0, err
	}

	stat := in.Strength

	if !in.Unarmed &&
		(in.WeaponSkillID == "SK_SHORT_BLADES" ||
			in.WeaponSkillID == "SK_LONG_BLADES") {
		stat = in.Dexterity
	}

	potential = potential * max(2, 150+5*stat) / 2 / 100
	damage, err := random2(r, potential+1)

	if err != nil {
		return 0, err
	}

	if !in.Unarmed {
		bonus, bonusErr := random2(r, in.WeaponSkill100+1)

		if bonusErr != nil {
			return 0, bonusErr
		}

		damage = damage * (2500 + bonus) / 2500
	}

	fightingBonus, err := random2(r, in.FightingSkill100+1)

	if err != nil {
		return 0, err
	}

	damage = damage * (3000 + fightingBonus) / 3000

	if in.Mighty {
		bonus, bonusErr := random2(r, 10)

		if bonusErr != nil {
			return 0, bonusErr
		}

		damage += 1 + bonus
	}

	if in.WeaponPlus >= 0 {
		bonus, bonusErr := random2(r, 1+in.WeaponPlus)

		if bonusErr != nil {
			return 0, bonusErr
		}

		damage += bonus
	} else {
		penalty, penaltyErr := random2(r, 1-in.WeaponPlus)

		if penaltyErr != nil {
			return 0, penaltyErr
		}

		damage -= penalty
	}

	return damage, nil
}

func playerBasePotential(r Roller, in PlayerAttackInput) (int, error) {
	potential := in.WeaponDamage

	if !in.Unarmed {
		return potential, nil
	}

	potential = 3 + in.UnarmedSkill256/256

	if rem := in.UnarmedSkill256 % 256; rem != 0 {
		roll, rollErr := random2(r, 256)

		if rollErr != nil {
			return 0, rollErr
		}

		if roll < rem {
			potential++
		}
	}

	return potential, nil
}

func playerArmourReduction(r Roller, ac int) (int, error) {
	saved, err := random2(r, ac+1)

	if err != nil {
		return 0, err
	}

	// actor::apply_ac evaluates div_rand_round(AC,2) even with zero GDR.
	if ac%2 != 0 {
		if _, err := random2(r, 2); err != nil {
			return 0, err
		}
	}

	return saved, nil
}
