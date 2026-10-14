package character

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/content"
)

// OrdinaryNaturalProfile describes supported source-backed natural melee.
// An equipment-capable monster can still use this path when it starts unarmed.
type OrdinaryNaturalProfile struct {
	HitDice      int
	AverageHP10x int
	MinHP        int
	MaxHP        int

	Damage          int
	Speed           int
	AttackTypeID    string
	ConstrictDamage int
	SpellbookID     string
	ItemUseID       string

	XPModifier int
	FastRegen  bool
	NoSkeleton bool
	NoCorpse   bool
	Poison     bool
	Batty      bool
}

var ordinaryNaturalProfiles = map[string]OrdinaryNaturalProfile{
	"MONS_RAT": {
		HitDice:      1,
		AverageHP10x: 25,
		MinHP:        1,
		MaxHP:        4,
		Damage:       3,
		Speed:        10,
		AttackTypeID: "AT_BITE",
		XPModifier:   1,
	},

	"MONS_QUOKKA": {
		HitDice:      1,
		AverageHP10x: 55,
		MinHP:        3,
		MaxHP:        8,
		Damage:       5,
		Speed:        12,
		AttackTypeID: "AT_BITE",
		XPModifier:   10,
	},

	"MONS_FRILLED_LIZARD": {
		HitDice:      1,
		AverageHP10x: 20,
		MinHP:        1,
		MaxHP:        3,
		Damage:       3,
		Speed:        10,
		AttackTypeID: "AT_BITE",
		XPModifier:   10,
	},

	"MONS_GIANT_COCKROACH": {
		HitDice:      1,
		AverageHP10x: 50,
		MinHP:        3,
		MaxHP:        7,
		Damage:       2,
		Speed:        12,
		AttackTypeID: "AT_BITE",
		XPModifier:   10,
		NoSkeleton:   true,
	},

	"MONS_WORM": {
		HitDice:      4,
		AverageHP10x: 180,
		MinHP:        12,
		MaxHP:        24,
		Damage:       12,
		Speed:        6,
		AttackTypeID: "AT_BITE",
		XPModifier:   3,
		FastRegen:    true,
		NoSkeleton:   true,
	},

	"MONS_JACKAL": {
		HitDice:      1,
		AverageHP10x: 55,
		MinHP:        3,
		MaxHP:        8,
		Damage:       3,
		Speed:        14,
		AttackTypeID: "AT_BITE",
		XPModifier:   10,
	},

	"MONS_ADDER": {
		HitDice:      2,
		AverageHP10x: 110,
		MinHP:        7,
		MaxHP:        15,

		Damage:       4,
		Speed:        13,
		AttackTypeID: "AT_BITE",

		XPModifier: 10,
		Poison:     true,
	},

	"MONS_BAT": {
		HitDice:      1,
		AverageHP10x: 35,
		MinHP:        2,
		MaxHP:        5,
		Damage:       1,
		Speed:        30,
		AttackTypeID: "AT_HIT",
		XPModifier:   4,
		Batty:        true,
	},

	"MONS_BALL_PYTHON": {
		HitDice:         1,
		AverageHP10x:    35,
		MinHP:           2,
		MaxHP:           5,
		Damage:          3,
		Speed:           12,
		AttackTypeID:    "AT_BITE",
		ConstrictDamage: 1,
		XPModifier:      13,
	},

	"MONS_ENDOPLASM": {
		HitDice:      1,
		AverageHP10x: 60,
		MinHP:        4,
		MaxHP:        8,

		Damage:       3,
		Speed:        10,
		AttackTypeID: "AT_HIT",
		SpellbookID:  "MST_ENDOPLASM",

		XPModifier: 10,
		NoSkeleton: true,
		NoCorpse:   true,
	},

	"MONS_DART_SLUG": {
		HitDice:      1,
		AverageHP10x: 100,
		MinHP:        6,
		MaxHP:        14,

		Damage:       3,
		Speed:        7,
		AttackTypeID: "AT_BITE",
		SpellbookID:  "MST_DART_SLUG",

		XPModifier: 40,
		NoSkeleton: true,
	},

	"MONS_HOBGOBLIN": {
		HitDice:      1,
		AverageHP10x: 55,
		MinHP:        3,
		MaxHP:        8,

		Damage:       5,
		Speed:        10,
		AttackTypeID: "AT_HIT",
		ItemUseID:    "MONUSE_WEAPONS_ARMOUR",

		XPModifier: 10,
	},
}

