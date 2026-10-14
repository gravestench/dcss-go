package character

import (
	"fmt"

	"dcrawl-go/internal/content"
)

const HumanMaxLevel = 27

// HumanExperienceNeeded follows player.cc:exp_needed for Human's XP aptitude
// of one. The source subtracts one from its historical threshold table.
func HumanExperienceNeeded(level int) (int, error) {
	if level < 1 || level > HumanMaxLevel {
		return 0, fmt.Errorf("Human experience level %d is outside 1..27", level)
	}

	switch level {
	case 1:
		return 0, nil

	case 2:
		return 9, nil

	case 3:
		return 29, nil

	case 4:
		return 69, nil
	}

	if level < 13 {
		offset := level - 4

		return 9 + 10*offset + (60 << offset), nil
	}

	offset := level - 12

	return 16674 + 5985*offset + 4235*offset*offset, nil
}

func HumanLevelForExperience(totalXP int) (int, error) {
	if totalXP < 0 {
		return 0, fmt.Errorf("negative Human experience %d", totalXP)
	}

	level := 1

	for level < HumanMaxLevel {
		next, _ := HumanExperienceNeeded(level + 1)

		if totalXP < next {
			break
		}

		level++
	}

	return level, nil
}

// HumanLevelProgress mirrors get_exp_progress, including the held level while
// a manual stat choice is pending. At the final level the display reads zero.
func HumanLevelProgress(totalXP, level int) (int, error) {
	if totalXP < 0 {
		return 0, fmt.Errorf("negative Human experience %d", totalXP)
	}

	current, err := HumanExperienceNeeded(level)

	if err != nil {
		return 0, err
	}

	if totalXP < current {
		return 0, fmt.Errorf("Human XL%d needs at least %d experience", level, current)
	}

	if level == HumanMaxLevel {
		return 0, nil
	}

	next, _ := HumanExperienceNeeded(level + 1)

	return (totalXP - current) * 100 / (next - current), nil
}

// HumanMaxHP projects get_real_hp without mutations, drains, artefacts, or
// transformations. Fighting is the only live skill this formula reads.
func HumanMaxHP(level int, species content.SpeciesDef, skills []Skill) (int, error) {
	if level < 1 ||
		level > HumanMaxLevel || species.ID != "SP_HUMAN" {
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
		level > HumanMaxLevel || species.ID != "SP_HUMAN" {
		return 0, fmt.Errorf("unsupported Human MP inputs at XL%d for %s", level, species.ID)
	}

	return max(0, min(23, level)+species.MPMod), nil
}

// With no divine-attributes mutation, the source prompts at XL 3, 9, ...
func HumanNeedsManualStat(level int) bool {
	return level >= 3 && level <= HumanMaxLevel && level%6 == 3
}
