package content

import "testing"

func testWeaponItem() ItemDef {
	return ItemDef{
		ID:           "WPN_MACE",
		Name:         "mace",
		Glyph:        ')',
		Class:        "OBJ_WEAPONS",
		ClassValue:   0,
		SubtypeValue: 4,
		Slot:         "weapon",
		WeaponSkill:  "SK_MACES_FLAILS",
		Naming: ItemName{
			Text:       "mace",
			Kind:       "static",
			SourcePath: "crawl-ref/source/item-prop.cc",
			SourceLine: 7,
		},
		Evidence: ItemEvidence{
			PropertySource: "crawl-ref/source/item-prop.cc",
			PropertyLine:   7,
		},
		Weapon: &WeaponProperties{
			Damage:      8,
			Hit:         3,
			Speed:       14,
			SkillID:     "SK_MACES_FLAILS",
			Min2HSizeID: "SIZE_LITTLE",
			Min1HSizeID: "SIZE_LITTLE",
			AmmoID:      "MI_NONE",
			DamageFlags: []string{"DAMV_CRUSHING"},
			BrandWeights: []ItemBrandWeight{
				{
					BrandID: "SPWPN_NORMAL",
					Weight:  58,
				},
				{
					BrandID: "SPWPN_VENOM",
					Weight:  16,
				},
			},
		},
	}
}

func TestItemDefCopies(t *testing.T) {
	c := Catalog{items: map[string]ItemDef{"WPN_MACE": testWeaponItem()}}
	first, err := c.Item("WPN_MACE")

	if err != nil {
		t.Fatal(err)
	}

	first.Weapon.DamageFlags[0] = "BROKEN"
	first.Weapon.BrandWeights[0].Weight = 0
	second, err := c.Item("WPN_MACE")

	if err != nil {
		t.Fatal(err)
	}

	if second.Weapon.DamageFlags[0] != "DAMV_CRUSHING" || second.Weapon.BrandWeights[0].Weight != 58 {
		t.Fatalf("catalog item was mutated through return value: %+v", second.Weapon)
	}

	armour := ItemDef{
		ID: "ARM_ROBE",
		Armour: &ArmourProperties{
			Flags: []ItemFlag{
				{
					ID:    "ARMF_RES_FIRE",
					Level: 2,
				},
			},
		},
	}
	c.items["ARM_ROBE"] = armour
	firstArmour, _ := c.Item("ARM_ROBE")
	firstArmour.Armour.Flags[0].Level = 9
	secondArmour, _ := c.Item("ARM_ROBE")

	if secondArmour.Armour.Flags[0].Level != 2 {
		t.Fatalf("armour flags leaked through return value: %+v", secondArmour.Armour.Flags)
	}
}

func TestItemIdentityInspection(t *testing.T) {
	c := Catalog{
		items: map[string]ItemDef{"WPN_MACE": testWeaponItem()},
		itemIdentities: map[string]ItemIdentity{
			"WPN_MACE": {
				ID:           "WPN_MACE",
				ClassID:      "OBJ_WEAPONS",
				ClassValue:   0,
				SubtypeValue: 4,
				SourcePath:   "crawl-ref/source/item-prop-enum.h",
				SourceLine:   4,
			},
			"WPN_OLD": {
				ID:           "WPN_OLD",
				ClassID:      "OBJ_WEAPONS",
				ClassValue:   0,
				SubtypeValue: 99,
				SourcePath:   "crawl-ref/source/item-prop-enum.h",
				SourceLine:   5,
			},
		},
	}

	if _, err := c.ItemIdentity("WPN_OLD"); err != nil {
		t.Fatal(err)
	}

	if _, err := c.Item("WPN_OLD"); err == nil {
		t.Fatal("undefined item was returned as a usable definition")
	}

	if _, err := c.ItemIdentity("WPN_UNKNOWN"); err == nil {
		t.Fatal("unknown identity was accepted")
	}

	ids := c.ItemIDs()

	if len(ids) != 2 || ids[0] != "WPN_MACE" || ids[1] != "WPN_OLD" {
		t.Fatalf("wrong identity listing: %v", ids)
	}

	ids[0] = "BROKEN"

	if c.ItemIDs()[0] != "WPN_MACE" {
		t.Fatal("identity listing exposed catalog storage")
	}
}

func TestItemShapeValidation(t *testing.T) {
	valid := testWeaponItem()

	if err := valid.validate(); err != nil {
		t.Fatalf("valid weapon rejected: %v", err)
	}

	bad := valid.clone()
	bad.Armour = &ArmourProperties{}

	if err := bad.validate(); err == nil {
		t.Fatal("weapon with armour properties accepted")
	}

	bad = valid.clone()
	bad.Naming.SourceLine = 0

	if err := bad.validate(); err == nil {
		t.Fatal("missing source location accepted")
	}

	bad = valid.clone()
	bad.Naming.Kind = "invented"

	if err := bad.validate(); err == nil {
		t.Fatal("unknown naming kind accepted")
	}

	bad = valid.clone()
	bad.Weapon.BrandWeights = []ItemBrandWeight{
		{
			BrandID: "SPWPN_VENOM",
			Weight:  16,
		},
		{
			BrandID: "SPWPN_NORMAL",
			Weight:  58,
		},
	}

	if err := bad.validate(); err == nil {
		t.Fatal("unsorted brand weights accepted")
	}
}
