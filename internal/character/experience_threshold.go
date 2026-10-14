package character

import (
	"fmt"
	"math"
)

const MaxExperienceLevel = 27

// ExperienceNeeded follows player.cc:exp_needed and skills.cc:apt_to_factor.
// The source returns the aptitude factor as float before multiplication.
func ExperienceNeeded(level, xpApt int) (int, error) {
	if level < 1 || level > MaxExperienceLevel {
		return 0, fmt.Errorf("experience level %d is outside 1..27", level)
	}

	factor := float32(1 / math.Exp(math.Log(2)*float64(xpApt-1)/4))
	maxThreshold := float32(historicalExperience(MaxExperienceLevel)-1) * factor
	maxInt := float64(int(^uint(0) >> 1))

	if factor <= 0 ||
		math.IsInf(float64(factor), 0) ||
		float32(9)*factor < 1 ||
		float64(maxThreshold) > maxInt {
		return 0, fmt.Errorf("experience aptitude %d has invalid thresholds", xpApt)
	}

	threshold := float32(historicalExperience(level)-1) * factor

	return int(threshold), nil
}

func historicalExperience(level int) int {
	switch level {
	case 1:
		return 1

	case 2:
		return 10

	case 3:
		return 30

	case 4:
		return 70
	}

	if level < 13 {
		offset := level - 4

		return 10 + 10*offset + (60 << offset)
	}

	offset := level - 12

	return 16675 + 5985*offset + 4235*offset*offset
}

// LevelForExperience returns the level earned by a species' XP aptitude.
func LevelForExperience(totalXP, xpApt int) (int, error) {
	if totalXP < 0 {
		return 0, fmt.Errorf("negative experience %d", totalXP)
	}

	if _, err := ExperienceNeeded(2, xpApt); err != nil {
		return 0, err
	}

	level := 1

	for level < MaxExperienceLevel {
		next, _ := ExperienceNeeded(level+1, xpApt)

		if totalXP < next {
			break
		}

		level++
	}

	return level, nil
}

// LevelProgress preserves a held applied level during a manual stat choice.
func LevelProgress(totalXP, level, xpApt int) (int, error) {
	if totalXP < 0 {
		return 0, fmt.Errorf("negative experience %d", totalXP)
	}

	if _, err := ExperienceNeeded(2, xpApt); err != nil {
		return 0, err
	}

	current, err := ExperienceNeeded(level, xpApt)

	if err != nil {
		return 0, err
	}

	if totalXP < current {
		return 0, fmt.Errorf("XL%d needs at least %d experience", level, current)
	}

	if level == MaxExperienceLevel {
		return 0, nil
	}

	next, _ := ExperienceNeeded(level+1, xpApt)

	return (totalXP - current) * 100 / (next - current), nil
}
