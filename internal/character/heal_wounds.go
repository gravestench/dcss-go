package character

import "fmt"

// HealWoundsHP follows potion.cc's ordinary Human healing: 10 plus
// random2avg(28, 3). The caller checks can_quaff before spending time.
func HealWoundsHP(roller Roller, current, maximum int) (int, error) {
	if roller == nil || maximum <= 0 || current <= 0 || current > maximum {
		return 0, fmt.Errorf("invalid heal wounds HP %d/%d", current, maximum)
	}

	total := 0
	for i, bound := range []int{28, 29, 29} {
		roll, err := roller.Intn("potion", bound)
		if err != nil {
			return 0, err
		}

		if roll < 0 || roll >= bound {
			return 0, fmt.Errorf("heal wounds roll %d is outside [0,%d) at draw %d", roll, bound, i+1)
		}

		total += roll
	}

	return min(maximum, current+10+total/3), nil
}
