package itemimport

import (
	"os"
	"path/filepath"
	"testing"
)

func TestPinnedItemSourceCoverage(t *testing.T) {
	root := os.Getenv("DCSS_SOURCE_DIR")

	if root == "" {
		t.Skip("optional pinned-source audit; normal tests use committed Go content")
	}

	source := map[string][]byte{}

	for _, name := range []string{
		"object-class-type.h",
		"item-prop-enum.h",
		"potion-type.h",
		"book-type.h",
		"orb-type.h",
		"item-prop.cc",
		"equipment-type.h",
		"skill-type.h",
		"size-type.h",
		"item-prop.h",
	} {
		data, err := os.ReadFile(filepath.Join(root, name))

		if err != nil {
			t.Fatal(err)
		}

		source[name] = data
	}

	identities, aliases, err := parseIdentities(source)

	if err != nil {
		t.Fatal(err)
	}

	removed, err := parseRemovedItems("crawl-ref/source/item-prop.cc", source["item-prop.cc"])

	if err != nil {
		t.Fatal(err)
	}

	vocabulary, err := parseVocabulary(source)

	if err != nil {
		t.Fatal(err)
	}

	counts := map[string]int{}

	for _, identity := range identities {
		counts[identity.ClassID]++
	}

	want := map[string]int{
		"OBJ_ARMOUR":     43,
		"OBJ_BOOKS":      78,
		"OBJ_CORPSES":    2,
		"OBJ_FOOD":       23,
		"OBJ_GOLD":       1,
		"OBJ_JEWELLERY":  37,
		"OBJ_MISCELLANY": 29,
		"OBJ_MISSILES":   10,
		"OBJ_ORBS":       1,
		"OBJ_POTIONS":    32,
		"OBJ_RODS":       10,
		"OBJ_RUNES":      19,
		"OBJ_SCROLLS":    28,
		"OBJ_STAVES":     13,
		"OBJ_WANDS":      25,
		"OBJ_WEAPONS":    57,
	}

	if len(identities) != 408 || len(aliases) != 10 || len(removed) != 84 || len(counts) != len(want) {
		t.Fatalf(
			"pinned identity partition changed: identities=%d aliases=%d removed=%d classes=%v",
			len(identities),
			len(aliases),
			len(removed),
			counts,
		)
	}

	for class, count := range want {
		if counts[class] != count {
			t.Errorf("%s: got %d identities, want %d", class, counts[class], count)
		}
	}

	if len(vocabulary.ArmourFlags) != 14 || len(vocabulary.DamageFlags) != 22 {
		t.Fatalf("pinned property vocabulary changed: %+v", vocabulary)
	}
}
