package character

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/content"
)

// OrdinaryNaturalProfile is the supported source-backed subset of monsters with
// one natural attack and no spell or equipment behavior.
type OrdinaryNaturalProfile struct {
	HitDice      int
	AverageHP10x int
	MinHP        int
	MaxHP        int

	Damage       int
	Speed        int
	AttackTypeID string

	XPModifier int
	FastRegen  bool
	NoSkeleton bool
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
}

func OrdinaryNaturalProfileFor(id string) (OrdinaryNaturalProfile, bool) {
	profile, found := ordinaryNaturalProfiles[id]

	return profile, found
}

// OrdinaryNaturalExperience evaluates the source's ordinary melee path of
// mon-util.cc:2345-2535 against live maximum HP. Difficulty adjustment is
// zero except for the worm's source fast-regeneration adjustment. These
// supported monsters have no spells, equipment, or large fast melee attack.
func OrdinaryNaturalExperience(definition content.MonsterDef, maxHP int) (int, error) {
	profile, found := OrdinaryNaturalProfileFor(definition.ID)

	if !found {
		return 0, fmt.Errorf("unsupported ordinary monster %s", definition.ID)
	}

	flavourID := "AF_PLAIN"

	if profile.Poison {
		flavourID = "AF_POISON"
	}

	if definition.HD != profile.HitDice ||
		definition.AverageHP10x != profile.AverageHP10x ||
		definition.Speed != profile.Speed ||
		definition.XPModifier != profile.XPModifier ||
		definition.SpellbookID != "MST_NO_SPELLS" ||
		definition.ItemUseID != "MONUSE_NOTHING" ||
		definition.Attacks[0] != (content.MonsterAttack{
			TypeID:    profile.AttackTypeID,
			FlavourID: flavourID,
			Damage:    profile.Damage,
		}) ||
		slices.Contains(definition.Flags, "M_NO_EXP_GAIN") ||
		slices.Contains(definition.Flags, "M_FIGHTER") ||
		slices.Contains(definition.Flags, "M_FAST_REGEN") != profile.FastRegen ||
		slices.Contains(definition.Flags, "M_NO_SKELETON") != profile.NoSkeleton ||
		slices.Contains(definition.Flags, "M_BATTY") != profile.Batty ||
		maxHP < profile.MinHP || maxHP > profile.MaxHP {
		return 0, fmt.Errorf("unsupported %s experience inputs at %d HP", definition.ID, maxHP)
	}

	for _, extra := range definition.Attacks[1:] {
		if extra.TypeID != "AT_NONE" || extra.Damage != 0 {
			return 0, fmt.Errorf("unsupported extra %s attack %+v", definition.ID, extra)
		}
	}

	return OrdinaryMonsterExperience(OrdinaryMonsterXPInput{
		HitDice:      definition.HD,
		MaxHP:        maxHP,
		Speed:        definition.Speed,
		Modifier:     definition.XPModifier,
		AttackDamage: [4]int{definition.Attacks[0].Damage},
		FastRegen:    profile.FastRegen,
	})
}
