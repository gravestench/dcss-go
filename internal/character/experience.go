package character

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/content"
)

// RatKillExperience evaluates the ordinary fixed rat path of
// mon-util.cc:2345-2535 against its live maximum HP.
func RatKillExperience(rat content.MonsterDef, maxHP int) (int, error) {
	if rat.ID != "MONS_RAT" || rat.HD != 1 || rat.Speed != 10 || rat.XPModifier != 1 ||
		rat.SpellbookID != "MST_NO_SPELLS" || rat.ItemUseID != "MONUSE_NOTHING" ||
		rat.Attacks[0].Damage != 3 || slices.Contains(rat.Flags, "M_NO_EXP_GAIN") || maxHP != 4 {
		return 0, fmt.Errorf("unsupported rat experience inputs for %s at %d HP", rat.ID, maxHP)
	}
	value := (16 + maxHP) * rat.HD * rat.HD / 10
	// This rat has no difficulty adjustment. Its base speed is 10.
	value = value * rat.Speed / 10
	value = value * rat.XPModifier / 10
	return max(1, value), nil
}

// HumanFirstLevelProgress follows exp_needed(1)=0, exp_needed(2)=9 and
// get_exp_progress(), which truncates the percentage toward zero.
func HumanFirstLevelProgress(totalXP int) (int, error) {
	if totalXP < 0 || totalXP >= 9 {
		return 0, fmt.Errorf("unsupported Human XL1 experience %d", totalXP)
	}
	return totalXP * 100 / 9, nil
}
