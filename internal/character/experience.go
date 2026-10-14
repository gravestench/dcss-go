package character

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/content"
)

// OrdinaryAnimalExperience evaluates the source's plain rat/quokka path of
// mon-util.cc:2345-2535 against live maximum HP. Their difficulty adjustment
// is zero because neither has spells, items, fast regeneration, or big damage.
func OrdinaryAnimalExperience(animal content.MonsterDef, maxHP int) (int, error) {
	minimum, maximum, damage, speed, modifier := 0, 0, 0, 0, 0
	switch animal.ID {
	case "MONS_RAT":
		minimum, maximum, damage, speed, modifier = 1, 4, 3, 10, 1
	case "MONS_QUOKKA":
		minimum, maximum, damage, speed, modifier = 3, 8, 5, 12, 10
	default:
		return 0, fmt.Errorf("unsupported ordinary animal %s", animal.ID)
	}
	if animal.HD != 1 || animal.Speed != speed || animal.XPModifier != modifier ||
		animal.SpellbookID != "MST_NO_SPELLS" || animal.ItemUseID != "MONUSE_NOTHING" ||
		animal.Attacks[0] != (content.MonsterAttack{TypeID: "AT_BITE", FlavourID: "AF_PLAIN", Damage: damage}) ||
		slices.Contains(animal.Flags, "M_NO_EXP_GAIN") || slices.Contains(animal.Flags, "M_FIGHTER") ||
		slices.Contains(animal.Flags, "M_FAST_REGEN") || maxHP < minimum || maxHP > maximum {
		return 0, fmt.Errorf("unsupported %s experience inputs at %d HP", animal.ID, maxHP)
	}
	for _, extra := range animal.Attacks[1:] {
		if extra.TypeID != "AT_NONE" || extra.Damage != 0 {
			return 0, fmt.Errorf("unsupported extra %s attack %+v", animal.ID, extra)
		}
	}
	return OrdinaryMonsterExperience(OrdinaryMonsterXPInput{
		HitDice: animal.HD, MaxHP: maxHP, Speed: animal.Speed, Modifier: animal.XPModifier,
		AttackDamage: [4]int{animal.Attacks[0].Damage},
	})
}

// HumanFirstLevelProgress follows exp_needed(1)=0, exp_needed(2)=9 and
// get_exp_progress(), which truncates the percentage toward zero.
func HumanFirstLevelProgress(totalXP int) (int, error) {
	if totalXP < 0 || totalXP >= 9 {
		return 0, fmt.Errorf("unsupported Human XL1 experience %d", totalXP)
	}
	return totalXP * 100 / 9, nil
}
