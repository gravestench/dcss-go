package combat

import "fmt"

// ConstrictDamage follows the monster's direct constriction damage phase.
// The current supported constrictor has no duration bonus.
func ConstrictDamage(r Roller, baseDamage, defenderAC, attackerSpeed int) (int, error) {
	if r == nil ||
		baseDamage <= 0 ||
		defenderAC < 0 ||
		attackerSpeed <= 0 {
		return 0, fmt.Errorf("invalid constriction damage inputs")
	}

	armourRoll, err := random2(r, 1+defenderAC/2)

	if err != nil {
		return 0, err
	}

	damage := max(0, baseDamage-armourRoll)

	return randomDivideRound(r, damage*10, attackerSpeed)
}

// RollConstrictEscape evaluates the source's growing movement escape test.
// attempts includes the current attempt; the caller retains it after failure.
func RollConstrictEscape(r Roller, attempts, attackerHD int) (bool, error) {
	if r == nil ||
		attempts < 1 ||
		attempts > 1000 ||
		attackerHD < 1 {
		return false, fmt.Errorf("invalid constriction escape inputs")
	}

	escapeScore, err := rollDice(r, 4+attempts, 13)

	if err != nil {
		return false, err
	}

	hdQuarter, err := randomDivideRound(r, attackerHD, 4)

	if err != nil {
		return false, err
	}

	gripScore, err := rollDice(r, 5, 8+hdQuarter)

	if err != nil {
		return false, err
	}

	return escapeScore >= gripScore, nil
}

func rollDice(r Roller, count, sides int) (int, error) {
	total := 0

	for i := 0; i < count; i++ {
		roll, err := random2(r, sides)

		if err != nil {
			return 0, err
		}

		total += roll + 1
	}

	return total, nil
}

func randomDivideRound(r Roller, numerator, denominator int) (int, error) {
	if denominator <= 0 || numerator < 0 {
		return 0, fmt.Errorf("invalid random division %d/%d", numerator, denominator)
	}

	quotient := numerator / denominator
	remainder := numerator % denominator

	if remainder == 0 {
		return quotient, nil
	}

	roll, err := random2(r, denominator)

	if err != nil {
		return 0, err
	}

	if roll < remainder {
		quotient++
	}

	return quotient, nil
}
