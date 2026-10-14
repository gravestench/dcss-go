package character

import (
	"fmt"
	"math"
)

// SkillPointsNeeded follows skills.cc:skill_exp_needed. The source returns
// the aptitude factor as float before multiplying and truncating it.
func SkillPointsNeeded(level, aptitude int) (int, error) {
	if level < 0 || level > MaxSkillLevel {
		return 0, fmt.Errorf("skill level %d is outside 0..27", level)
	}

	factor := float32(1 / math.Exp(math.Log(2)*float64(aptitude)/4))
	maxThreshold := float32(historicalSkillCost(MaxSkillLevel)) * factor
	maxInt := float64(int(^uint(0) >> 1))

	if factor <= 0 ||
		math.IsInf(float64(factor), 0) ||
		float32(50)*factor < 1 ||
		float64(maxThreshold) > maxInt {
		return 0, fmt.Errorf("skill aptitude %d has invalid thresholds", aptitude)
	}

	return int(float32(historicalSkillCost(level)) * factor), nil
}

func historicalSkillCost(level int) int {
	points := 25 * level * (level + 1)

	for _, breakpoint := range [...]int{9, 18, 26} {
		if level > breakpoint {
			offset := level - breakpoint
			points += 25 * offset * (offset + 1) / 2
		}
	}

	return points
}

// SkillLevel returns the level earned from stored points at this aptitude.
func SkillLevel(points, aptitude int) (int, error) {
	if points < 0 {
		return 0, fmt.Errorf("negative skill points %d", points)
	}

	if _, err := SkillPointsNeeded(1, aptitude); err != nil {
		return 0, err
	}

	for level := MaxSkillLevel; level > 0; level-- {
		needed, _ := SkillPointsNeeded(level, aptitude)

		if points >= needed {
			return level, nil
		}
	}

	return 0, nil
}
