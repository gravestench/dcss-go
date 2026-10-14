package itemimport

import (
	"strings"
	"testing"
)

func identityFixture() map[string][]byte {
	return map[string][]byte{
		"object-class-type.h": []byte(`enum object_class_type : uint8_t
{
OBJ_WEAPONS,
OBJ_MISSILES,
OBJ_ARMOUR,
OBJ_WANDS,
#if TAG_MAJOR_VERSION == 34
OBJ_FOOD,
#endif
OBJ_SCROLLS,
OBJ_JEWELLERY,
OBJ_POTIONS,
OBJ_BOOKS,
OBJ_STAVES,
OBJ_ORBS,
OBJ_MISCELLANY,
OBJ_CORPSES,
OBJ_GOLD,
OBJ_RODS,
OBJ_RUNES,
NUM_OBJECT_CLASSES,
OBJ_UNASSIGNED = 100,
OBJ_RANDOM,
OBJ_DETECTED,
};`),
		"item-prop-enum.h": []byte(`enum weapon_type
{
WPN_CLUB,
WPN_ALIAS = WPN_CLUB,
WPN_DAGGER = 3,
NUM_WEAPONS,
WPN_UNARMED,
};
enum missile_type
{
MI_DART,
NUM_MISSILES,
MI_NONE,
};
enum armour_type
{
ARM_ROBE,
NUM_ARMOURS,
};
enum wand_type
{
WAND_FLAME,
NUM_WANDS,
};
enum food_type
{
FOOD_RATION,
NUM_FOODS,
};
enum scroll_type
{
SCR_IDENTIFY,
NUM_SCROLLS,
};
enum jewellery_type
{
RING_PROTECTION,
RING_FIRST_RING = RING_PROTECTION,
AMU_RAGE = 35,
NUM_JEWELLERY,
};
enum stave_type
{
STAFF_FIRE,
NUM_STAVES,
};
enum misc_item_type
{
MISC_BOX_OF_BEASTS,
NUM_MISCELLANY,
MISC_DECK_UNKNOWN = NUM_MISCELLANY,
};
enum corpse_type
{
CORPSE_BODY,
};
enum rod_type
{
ROD_LIGHTNING,
NUM_RODS,
};
enum rune_type
{
RUNE_SWAMP,
NUM_RUNE_TYPES,
};`),
		"potion-type.h": []byte("enum potion_type\n{\nPOT_CURING,\nNUM_POTIONS,\n};\n"),
		"book-type.h":   []byte("enum book_type\n{\nBOOK_MINOR_MAGIC,\nNUM_BOOKS,\n};\n"),
		"orb-type.h":    []byte("enum orb_type\n{\nORB_ZOT,\n};\n"),
	}
}

func TestItemIdentityEnums(t *testing.T) {
	identities, aliases, err := parseIdentities(identityFixture())
	if err != nil {
		t.Fatal(err)
	}
	if len(identities) != 18 {
		t.Fatalf("expected 18 concrete class/subtype identities, got %d", len(identities))
	}
	byID := map[string]int{}
	classes := map[string]int{}
	for _, identity := range identities {
		byID[identity.ID] = identity.SubtypeValue
		classes[identity.ClassID] = identity.ClassValue
	}
	if byID["WPN_CLUB"] != 0 || byID["WPN_DAGGER"] != 3 || byID["OBJ_GOLD"] != 0 || classes["OBJ_GOLD"] != 13 || len(classes) != 16 {
		t.Fatalf("wrong numeric identities: ids=%v classes=%v", byID, classes)
	}
	for _, pseudo := range []string{"WPN_ALIAS", "WPN_UNARMED", "MI_NONE", "MISC_DECK_UNKNOWN", "OBJ_RANDOM", "NUM_WEAPONS"} {
		if _, found := byID[pseudo]; found {
			t.Fatalf("pseudo/alias %s became a concrete identity", pseudo)
		}
	}
	if len(aliases) != 2 || aliases[0].ID != "RING_FIRST_RING" && aliases[1].ID != "RING_FIRST_RING" {
		t.Fatalf("alias exclusions missing: %+v", aliases)
	}
	if got := byID["CORPSE_BODY"]; got != 0 {
		t.Fatalf("corpse numeric value = %d", got)
	}
	if got := byID["ORB_ZOT"]; got != 0 {
		t.Fatalf("orb numeric value = %d", got)
	}
	bad := identityFixture()
	bad["item-prop-enum.h"] = []byte(strings.Replace(string(bad["item-prop-enum.h"]), "WPN_DAGGER = 3", "WPN_DAGGER = unknown()", 1))
	if _, _, err := parseIdentities(bad); err == nil || !strings.Contains(err.Error(), "item-prop-enum.h") {
		t.Fatalf("unsupported numeric expression was accepted: %v", err)
	}
	bad = identityFixture()
	bad["item-prop-enum.h"] = []byte(strings.Replace(string(bad["item-prop-enum.h"]), "WPN_DAGGER = 3", "WPN_DAGGER = 0", 1))
	if _, _, err := parseIdentities(bad); err == nil {
		t.Fatal("duplicate numeric class/subtype pair was accepted")
	}
}

