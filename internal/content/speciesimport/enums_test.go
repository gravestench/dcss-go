package speciesimport

import (
	"strings"
	"testing"

	"dcrawl-go/internal/content/sourceparse"
)

func TestActiveEnumIDsTag34AndAliases(t *testing.T) {
	input := `enum species_type {
    SP_HUMAN,
#if TAG_MAJOR_VERSION == 34
    SP_HIGH_ELF,
#else
    SP_NEW_ELF,
#endif
#if TAG_MAJOR_VERSION > 34
    SP_FUTURE,
#endif
    SP_RED_DRACONIAN,
    SP_FIRST_NONBASE_DRACONIAN = SP_RED_DRACONIAN,
    NUM_SPECIES,
    SP_UNKNOWN = 100,
};`
	ids, err := sourceparse.ActiveEnumIDs("species-type.h", []byte(input), "SP_")
	if err != nil {
		t.Fatal(err)
	}
	for _, id := range []string{"SP_HUMAN", "SP_HIGH_ELF", "SP_RED_DRACONIAN"} {
		if _, found := ids[id]; !found {
			t.Fatalf("active ID %s missing", id)
		}
	}
	for _, id := range []string{"SP_NEW_ELF", "SP_FUTURE", "SP_FIRST_NONBASE_DRACONIAN", "SP_UNKNOWN"} {
		if _, found := ids[id]; found {
			t.Fatalf("inactive/alias/sentinel ID %s included", id)
		}
	}
}

func TestActiveEnumIDsRejectsUnsupportedConditional(t *testing.T) {
	_, err := sourceparse.ActiveEnumIDs("species-type.h", []byte("enum species_type {\n#if FEATURE_X\n SP_HUMAN,\n#endif\n};\n"), "SP_")
	if err == nil || !strings.Contains(err.Error(), "species-type.h") || !strings.Contains(err.Error(), "FEATURE_X") {
		t.Fatalf("unsupported condition accepted: %v", err)
	}
}
