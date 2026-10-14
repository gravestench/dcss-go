package character

import "fmt"

const MaxSkillLevel = 27

// SkillCostLevel follows skills.cc:skill_cost_needed. Spent skill XP uses
// the fixed XP-aptitude-one threshold multiplied by thirteen.
func SkillCostLevel(spentXP int) (int, error) {
	if spentXP < 0 {
		return 0, fmt.Errorf("negative spent skill experience %d", spentXP)
	}

	level := 1

	for level < MaxSkillLevel {
		threshold, _ := ExperienceNeeded(level+1, 1)

		if spentXP < 13*threshold {
			break
		}

		level++
	}

	return level, nil
}

// SkillPointCost is the source's per-point skill XP cost table.
func SkillPointCost(level int) (int, error) {
	costs := [...]int{
		1,
		2,
		3,
		4,
		5,
		7,
		8,
		9,
		13,
		22,
		37,
		48,
		73,
		98,
		125,
		145,
		170,
		190,
		212,
		225,
		240,
		255,
		260,
		265,
		265,
		265,
		265,
	}

	if level < 1 || level > len(costs) {
		return 0, fmt.Errorf("skill cost level %d is outside 1..27", level)
	}

	return costs[level-1], nil
}
