package game

import (
	"dcrawl-go/internal/combat"
)

// These practice rolls follow exercise.cc for the combat actions currently
// implemented by the Go port. The events are consumed after death resolution.
func (s *combatSystem) practicePlayerHit(
	attack combat.PlayerAttackInput,
	defenderID string,
) error {
	if attack.Unarmed {
		s.turn.Practice = append(s.turn.Practice, "SK_UNARMED_COMBAT")

		return nil
	}

	practice, err := s.skillChance(attack.WeaponDamage, 20)

	if err != nil || !practice {
		return err
	}

	delay, err := s.fighter.attackDelayInput(defenderID)

	if err != nil {
		return err
	}

	minimumSkill := combat.WeaponMinDelaySkill(
		delay.WeaponSpeed,
		attack.WeaponSkillID,
	)
	currentSkill := attack.WeaponSkill100 / 100
	degree := 0

	if currentSkill >= minimumSkill {
		practice, err = s.skillChance(1, 2)

		if err != nil {
			return err
		}

		if practice {
			degree = 1
		}
	} else {
		degree = 1

		if minimumSkill > 0 {
			bonus, roundErr := s.skillRandomRound(
				2*(minimumSkill-currentSkill),
				minimumSkill,
			)

			if roundErr != nil {
				return roundErr
			}

			degree += bonus
		}
	}

	for i := 0; i < degree; i++ {
		s.turn.Practice = append(s.turn.Practice, attack.WeaponSkillID)
	}

	practiceFighting, err := s.skillChance(1, 2)

	if err != nil {
		return err
	}

	if practiceFighting {
		s.turn.Practice = append(s.turn.Practice, "SK_FIGHTING")
	}

	return nil
}

func (s *combatSystem) practiceAnimalAttack(
	outcome combat.Outcome,
	defense combat.Defense,
) error {
	armourMass := max(0, 42*(-defense.BodyEV/10)-13)

	if err := s.practiceIncomingDodge(armourMass); err != nil {
		return err
	}

	if err := s.practiceIncomingShield(outcome, defense); err != nil {
		return err
	}

	if outcome.Kind != combat.Hit {
		return nil
	}

	return s.practiceIncomingHit(armourMass)
}

func (s *combatSystem) practiceIncomingDodge(armourMass int) error {
	practiceDodge, err := s.skillChance(1, 6)

	if err != nil {
		return err
	}

	if !practiceDodge {
		return nil
	}

	blocked, err := s.skillChance(armourMass, 800)

	if err != nil {
		return err
	}

	if !blocked {
		s.turn.Practice = append(s.turn.Practice, "SK_DODGING")
	}

	return nil
}

func (s *combatSystem) practiceIncomingShield(
	outcome combat.Outcome,
	defense combat.Defense,
) error {
	if defense.ShieldClass <= 0 {
		return nil
	}

	denominator := 6

	if outcome.Kind == combat.Block {
		denominator = 2
	}

	practiceShield, err := s.skillChance(1, denominator)

	if err != nil {
		return err
	}

	if practiceShield {
		s.turn.Practice = append(s.turn.Practice, "SK_SHIELDS")
	}

	return nil
}

func (s *combatSystem) practiceIncomingHit(armourMass int) error {
	practiceArmour, err := s.skillChance(1, 2)

	if err != nil {
		return err
	}

	if practiceArmour {
		currentArmour := s.fighter.skillLevel("SK_ARMOUR")
		trainArmour, err := s.skillChance(armourMass-100, currentArmour*50)

		if err != nil {
			return err
		}

		if trainArmour {
			degree, err := s.rng.Intn("skill", 2)

			if err != nil {
				return err
			}

			for i := 0; i < degree+1; i++ {
				s.turn.Practice = append(s.turn.Practice, "SK_ARMOUR")
			}
		}

		return nil
	}

	practiceFighting, err := s.skillChance(1, 2)

	if err != nil {
		return err
	}

	if practiceFighting {
		s.turn.Practice = append(s.turn.Practice, "SK_FIGHTING")
	}

	return nil
}

func (s *combatSystem) skillChance(numerator, denominator int) (bool, error) {
	if numerator <= 0 {
		return false, nil
	}

	if denominator <= 0 || numerator >= denominator {
		return true, nil
	}

	roll, err := s.rng.Intn("skill", denominator)

	return roll < numerator, err
}

func (s *combatSystem) skillRandomRound(numerator, denominator int) (int, error) {
	whole := numerator / denominator
	remainder := numerator % denominator
	roll, err := s.rng.Intn("skill", denominator)

	if err != nil {
		return 0, err
	}

	if roll < remainder {
		whole++
	}

	return whole, nil
}
