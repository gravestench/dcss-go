package itemimport

import (
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func presentationIdentities() []content.ItemIdentity {
	return []content.ItemIdentity{
		{
			ID:      "WPN_MACE",
			ClassID: "OBJ_WEAPONS",
		},
		{
			ID:      "POT_CURING",
			ClassID: "OBJ_POTIONS",
		},
		{
			ID:      "BOOK_MINOR_MAGIC",
			ClassID: "OBJ_BOOKS",
		},
		{
			ID:      "BOOK_MANUAL",
			ClassID: "OBJ_BOOKS",
		},
		{
			ID:      "CORPSE_BODY",
			ClassID: "OBJ_CORPSES",
		},
		{
			ID:      "CORPSE_SKELETON",
			ClassID: "OBJ_CORPSES",
		},
		{
			ID:      "OBJ_GOLD",
			ClassID: "OBJ_GOLD",
		},
		{
			ID:      "ORB_ZOT",
			ClassID: "OBJ_ORBS",
		},
		{
			ID:      "RUNE_SWAMP",
			ClassID: "OBJ_RUNES",
		},
		{
			ID:      "RING_PROTECTION",
			ClassID: "OBJ_JEWELLERY",
		},
		{
			ID:      "AMU_FAITH",
			ClassID: "OBJ_JEWELLERY",
		},
		{
			ID:      "MISC_XOMS_CHESSBOARD",
			ClassID: "OBJ_MISCELLANY",
		},
		{
			ID:                "MISC_DECK_OF_ESCAPE",
			ClassID:           "OBJ_MISCELLANY",
			ExplicitlyRemoved: true,
		},
		{
			ID:      "STAFF_FIRE",
			ClassID: "OBJ_STAVES",
		},
		{
			ID:      "FOOD_RATION",
			ClassID: "OBJ_FOOD",
		},
		{
			ID:      "WAND_FLAME",
			ClassID: "OBJ_WANDS",
		},
		{
			ID:      "SCR_IDENTIFY",
			ClassID: "OBJ_SCROLLS",
		},
	}
}

func glyphIdentities() []content.ItemIdentity {
	var selected []content.ItemIdentity

	for _, identity := range presentationIdentities() {
		switch identity.ClassID {
		case "OBJ_WEAPONS", "OBJ_POTIONS", "OBJ_BOOKS", "OBJ_CORPSES", "OBJ_GOLD", "OBJ_ORBS", "OBJ_RUNES", "OBJ_JEWELLERY":
			selected = append(selected, identity)
		}
	}

	return selected
}

func presentationNameFixture() []byte {
	return []byte(`static const char* _wand_type_name(int type)
{
    switch (type) { case WAND_FLAME: return "flame"; }
}
const char* potion_type_name(int type)
{
    switch (type) { case POT_CURING: return "curing"; }
}
static const char* scroll_type_name(int type)
{
    switch (type) { case SCR_IDENTIFY: return "identify"; }
}
const char* jewellery_effect_name(int type, bool terse)
{
    if (!terse) {
        switch (type) {
        case RING_PROTECTION: return "protection";

        case AMU_FAITH: return "faith";
        }
    } else { return "short"; }
}
const char* rune_type_name(short type)
{
    switch (type) { case RUNE_SWAMP: return "decaying"; }
}
static string misc_type_name(int type)
{
    if (is_deck_type(type)) return "removed deck";
    switch (type) { case MISC_XOMS_CHESSBOARD: return "piece from Xom's chessboard"; }
}
static const char* _book_type_name(int type)
{
    switch (type) { case BOOK_MINOR_MAGIC: return "Minor Magic"; }
}
static const char* staff_type_name(int type)
{
    switch (type) { case STAFF_FIRE: return "fire"; }
}
string sub_type_string(const item_def &item, bool known)
{
    case BOOK_MANUAL:
        if (!known) return "manual";
        return "manual of " + skill_name(item.plus);

    case OBJ_ORBS: return "orb of Zot";

    case OBJ_CORPSES: return "corpse";

    case OBJ_GOLD: return "gold";
}

case OBJ_FOOD: return "removed food";
`)
}

func presentationGlyphFixture() (show, showHeader, dcharHeader, view []byte) {
	show = []byte(`static show_item_type _item_to_show_code(const item_def &item)
{
    switch (item.base_type) {
    case OBJ_ORBS: return SHOW_ITEM_ORB;

    case OBJ_WEAPONS: return SHOW_ITEM_WEAPON;

    case OBJ_POTIONS: return SHOW_ITEM_POTION;

    case OBJ_BOOKS: return SHOW_ITEM_BOOK;

    case OBJ_CORPSES:
        if (item.sub_type == CORPSE_SKELETON) return SHOW_ITEM_SKELETON;
        else return SHOW_ITEM_CORPSE;

    case OBJ_GOLD: return SHOW_ITEM_GOLD;

    case OBJ_RUNES: return SHOW_ITEM_RUNE;

    case OBJ_JEWELLERY:
        return jewellery_is_amulet(item) ? SHOW_ITEM_AMULET : SHOW_ITEM_RING;

    default: return SHOW_ITEM_ORB;
    }
}`)
	showHeader = []byte(`enum show_item_type
{
SHOW_ITEM_NONE,
SHOW_ITEM_ORB,
SHOW_ITEM_RUNE,
SHOW_ITEM_WEAPON,
SHOW_ITEM_RING,
SHOW_ITEM_POTION,
SHOW_ITEM_BOOK,
SHOW_ITEM_CORPSE,
SHOW_ITEM_SKELETON,
SHOW_ITEM_GOLD,
SHOW_ITEM_AMULET,
NUM_SHOW_ITEMS
};`)
	dcharHeader = []byte(`enum dungeon_char_type
{
DCHAR_WALL,
DCHAR_ITEM_ORB,
DCHAR_ITEM_RUNE,
DCHAR_ITEM_WEAPON,
DCHAR_ITEM_RING,
DCHAR_ITEM_POTION,
DCHAR_ITEM_BOOK,
DCHAR_ITEM_CORPSE,
DCHAR_ITEM_SKELETON,
DCHAR_ITEM_GOLD,
DCHAR_ITEM_AMULET,
NUM_DCHAR_TYPES
};`)
	view = []byte(`static const char32_t dchar_table[NUM_CSET][NUM_DCHAR_TYPES] =
{
    // CSET_ASCII
    { '#', '}', '{', ')', '=', '!', ':', '%', '%', '$', '"' }
};`)

	return
}

func TestPinnedItemNamesAndGlyphs(t *testing.T) {
	ids := presentationIdentities()
	names, err := parseItemNames("item-name.cc", presentationNameFixture(), ids)

	if err != nil {
		t.Fatal(err)
	}

	for key, want := range map[itemKey]string{
		{"OBJ_POTIONS", "POT_CURING"}:              "potion of curing",
		{"OBJ_BOOKS", "BOOK_MINOR_MAGIC"}:          "book of Minor Magic",
		{"OBJ_ORBS", "ORB_ZOT"}:                    "Orb of Zot",
		{"OBJ_GOLD", "OBJ_GOLD"}:                   "gold piece",
		{"OBJ_RUNES", "RUNE_SWAMP"}:                "decaying rune of Zot",
		{"OBJ_JEWELLERY", "RING_PROTECTION"}:       "ring of protection",
		{"OBJ_JEWELLERY", "AMU_FAITH"}:             "amulet of faith",
		{"OBJ_MISCELLANY", "MISC_XOMS_CHESSBOARD"}: "piece from Xom's chessboard",
		{"OBJ_MISCELLANY", "MISC_DECK_OF_ESCAPE"}:  "removed deck",
		{"OBJ_STAVES", "STAFF_FIRE"}:               "staff of fire",
		{"OBJ_WANDS", "WAND_FLAME"}:                "wand of flame",
		{"OBJ_SCROLLS", "SCR_IDENTIFY"}:            "scroll of identify",
	} {
		if names[key].Text != want || names[key].Kind != "static" || names[key].SourceLine <= 0 {
			t.Errorf("%v: got %+v, want %q", key, names[key], want)
		}
	}

	if manual := names[itemKey{
		ClassID:   "OBJ_BOOKS",
		SubtypeID: "BOOK_MANUAL",
	}]; manual.Kind != "manual_skill" || manual.Text != "manual" {
		t.Errorf("manual naming lost: %+v", manual)
	}

	if corpse := names[itemKey{
		ClassID:   "OBJ_CORPSES",
		SubtypeID: "CORPSE_BODY",
	}]; corpse.Kind != "corpse_monster" || corpse.Text != "corpse" {
		t.Errorf("corpse naming lost: %+v", corpse)
	}

	if _, found := names[itemKey{
		ClassID:   "OBJ_WEAPONS",
		SubtypeID: "WPN_MACE",
	}]; found {
		t.Fatal("property-table weapon name was invented in item-name.cc view")
	}

	show, showHeader, dcharHeader, view := presentationGlyphFixture()
	glyphs, err := parseASCIIItemGlyphs("show.cc", show, showHeader, dcharHeader, "viewchar.cc", view, glyphIdentities())

	if err != nil {
		t.Fatal(err)
	}

	for key, want := range map[itemKey]rune{
		{"OBJ_WEAPONS", "WPN_MACE"}:          ')',
		{"OBJ_POTIONS", "POT_CURING"}:        '!',
		{"OBJ_BOOKS", "BOOK_MANUAL"}:         ':',
		{"OBJ_CORPSES", "CORPSE_BODY"}:       '%',
		{"OBJ_CORPSES", "CORPSE_SKELETON"}:   '%',
		{"OBJ_GOLD", "OBJ_GOLD"}:             '$',
		{"OBJ_ORBS", "ORB_ZOT"}:              '}',
		{"OBJ_RUNES", "RUNE_SWAMP"}:          '{',
		{"OBJ_JEWELLERY", "RING_PROTECTION"}: '=',
		{"OBJ_JEWELLERY", "AMU_FAITH"}:       '"',
	} {
		if glyphs[key] != want {
			t.Errorf("%v: got %q, want %q", key, glyphs[key], want)
		}
	}
}

func TestDynamicNameAndSourceErrors(t *testing.T) {
	ids := presentationIdentities()
	bad := strings.Replace(
		string(presentationNameFixture()),
		`case POT_CURING: return "curing";`,
		`case POT_CURING: return "curing"; case POT_CURING: return "healing";`,
		1,
	)

	if _, err := parseItemNames("item-name.cc", []byte(bad), ids); err == nil ||
		!strings.Contains(err.Error(), "item-name.cc") {
		t.Fatalf("ambiguous source name accepted: %v", err)
	}

	bad = strings.Replace(
		string(presentationNameFixture()),
		`case POT_CURING: return "curing";`,
		`case POT_UNKNOWN: return "unknown";`,
		1,
	)

	if _, err := parseItemNames("item-name.cc", []byte(bad), ids); err == nil {
		t.Fatal("missing name for unremoved potion accepted")
	}

	bad = "#if OTHER_FLAG\n" + string(presentationNameFixture()) + "\n#endif\n"

	if _, err := parseItemNames("item-name.cc", []byte(bad), ids); err == nil {
		t.Fatal("unsupported conditional accepted")
	}

	show, showHeader, dcharHeader, view := presentationGlyphFixture()
	dcharHeader = []byte(strings.Replace(
		string(dcharHeader),
		"DCHAR_ITEM_RUNE,\nDCHAR_ITEM_WEAPON,",
		"DCHAR_ITEM_WEAPON,\nDCHAR_ITEM_RUNE,",
		1,
	))

	if _, err := parseASCIIItemGlyphs(
		"show.cc",
		show,
		showHeader,
		dcharHeader,
		"viewchar.cc",
		view,
		glyphIdentities(),
	); err == nil {
		t.Fatal("mismatched show/dchar ordering accepted")
	}

	show, showHeader, dcharHeader, view = presentationGlyphFixture()
	show = []byte(strings.Replace(string(show), "return SHOW_ITEM_POTION;", "return SHOW_ITEM_NOT_REAL;", 1))

	if _, err := parseASCIIItemGlyphs(
		"show.cc",
		show,
		showHeader,
		dcharHeader,
		"viewchar.cc",
		view,
		glyphIdentities(),
	); err == nil {
		t.Fatal("unknown show glyph reference accepted")
	}
}
