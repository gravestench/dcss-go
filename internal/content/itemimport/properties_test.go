package itemimport

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func propertyFixture() []byte {
	return []byte(`static const armour_def Armour_prop[] =
{
    { ARM_ROBE, "robe", 2, 0, 7, EQ_BODY_ARMOUR, SIZE_LITTLE, SIZE_LARGE, true, ARMF_NO_FLAGS, 1000 },
    DRAGON_ARMOUR(FIRE, "fire", 8, -110, 600, ard(ARMF_RES_FIRE, 2) | ARMF_VUL_COLD),
};
static const vector<brand_weight_tuple> M_AND_F_BRANDS = {
    { SPWPN_NORMAL, 58 },
    { SPWPN_VENOM, 16 },
};
static const weapon_def Weapon_prop[] =
{
    { WPN_MACE, "mace", 8, 3, 14, SK_MACES_FLAILS, SIZE_LITTLE, ` +
		`SIZE_LITTLE, MI_NONE, DAMV_CRUSHING, 9, 10, 30, M_AND_F_BRANDS },
};
static const missile_def Missile_prop[] =
{
    { MI_NEEDLE, "needle", 0, 12, 2 },
};
static const food_def Food_prop[] =
{
    { FOOD_RATION, "buggy ration", 3400, 1900, 1900 },
};`)
}

func TestWeaponBrandWeightsKeepSourceOrder(t *testing.T) {
	vocabulary := propertyVocabulary()
	raw := "{{ SPWPN_VENOM, 28 }, { SPWPN_NORMAL, 20 }}"

	weights, err := parseBrandWeights(raw, nil, vocabulary)

	if err != nil {
		t.Fatal(err)
	}

	if len(weights) != 2 ||
		weights[0].BrandID != "SPWPN_VENOM" ||
		weights[1].BrandID != "SPWPN_NORMAL" {
		t.Fatalf("brand order changed: %+v", weights)
	}
}

func TestPinnedPropertyTableCoverage(t *testing.T) {
	root := os.Getenv("DCSS_SOURCE_DIR")

	if root == "" {
		t.Skip("optional pinned-source audit; normal tests use committed Go content")
	}

	source := map[string][]byte{}

	for _, name := range []string{
		"equipment-type.h",
		"skill-type.h",
		"size-type.h",
		"item-prop-enum.h",
		"item-prop.h",
		"item-prop.cc",
	} {
		data, err := os.ReadFile(filepath.Join(root, name))

		if err != nil {
			t.Fatal(err)
		}

		source[name] = data
	}

	vocabulary, err := parseVocabulary(source)

	if err != nil {
		t.Fatal(err)
	}

	rows, err := parsePropertyTables("crawl-ref/source/item-prop.cc", source["item-prop.cc"], vocabulary)

	if err != nil {
		t.Fatal(err)
	}

	counts := map[string]int{}

	for key := range rows {
		counts[key.ClassID]++
	}

	for class, want := range map[string]int{
		"OBJ_ARMOUR":   43,
		"OBJ_WEAPONS":  57,
		"OBJ_MISSILES": 10,
		"OBJ_FOOD":     23,
	} {
		if counts[class] != want {
			t.Errorf("%s rows: got %d, want %d", class, counts[class], want)
		}
	}

	if len(rows) != 133 {
		t.Fatalf("got %d property rows, want 133", len(rows))
	}

	fire := rows[itemKey{
		ClassID:   "OBJ_ARMOUR",
		SubtypeID: "ARM_FIRE_DRAGON_ARMOUR",
	}]

	if fire.Armour == nil ||
		fire.Armour.AC != 8 ||
		fire.Armour.EV != -110 ||
		len(fire.Armour.Flags) != 2 {
		t.Fatalf("fire dragon scales fields lost: %+v", fire)
	}

	mace := rows[itemKey{
		ClassID:   "OBJ_WEAPONS",
		SubtypeID: "WPN_MACE",
	}]

	if mace.Weapon == nil ||
		mace.Weapon.Damage != 8 ||
		mace.Weapon.Price != 30 ||
		len(mace.Weapon.BrandWeights) != 9 {
		t.Fatalf("mace fields lost: %+v", mace)
	}

	needle := rows[itemKey{
		ClassID:   "OBJ_MISSILES",
		SubtypeID: "MI_NEEDLE",
	}]

	if needle.Missile == nil || needle.Missile.MulchRate != 12 {
		t.Fatalf("needle fields lost: %+v", needle)
	}

	ration := rows[itemKey{
		ClassID:   "OBJ_FOOD",
		SubtypeID: "FOOD_RATION",
	}]

	if ration.Food == nil ||
		ration.Food.NormalNutrition != 3400 ||
		ration.Food.HerbivoreNutrition != 1900 {
		t.Fatalf("ration fields lost: %+v", ration)
	}
}

func propertyVocabulary() content.ItemVocabulary {
	return content.ItemVocabulary{
		Slots:       []string{"EQ_BODY_ARMOUR"},
		Skills:      []string{"SK_MACES_FLAILS"},
		Sizes:       []string{"SIZE_LARGE", "SIZE_LITTLE"},
		Ammo:        []string{"MI_NEEDLE", "MI_NONE"},
		DamageFlags: []string{"DAMV_CRUSHING"},
		Brands:      []string{"SPWPN_NORMAL", "SPWPN_VENOM"},
		ArmourFlags: []string{
			"ARMF_NO_FLAGS",
			"ARMF_RES_FIRE",
			"ARMF_VUL_COLD",
		},
	}
}

