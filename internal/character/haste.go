package character

import "fmt"

const HasteCapAut = 400

// HastePotionDuration follows potion.cc and player.cc: the nominal potion
// turns are cut to two thirds before they are stored in aut, then capped.
func HastePotionDuration(roller Roller, currentAut int) (int, string, error) {
	if roller == nil ||
		currentAut < 0 || currentAut > HasteCapAut {
		return 0, "", fmt.Errorf("invalid haste duration %d", currentAut)
	}

	roll, err := roller.Intn("potion", 40)

	if err != nil {
		return 0, "", err
	}

	if roll < 0 || roll >= 40 {
		return 0, "", fmt.Errorf("haste potion roll %d outside [0,40)", roll)
	}

	turns, err := roundedTwoThirds(roller, "potion", 40+roll)

	if err != nil {
		return 0, "", err
	}

	message := "You feel yourself speed up."

	if currentAut > 0 {
		message = "You feel as though your hastened speed will last longer."
	}

	return min(HasteCapAut, currentAut+turns*10), message, nil
}

// PlayerActionTime evaluates player_speed for the supported unslowed Human.
// It is chosen once for an accepted command, before any quaff effect runs.
func PlayerActionTime(roller Roller, hasted bool) (int, error) {
	if !hasted {
		return 10, nil
	}

	return roundedTwoThirds(roller, "speed", 10)
}

func roundedTwoThirds(roller Roller, stream string, value int) (int, error) {
	if roller == nil || value < 0 {
		return 0, fmt.Errorf("cannot round haste value %d", value)
	}

	numerator := value * 2
	whole := numerator / 3
	remainder := numerator % 3

	if remainder == 0 {
		return whole, nil
	}

	roll, err := roller.Intn(stream, 3)

	if err != nil {
		return 0, err
	}

	if roll < 0 || roll >= 3 {
		return 0, fmt.Errorf("haste rounding roll %d outside [0,3)", roll)
	}

	if roll < remainder {
		return whole + 1, nil
	}

	return whole, nil
}

// DecayHaste follows player.cc:4616-4642. A timer that crosses zero during
// a long action remains truthy for one more action before the slowdown text.
func DecayHaste(roller Roller, currentAut, costAut int) (int, string, error) {
	if currentAut < 0 ||
		currentAut > HasteCapAut || costAut < 0 {
		return 0, "", fmt.Errorf("invalid haste decay %d by %d", currentAut, costAut)
	}

	if currentAut == 0 || costAut == 0 {
		return currentAut, "", nil
	}

	if currentAut <= 10 {
		return 0, "You feel yourself slow down.", nil
	}

	remaining := currentAut - costAut
	message := ""

	if currentAut > 60 && remaining <= 60 {
		message = "Your extra speed is starting to run out."

		if roller == nil {
			return 0, "", fmt.Errorf("haste warning requires a roller")
		}

		roll, err := roller.Intn("speed", 2)

		if err != nil {
			return 0, "", err
		}

		if roll < 0 || roll >= 2 {
			return 0, "", fmt.Errorf("haste warning roll %d outside [0,2)", roll)
		}

		if roll == 0 {
			remaining -= 10
		}
	}

	return max(1, remaining), message, nil
}