func TestRemovedItemsIndependent(t *testing.T) {
	source := []byte(`const set<pair<object_class_type, int> > removed_items =
{
#if TAG_MAJOR_VERSION == 34
    { OBJ_POTIONS, POT_OLD },
#endif
    { OBJ_BOOKS, BOOK_OLD },
};
// A property row named "removed potion" does not enter this set.
`)
	removed, err := parseRemovedItems("item-prop.cc", source)
	if err != nil {
		t.Fatal(err)
	}
	if len(removed) != 2 || !removed[itemKey{
		"OBJ_POTIONS",
		"POT_OLD",
	}] || !removed[itemKey{
		"OBJ_BOOKS",
		"BOOK_OLD",
	}] || removed[itemKey{
		"OBJ_POTIONS",
		"POT_OTHER",
	}] {
		t.Fatalf("wrong explicit removal set: %v", removed)
	}
	duplicate := []byte(strings.Replace(string(source), "{ OBJ_BOOKS, BOOK_OLD },", "{ OBJ_POTIONS, POT_OLD },", 1))
	if _, err := parseRemovedItems("item-prop.cc", duplicate); err == nil {
		t.Fatal("duplicate explicit removal accepted")
	}
	malformed := []byte(strings.Replace(string(source), "#if TAG_MAJOR_VERSION == 34", "#if OTHER_FLAG", 1))
	if _, err := parseRemovedItems("item-prop.cc", malformed); err == nil || !strings.Contains(err.Error(), "item-prop.cc") {
		t.Fatalf("unsupported conditional was accepted: %v", err)
	}
}

func TestItemVocabularyAcceptsSymbolicBitExpressions(t *testing.T) {
	source := map[string][]byte{
		"equipment-type.h": []byte("enum equipment_type\n{\nEQ_BODY_ARMOUR,\n};\n"),
		"skill-type.h":     []byte("enum skill_type\n{\nSK_FIGHTING,\n};\n"),
		"size-type.h":      []byte("enum size_type\n{\nSIZE_LITTLE,\n};\n"),
		"item-prop-enum.h": []byte(`enum missile_type
{
MI_DART,
MI_NONE,
};
enum vorpal_damage_type
{
DAM_PIERCE = 0x0004,
DAMV_PIERCING = 0x3000 | DAM_PIERCE,
};
enum brand_type
{
SPWPN_NORMAL,
};`),
		"item-prop.h": []byte(`enum armour_flag
{
ARMF_RES_FIRE = 1 << 0,
ARMF_VUL_FIRE = ard(ARMF_RES_FIRE, -1),
};`),
	}
	v, err := parseVocabulary(source)
	if err != nil {
		t.Fatal(err)
	}
	if len(v.ArmourFlags) != 2 || v.ArmourFlags[0] != "ARMF_RES_FIRE" || v.ArmourFlags[1] != "ARMF_VUL_FIRE" || len(v.DamageFlags) != 2 || v.DamageFlags[0] != "DAMV_PIERCING" || v.DamageFlags[1] != "DAM_PIERCE" {
		t.Fatalf("symbolic vocabulary was lost: %+v", v)
	}
}
