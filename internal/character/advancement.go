package character

import (
	"fmt"

	"dcrawl-go/internal/content"
)

// HumanMaxHP projects get_real_hp without mutations, drains, artefacts, or
// transformations. Fighting is the only live skill this formula reads.
func HumanMaxHP(level int, species content.SpeciesDef, skills []Skill) (int, error) {
	if level < 1 ||
		level > MaxExperienceLevel || species.ID != "SP_HUMAN" {
		return 0, fmt.Errorf("unsupported Human HP inputs at XL%d for %s", level, species.ID)
	}

	var fighting *Skill

	for index := range skills {
		if skills[index].ID == "SK_FIGHTING" {
			fighting = &skills[index]
			break
		}
	}

	if fighting == nil {
		return 0, fmt.Errorf("Human lacks Fighting skill")
	}

	hp := level*11/2 + 8
	hp += level*ScaledSkill(*fighting, 5)/70 +
		(ScaledSkill(*fighting, 3)+1)/2
	hp = hp * (10 + species.HP) / 10

	return max(1, hp), nil
}

// HumanMaxMP projects get_real_mp for a Fighter with no Spellcasting,
// Invocations, magic mutations, or power-granting equipment.
func HumanMaxMP(level int, species content.SpeciesDef) (int, error) {
	if level < 1 ||
		level > MaxExperienceLevel || species.ID != "SP_HUMAN" {
		return 0, fmt.Errorf("unsupported Human MP inputs at XL%d for %s", level, species.ID)
	}

	return max(0, min(23, level)+species.MPMod), nil
}

// With no divine-attributes mutation, the source prompts at XL 3, 9, ...
func HumanNeedsManualStat(level int) bool {
	return level >= 3 &&
		level <= MaxExperienceLevel &&
		level%6 == 3
}
