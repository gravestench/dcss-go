package character

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/content"
)

// OrdinaryBiteProfile is the supported source-backed subset of monsters with
// one plain bite and no special combat or experience behavior.
type OrdinaryBiteProfile struct {
	AverageHP10x, MinHP, MaxHP, Damage, Speed, XPModifier int
}

var ordinaryBiteProfiles = map[string]OrdinaryBiteProfile{
	"MONS_RAT": {
		AverageHP10x: 25,
		MinHP:        1,
		MaxHP:        4,
		Damage:       3,
		Speed:        10,
		XPModifier:   1,
	},
	"MONS_QUOKKA": {
		AverageHP10x: 55,
		MinHP:        3,
		MaxHP:        8,
		Damage:       5,
		Speed:        12,
		XPModifier:   10,
	},
	"MONS_FRILLED_LIZARD": {
		AverageHP10x: 20,
		MinHP:        1,
		MaxHP:        3,
		Damage:       3,
		Speed:        10,
		XPModifier:   10,
	},
}

func OrdinaryAnimalProfile(id string) (OrdinaryBiteProfile, bool) {
	profile, found := ordinaryBiteProfiles[id]

	return profile, found
}

// OrdinaryAnimalExperience evaluates the source's plain bite path of
// mon-util.cc:2345-2535 against live maximum HP. Difficulty adjustment is
// zero because these animals have no spells, items, fast regeneration, or big damage.
func OrdinaryAnimalExperience(animal content.MonsterDef, maxHP int) (int, error) {
	profile, found := OrdinaryAnimalProfile(animal.ID)

	if !found {
		return 0, fmt.Errorf("unsupported ordinary animal %s", animal.ID)
	}

	if animal.HD != 1 ||
		animal.AverageHP10x != profile.AverageHP10x ||
		animal.Speed != profile.Speed ||
		animal.XPModifier != profile.XPModifier ||
		animal.SpellbookID != "MST_NO_SPELLS" || animal.ItemUseID != "MONUSE_NOTHING" ||
		animal.Attacks[0] != (content.MonsterAttack{
			TypeID:    "AT_BITE",
			FlavourID: "AF_PLAIN",
			Damage:    profile.Damage,
		}) ||
		slices.Contains(animal.Flags, "M_NO_EXP_GAIN") || slices.Contains(animal.Flags, "M_FIGHTER") ||
		slices.Contains(animal.Flags, "M_FAST_REGEN") || maxHP < profile.MinHP || maxHP > profile.MaxHP {
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
	})
}
