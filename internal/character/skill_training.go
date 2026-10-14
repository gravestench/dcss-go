package character

import "fmt"

const HumanMaxSkillLevel = 27

// HumanSkillPointsNeeded follows skills.cc:_get_skill_cost_for at zero
// aptitude. Breakpoints at 9, 18, and 26 add half of the base cost curve.
func HumanSkillPointsNeeded(level int) (int, error) {
	if level < 0 || level > HumanMaxSkillLevel {
		return 0, fmt.Errorf("Human skill level %d is outside 0..27", level)
	}

	points := baseSkillCost(level)

	for _, breakpoint := range [...]int{9, 18, 26} {
		if level > breakpoint {
			points += baseSkillCost(level-breakpoint) / 2
		}
	}

	return points, nil
}

func baseSkillCost(level int) int {
	return 25 * level * (level + 1)
}

func HumanSkillLevel(points int) (int, error) {
	if points < 0 {
		return 0, fmt.Errorf("negative Human skill points %d", points)
	}

	for level := HumanMaxSkillLevel; level > 0; level-- {
		needed, _ := HumanSkillPointsNeeded(level)

		if points >= needed {
			return level, nil
		}
	}

	return 0, nil
}

// SkillCostLevel follows skills.cc:skill_cost_needed. Spent skill XP uses
// Human's historical XP-aptitude-one threshold multiplied by thirteen.
func SkillCostLevel(spentXP int) (int, error) {
	if spentXP < 0 {
		return 0, fmt.Errorf("negative spent skill experience %d", spentXP)
	}

	level := 1

	for level < HumanMaxSkillLevel {
		threshold, _ := HumanExperienceNeeded(level + 1)

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
