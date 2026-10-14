package character

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/mattn/go-runewidth"
)

// ValidateName follows the pinned console's ng-input.cc character and 30-column rules.
func ValidateName(name string) error {
	if strings.TrimSpace(name) == "" {
		return fmt.Errorf("player name is blank")
	}

	if runewidth.StringWidth(name) > 30 {
		return fmt.Errorf("player name exceeds 30 display columns")
	}

	hasAlphanumeric := false

	for _, r := range name {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			hasAlphanumeric = true
			continue
		}

		if r != '-' && r != '.' && r != '_' && r != ' ' {
			return fmt.Errorf("player name contains invalid character %q", r)
		}
	}

	if !hasAlphanumeric {
		return fmt.Errorf("player name has no letters or digits")
	}

	return nil
}
