package character

import "fmt"

const MightCapAut = 800

// MightPotionDuration applies potion.cc's 35+random2(40) turns, capped at
// 80 turns. Duration is stored in aut and the quaff's aut is decayed later.
func MightPotionDuration(roller Roller, currentAut int) (int, string, error) {
	if roller == nil || currentAut < 0 || currentAut > MightCapAut {
		return 0, "", fmt.Errorf("invalid might duration %d", currentAut)
	}
	roll, err := roller.Intn("potion", 40)
	if err != nil {
		return 0, "", err
	}
	if roll < 0 || roll >= 40 {
		return 0, "", fmt.Errorf("potion roll %d outside [0,40)", roll)
	}
	message := "You feel very mighty all of a sudden."
	if currentAut > 0 {
		message = "You feel mightier all of a sudden."
	}
	return min(MightCapAut, currentAut+(35+roll)*10), message, nil
}

// DecayMight matches a normal duration's per-player-action aut decrement.
func DecayMight(currentAut, costAut int) (remaining int, ended bool, err error) {
	if currentAut < 0 || currentAut > MightCapAut || costAut < 0 {
		return 0, false, fmt.Errorf("invalid might decay %d by %d", currentAut, costAut)
	}
	if currentAut == 0 || costAut == 0 {
		return currentAut, false, nil
	}
	return max(0, currentAut-costAut), costAut >= currentAut, nil
}
