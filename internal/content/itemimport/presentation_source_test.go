package itemimport

import (
	"os"
	"path/filepath"
	"testing"
)

func TestPinnedItemPresentationCoverage(t *testing.T) {
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
		"item-name.cc",
		"show.cc",
		"show.h",
		"dungeon-char-type.h",
		"viewchar.cc",
	} {
		data, err := os.ReadFile(filepath.Join(root, name))
		if err != nil {
			t.Fatal(err)
		}
		source[name] = data
	}
	identities, _, err := parseIdentities(source)
	if err != nil {
		t.Fatal(err)
	}
	removed, err := parseRemovedItems("crawl-ref/source/item-prop.cc", source["item-prop.cc"])
	if err != nil {
		t.Fatal(err)
	}
	for i := range identities {
		identities[i].ExplicitlyRemoved = removed[itemKey{
			ClassID:   identities[i].ClassID,
			SubtypeID: identities[i].ID,
		}]
	}
	names, err := parseItemNames("crawl-ref/source/item-name.cc", source["item-name.cc"], identities)
	if err != nil {
		t.Fatal(err)
	}
	missing := map[string][]string{}
	for _, identity := range identities {
		if _, found := names[itemKey{
			ClassID:   identity.ClassID,
			SubtypeID: identity.ID,
		}]; !found {
			missing[identity.ClassID] = append(missing[identity.ClassID], identity.ID)
			if identity.ClassID != "OBJ_ARMOUR" && identity.ClassID != "OBJ_WEAPONS" &&
				identity.ClassID != "OBJ_MISSILES" && !identity.ExplicitlyRemoved {
				t.Errorf("active item %s has no source name", identity.ID)
			}
		}
	}
	if len(names) != 258 {
		t.Fatalf("item-name.cc naming coverage: got %d, want 258; missing=%v", len(names), missing)
	}
	glyphs, err := parseASCIIItemGlyphs(
		"crawl-ref/source/show.cc",
		source["show.cc"],
		source["show.h"],
		source["dungeon-char-type.h"],
		"crawl-ref/source/viewchar.cc",
		source["viewchar.cc"],
		identities,
	)
	if err != nil {
		t.Fatal(err)
	}
	if len(glyphs) != 408 {
		t.Fatalf("glyph coverage: got %d, want 408", len(glyphs))
	}
	for key, want := range map[itemKey]string{
		{"OBJ_POTIONS", "POT_CURING"}:  "potion of curing",
		{"OBJ_BOOKS", "BOOK_MANUAL"}:   "manual",
		{"OBJ_ORBS", "ORB_ZOT"}:        "Orb of Zot",
		{"OBJ_GOLD", "OBJ_GOLD"}:       "gold piece",
		{"OBJ_JEWELLERY", "AMU_FAITH"}: "amulet of faith",
		{"OBJ_RUNES", "RUNE_SWAMP"}:    "decaying rune of Zot",
	} {
		if names[key].Text != want {
			t.Errorf("%v: got %+v, want %q", key, names[key], want)
		}
	}
	for key, want := range map[itemKey]rune{
		{"OBJ_POTIONS", "POT_CURING"}:      '!',
		{"OBJ_WEAPONS", "WPN_MACE"}:        ')',
		{"OBJ_BOOKS", "BOOK_MANUAL"}:       ':',
		{"OBJ_JEWELLERY", "AMU_FAITH"}:     '"',
		{"OBJ_CORPSES", "CORPSE_SKELETON"}: '%',
	} {
		if glyphs[key] != want {
			t.Errorf("%v: got %q, want %q", key, glyphs[key], want)
		}
	}
}
