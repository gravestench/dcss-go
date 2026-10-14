package character

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/content"
)

// OrdinaryBiteProfile is the supported source-backed subset of monsters with
// one ordinary bite and no spell or equipment behavior.
type OrdinaryBiteProfile struct {
	HitDice      int
	AverageHP10x int
	MinHP        int
	MaxHP        int

	Damage int
	Speed  int

	XPModifier int
	FastRegen  bool
	NoSkeleton bool
	Poison     bool
}

var ordinaryBiteProfiles = map[string]OrdinaryBiteProfile{
	"MONS_RAT": {
		HitDice:      1,
		AverageHP10x: 25,
		MinHP:        1,
		MaxHP:        4,
		Damage:       3,
		Speed:        10,
		XPModifier:   1,
	},

	"MONS_QUOKKA": {
		HitDice:      1,
		AverageHP10x: 55,
		MinHP:        3,
		MaxHP:        8,
		Damage:       5,
		Speed:        12,
		XPModifier:   10,
	},

	"MONS_FRILLED_LIZARD": {
		HitDice:      1,
		AverageHP10x: 20,
		MinHP:        1,
		MaxHP:        3,
		Damage:       3,
		Speed:        10,
		XPModifier:   10,
	},

	"MONS_GIANT_COCKROACH": {
		HitDice:      1,
		AverageHP10x: 50,
		MinHP:        3,
		MaxHP:        7,
		Damage:       2,
		Speed:        12,
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
		XPModifier:   10,
	},

	"MONS_ADDER": {
		HitDice:      2,
		AverageHP10x: 110,
		MinHP:        7,
		MaxHP:        15,

		Damage: 4,
		Speed:  13,

		XPModifier: 10,
		Poison:     true,
	},
}

func OrdinaryAnimalProfile(id string) (OrdinaryBiteProfile, bool) {
	profile, found := ordinaryBiteProfiles[id]

	return profile, found
}

// OrdinaryAnimalExperience evaluates the source's ordinary bite path of
// mon-util.cc:2345-2535 against live maximum HP. Difficulty adjustment is
// zero except for the worm's source fast-regeneration adjustment. These
// supported animals have no spells, equipment, or large fast melee attack.
func OrdinaryAnimalExperience(animal content.MonsterDef, maxHP int) (int, error) {
	profile, found := OrdinaryAnimalProfile(animal.ID)

	if !found {
		return 0, fmt.Errorf("unsupported ordinary animal %s", animal.ID)
	}

	flavourID := "AF_PLAIN"

	if profile.Poison {
		flavourID = "AF_POISON"
	}

	if animal.HD != profile.HitDice ||
		animal.AverageHP10x != profile.AverageHP10x ||
		animal.Speed != profile.Speed ||
		animal.XPModifier != profile.XPModifier ||
		animal.SpellbookID != "MST_NO_SPELLS" ||
		animal.ItemUseID != "MONUSE_NOTHING" ||
		animal.Attacks[0] != (content.MonsterAttack{
			TypeID:    "AT_BITE",
			FlavourID: flavourID,
			Damage:    profile.Damage,
		}) ||
		slices.Contains(animal.Flags, "M_NO_EXP_GAIN") ||
		slices.Contains(animal.Flags, "M_FIGHTER") ||
		slices.Contains(animal.Flags, "M_FAST_REGEN") != profile.FastRegen ||
		slices.Contains(animal.Flags, "M_NO_SKELETON") != profile.NoSkeleton ||
		maxHP < profile.MinHP || maxHP > profile.MaxHP {
		return 0, fmt.Errorf("unsupported %s experience inputs at %d HP", animal.ID, maxHP)
	}

	for _, extra := range animal.Attacks[1:] {
		if extra.TypeID != "AT_NONE" || extra.Damage != 0 {
			return 0, fmt.Errorf("unsupported extra %s attack %+v", animal.ID, extra)
		}
	}

	return OrdinaryMonsterExperience(OrdinaryMonsterXPInput{
		HitDice:      animal.HD,
		MaxHP:        maxHP,
		Speed:        animal.Speed,
		Modifier:     animal.XPModifier,
		AttackDamage: [4]int{animal.Attacks[0].Damage},
		FastRegen:    profile.FastRegen,
	})
}
