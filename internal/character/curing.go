package character

import "fmt"

// CuringHP applies the ordinary Human potion of curing effect from
// potion.cc:103-112. The default healing factor is 2/2, so the amount is
// 5 + random2(7). The potion still draws when HP is already full.
func CuringHP(roller Roller, current, maximum int) (int, error) {
	if roller == nil || maximum <= 0 || current <= 0 || current > maximum {
		return 0, fmt.Errorf("invalid curing HP %d/%d", current, maximum)
	}

	roll, err := roller.Intn("potion", 7)

	if err != nil {
		return 0, err
	}

	if roll < 0 || roll >= 7 {
		return 0, fmt.Errorf("potion roll %d outside [0,7)", roll)
	}

	return min(maximum, current+5+roll), nil
}
