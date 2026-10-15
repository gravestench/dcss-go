package terminal

func menuLetter(index int) rune {
	if index < 26 {
		return rune('a' + index)
	}

	return rune('A' + index - 26)
}
