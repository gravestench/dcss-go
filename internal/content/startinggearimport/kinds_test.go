package startinggearimport

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func kindSourceFixture(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	files := map[string]string{
		"item-prop-enum.h": `enum armour_type {
 ARM_SCALE_MAIL,
};
enum missile_type {
 MI_DART,
};
enum scroll_type {
 SCR_MAGIC_MAPPING,
};
enum misc_item_type {
 MISC_XOMS_CHESSBOARD,
};
enum weapon_type {
 WPN_FLAIL,
};
enum wand_type {
 WAND_CHARMING,
};
`,
		"potion-type.h": `enum potion_type {
 POT_MIGHT,
};
`,
		"item-prop.cc": `static const armour_def Armour_prop[] = {
 { ARM_SCALE_MAIL, "scale mail", 6, -100, 40,
   EQ_BODY_ARMOUR, SIZE_SMALL, SIZE_MEDIUM, true },
};
static const weapon_def Weapon_prop[] = {
 { WPN_FLAIL, "flail", 10, 0, 14,
   SK_MACES_FLAILS, SIZE_LITTLE, SIZE_LITTLE, MI_NONE },
};
static const missile_def Missile_prop[] = {
 { MI_DART, "dart", 0, 12, 2 },
};
`,
		"item-name.cc": `static const char* _wand_type_name(int wandtype) {
case POT_MIGHT: return "might";
case SCR_MAGIC_MAPPING: return "magic mapping";
case WAND_CHARMING: return "charming";
case MISC_XOMS_CHESSBOARD: return "piece from Xom's chessboard";
}
static const char* _book_type_name(int booktype) {
`,
	}
	for name, source := range files {
		if err := os.WriteFile(filepath.Join(root, name), []byte(source), 0644); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

func alterKindSource(t *testing.T, root, name, old, replacement string) {
	t.Helper()
	path := filepath.Join(root, name)
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), old) {
		t.Fatalf("%s lacks %q", path, old)
	}
	if err := os.WriteFile(path, []byte(strings.Replace(string(data), old, replacement, 1)), 0644); err != nil {
		t.Fatal(err)
	}
}

func TestResolveKinds(t *testing.T) {
	root := kindSourceFixture(t)
	names := []string{"scale mail", "flail", "dart", "potion of might", "scroll of magic mapping", "wand of charming", "piece from Xom's chessboard"}
	kinds, err := resolveKinds(root, names)
	if err != nil {
		t.Fatal(err)
	}
	if len(kinds) != len(names) {
		t.Fatalf("got %d kinds, want %d", len(kinds), len(names))
	}
	byName := map[string]string{}
	for _, kind := range kinds {
		byName[kind.Name] = kind.ID
	}
	artifact := content.StartingGearArtifact{SchemaVersion: 1, SourceRevision: "fixture", TagMajorVersion: 34, Kinds: kinds}
	if err := artifact.Validate(); err != nil {
		t.Fatalf("resolved kinds are invalid: %v", err)
	}
	for name, id := range map[string]string{
		"scale mail": "ARM_SCALE_MAIL", "flail": "WPN_FLAIL", "dart": "MI_DART",
		"potion of might": "POT_MIGHT", "scroll of magic mapping": "SCR_MAGIC_MAPPING",
		"wand of charming": "WAND_CHARMING", "piece from Xom's chessboard": "MISC_XOMS_CHESSBOARD",
	} {
		if byName[name] != id {
			t.Fatalf("%q resolved to %q, want %q", name, byName[name], id)
		}
	}
	for _, kind := range kinds {
		if kind.ID == "WPN_FLAIL" && (kind.WeaponSkill != "SK_MACES_FLAILS" || kind.Slot != "weapon") {
			t.Fatalf("weapon properties missing: %+v", kind)
		}
		if kind.ID == "ARM_SCALE_MAIL" && kind.Slot != "body" {
			t.Fatalf("armour slot missing: %+v", kind)
		}
	}
}

func TestResolveKindsRejectsInactiveOrAmbiguousName(t *testing.T) {
	for _, tc := range []struct {
		name, file, old, replacement, requested, want string
	}{
		{"future item", "item-prop-enum.h", " WAND_CHARMING,", "#if TAG_MAJOR_VERSION > 34\n WAND_CHARMING,\n#endif", "wand of charming", "WAND_CHARMING"},
		{"else item", "item-prop-enum.h", " WAND_CHARMING,", "#if TAG_MAJOR_VERSION == 34\n WAND_OTHER,\n#else\n WAND_CHARMING,\n#endif", "wand of charming", "WAND_CHARMING"},
		{"inactive enum", "item-prop-enum.h", " WPN_FLAIL,", " WPN_OTHER,", "flail", "WPN_FLAIL"},
		{"duplicate name", "item-prop.cc", `{ MI_DART, "dart", 0, 12, 2 },`, `{ MI_DART, "flail", 0, 12, 2 },`, "flail", "flail"},
		{"unknown name", "item-prop.cc", `{ MI_DART, "dart", 0, 12, 2 },`, `{ MI_DART, "dart", 0, 12, 2 },`, "unknown item", "unknown item"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			root := kindSourceFixture(t)
			alterKindSource(t, root, tc.file, tc.old, tc.replacement)
			_, err := resolveKinds(root, []string{tc.requested})
			if err == nil || !strings.Contains(err.Error(), tc.want) || !strings.Contains(err.Error(), tc.file) {
				t.Fatalf("want %s and %s in error, got %v", tc.want, tc.file, err)
			}
		})
	}
}

func TestResolveKindsIgnoresUnrequestedFutureRows(t *testing.T) {
	root := kindSourceFixture(t)
	alterKindSource(t, root, "item-prop.cc", `{ MI_DART, "dart", 0, 12, 2 },`, `{ MI_DART, "dart", 0, 12, 2 },
 { MI_FUTURE, "future missile", 0, 12, 2 },`)
	kinds, err := resolveKinds(root, []string{"flail"})
	if err != nil {
		t.Fatal(err)
	}
	if len(kinds) != 1 || kinds[0].ID != "WPN_FLAIL" {
		t.Fatalf("unrequested row affected resolution: %+v", kinds)
	}
}
