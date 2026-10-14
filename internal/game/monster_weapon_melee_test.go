package game

// Maximum rolls make the weapon's added damage observable after Fighter AC.
type maximumMeleeRoller struct{}

func (maximumMeleeRoller) Intn(stream string, bound int) (int, error) {
	if stream != "melee" || bound < 1 {
		return 0, errUnexpectedMeleeRoll(stream, bound)
	}

	return bound - 1, nil
}