func OrdinaryNaturalProfileFor(id string) (OrdinaryNaturalProfile, bool) {
	profile, found := ordinaryNaturalProfiles[id]

	return profile, found
}

// OrdinaryNaturalExperience evaluates mon-util.cc:2345-2535 against live
// maximum HP. Supported spellbooks add no spell difficulty bonus; equipment
// users receive the source's difficulty bonus even when they start unarmed.
func OrdinaryNaturalExperience(definition content.MonsterDef, maxHP int) (int, error) {
	profile, found := OrdinaryNaturalProfileFor(definition.ID)

	if !found {
		return 0, fmt.Errorf("unsupported ordinary monster %s", definition.ID)
	}

	flavourID := "AF_PLAIN"

	if profile.Poison {
		flavourID = "AF_POISON"
	}

	secondAttack := content.MonsterAttack{
		TypeID:    "AT_NONE",
		FlavourID: "AF_PLAIN",
	}

	if profile.ConstrictDamage > 0 {
		secondAttack = content.MonsterAttack{
			TypeID:    "AT_CONSTRICT",
			FlavourID: "AF_CRUSH",
			Damage:    profile.ConstrictDamage,
		}
	}

	spellbookID := profile.SpellbookID

	if spellbookID == "" {
		spellbookID = "MST_NO_SPELLS"
	}

	expectedCorpse := !profile.NoCorpse
	itemUseID := profile.ItemUseID

	if itemUseID == "" {
		itemUseID = "MONUSE_NOTHING"
	}

	if definition.HD != profile.HitDice ||
		definition.AverageHP10x != profile.AverageHP10x ||
		definition.Speed != profile.Speed ||
		definition.XPModifier != profile.XPModifier ||
		definition.SpellbookID != spellbookID ||
		definition.ItemUseID != itemUseID ||
		definition.Attacks[0] != (content.MonsterAttack{
			TypeID:    profile.AttackTypeID,
			FlavourID: flavourID,
			Damage:    profile.Damage,
		}) ||
		definition.Attacks[1] != secondAttack ||
		slices.Contains(definition.Flags, "M_NO_EXP_GAIN") ||
		slices.Contains(definition.Flags, "M_FIGHTER") ||
		slices.Contains(definition.Flags, "M_FAST_REGEN") != profile.FastRegen ||
		slices.Contains(definition.Flags, "M_NO_SKELETON") != profile.NoSkeleton ||
		definition.LeavesCorpse != expectedCorpse ||
		slices.Contains(definition.Flags, "M_BATTY") != profile.Batty ||
		maxHP < profile.MinHP || maxHP > profile.MaxHP {
		return 0, fmt.Errorf("unsupported %s experience inputs at %d HP", definition.ID, maxHP)
	}

	for _, extra := range definition.Attacks[2:] {
		if extra.TypeID != "AT_NONE" || extra.Damage != 0 {
			return 0, fmt.Errorf("unsupported extra %s attack %+v", definition.ID, extra)
		}
	}

	attackDamage := [4]int{
		definition.Attacks[0].Damage,
		definition.Attacks[1].Damage,
	}

	return OrdinaryMonsterExperience(OrdinaryMonsterXPInput{
		HitDice:       definition.HD,
		MaxHP:         maxHP,
		Speed:         definition.Speed,
		Modifier:      definition.XPModifier,
		AttackDamage:  attackDamage,
		FastRegen:     profile.FastRegen,
		Spellcaster:   profile.SpellbookID != "",
		EquipmentUser: profile.ItemUseID != "",
	})
}
