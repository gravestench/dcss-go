package character

import (
	"strings"
	"testing"
)

func TestValidateNameUsesSourceCharactersAndDisplayWidth(t *testing.T) {
	for _, name := range []string{"Alice", "A.B-C_D 9", strings.Repeat("界", 15)} {
		if err := ValidateName(name); err != nil {
			t.Fatalf("valid name %q: %v", name, err)
		}
	}

	for _, name := range []string{
		"",
		"   ",
		"Bad!",
		"Bad/name",
		strings.Repeat("界", 16),
		strings.Repeat("a", 31),
	} {
		if err := ValidateName(name); err == nil {
			t.Fatalf("invalid name %q accepted", name)
		}
	}
}
