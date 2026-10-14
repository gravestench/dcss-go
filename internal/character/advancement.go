package character

import (
	"fmt"

	"dcrawl-go/internal/content"
)

// BaseMaxHP projects get_real_hp through the racial modifier. Permanent HP
// adjustments, mutations, religion, drains, artefacts, and transformations
// have separate state and are not yet part of this baseline.
func BaseMaxHP(level int, species content.SpeciesDef, skills []Skill) (int, error) {
	if level < 1 || level > MaxExperienceLevel {
		return 0, fmt.Errorf("invalid HP level %d", level)
	}

	var fighting *Skill

	for index := range skills {
		if skills[index].ID == "SK_FIGHTING" {
			fighting = &skills[index]
			break
		}
	}

	if fighting == nil {
		return 0, fmt.Errorf("%s lacks Fighting skill", species.ID)
	}

	aptitude, err := species.SkillAptitude("SK_FIGHTING")

	if err != nil {
		return 0, err
	}

	fighting5, err := ScaledSkill(*fighting, 5, aptitude)

	if err != nil {
		return 0, err
	}

	fighting3, err := ScaledSkill(*fighting, 3, aptitude)

	if err != nil {
		return 0, err
	}

	hp := level*11/2 + 8
	hp += level*fighting5/70 + (fighting3+1)/2
	hp = hp * (10 + species.HP) / 10

	return max(1, hp), nil
}

// BaseMaxMP projects get_real_mp for a Fighter with no Spellcasting,
// Invocations, magic mutations, or power-granting equipment.
func BaseMaxMP(level int, species content.SpeciesDef) (int, error) {
	if level < 1 ||
		level > MaxExperienceLevel ||
		!SupportedFighterSpecies(species.ID) {
		return 0, fmt.Errorf("unsupported baseline MP inputs at XL%d for %s", level, species.ID)
	}

	return max(0, min(23, level)+species.MPMod), nil
}

// With no divine-attributes mutation, the source prompts at XL 3, 9, ...
func NeedsManualStat(level int) bool {
	return level >= 3 &&
		level <= MaxExperienceLevel &&
		level%6 == 3
}