func TestPropertyTablesComplete(t *testing.T) {
	rows, err := parsePropertyTables("item-prop.cc", propertyFixture(), propertyVocabulary())

	if err != nil {
		t.Fatal(err)
	}

	if len(rows) != 6 {
		t.Fatalf("got %d rows, want 6", len(rows))
	}

	robe := rows[itemKey{
		ClassID:   "OBJ_ARMOUR",
		SubtypeID: "ARM_ROBE",
	}]

	if robe.Name != "robe" ||
		robe.Line != 3 ||
		robe.Armour == nil ||
		robe.Armour.AC != 2 ||
		robe.Armour.Price != 7 || robe.Armour.AcquireWeight != 1000 {
		t.Fatalf("robe fields lost: %+v", robe)
	}

	scales := rows[itemKey{
		ClassID:   "OBJ_ARMOUR",
		SubtypeID: "ARM_FIRE_DRAGON_ARMOUR",
	}]

	if scales.Armour == nil ||
		scales.Armour.AC != 8 ||
		scales.Armour.EV != -110 ||
		scales.Armour.Price != 600 ||
		scales.Armour.AcquireWeight != 25 ||
		len(scales.Armour.Flags) != 2 || scales.Armour.Flags[0] != (content.ItemFlag{
		ID:    "ARMF_RES_FIRE",
		Level: 2,
	}) || scales.Armour.Flags[1] != (content.ItemFlag{
		ID:    "ARMF_VUL_COLD",
		Level: -1,
	}) {
		t.Fatalf("dragon scales fields lost: %+v", scales)
	}

	hide := rows[itemKey{
		ClassID:   "OBJ_ARMOUR",
		SubtypeID: "ARM_FIRE_DRAGON_HIDE",
	}]

	if hide.Armour == nil ||
		hide.Armour.AC != 0 ||
		hide.Armour.Price != 0 ||
		hide.Armour.AcquireWeight != 0 || hide.Name != "removed fire dragon hide" {
		t.Fatalf("dragon hide fields lost: %+v", hide)
	}

	mace := rows[itemKey{
		ClassID:   "OBJ_WEAPONS",
		SubtypeID: "WPN_MACE",
	}]

	if mace.Weapon == nil ||
		mace.Weapon.Damage != 8 ||
		mace.Weapon.Hit != 3 ||
		mace.Weapon.Speed != 14 ||
		mace.Weapon.Commonness != 9 ||
		mace.Weapon.AcquireWeight != 10 ||
		mace.Weapon.Price != 30 ||
		len(mace.Weapon.BrandWeights) != 2 ||
		mace.Weapon.BrandWeights[0].BrandID != "SPWPN_NORMAL" ||
		mace.Weapon.BrandWeights[0].Weight != 58 {
		t.Fatalf("weapon fields lost: %+v", mace)
	}

	needle := rows[itemKey{
		ClassID:   "OBJ_MISSILES",
		SubtypeID: "MI_NEEDLE",
	}]

	if needle.Missile == nil ||
		needle.Missile.Damage != 0 ||
		needle.Missile.MulchRate != 12 ||
		needle.Missile.Price != 2 {
		t.Fatalf("missile fields lost: %+v", needle)
	}

	ration := rows[itemKey{
		ClassID:   "OBJ_FOOD",
		SubtypeID: "FOOD_RATION",
	}]

	if ration.Food == nil ||
		ration.Food.NormalNutrition != 3400 ||
		ration.Food.CarnivoreNutrition != 1900 ||
		ration.Food.HerbivoreNutrition != 1900 {
		t.Fatalf("food fields lost: %+v", ration)
	}
}

func TestPropertyScannerRejectsLoss(t *testing.T) {
	base := string(propertyFixture())

	for _, test := range []struct {
		name string
		from string
		to   string
	}{
		{
			name: "missing field",
			from: "EQ_BODY_ARMOUR, SIZE_LITTLE",
			to:   "SIZE_LITTLE",
		},

		{
			name: "unknown macro",
			from: "DRAGON_ARMOUR(FIRE",
			to:   "DRAGON_SHIELD(FIRE",
		},

		{
			name: "unknown symbol",
			from: "SK_MACES_FLAILS",
			to:   "SK_NOT_REAL",
		},

		{
			name: "duplicate row",
			from: "{ MI_NEEDLE, \"needle\", 0, 12, 2 },",
			to:   "{ MI_NEEDLE, \"needle\", 0, 12, 2 },\n    { MI_NEEDLE, \"needle\", 0, 12, 2 },",
		},

		{
			name: "extra table row",
			from: "{ MI_NEEDLE, \"needle\", 0, 12, 2 },",
			to:   "{ MI_NEEDLE, \"needle\", 0, 12, 2 },\n    { MI_BAD, \"bad\", 0, 12, 2 },",
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			bad := strings.Replace(base, test.from, test.to, 1)

			if _, err := parsePropertyTables(
				"item-prop.cc",
				[]byte(bad),
				propertyVocabulary(),
			); err == nil ||
				!strings.Contains(
					err.Error(),
					"item-prop.cc",
				) {
				t.Fatalf("invalid row accepted or lacked source context: %v", err)
			}
		})
	}

	quoted := strings.Replace(base, `"robe"`, `"robe, // still name"`, 1)
	rows, err := parsePropertyTables("item-prop.cc", []byte(quoted), propertyVocabulary())

	if err != nil ||
		rows[itemKey{
			ClassID:   "OBJ_ARMOUR",
			SubtypeID: "ARM_ROBE",
		}].Name != "robe, // still name" {
		t.Fatalf("quoted punctuation truncated: rows=%v err=%v", rows, err)
	}
}
