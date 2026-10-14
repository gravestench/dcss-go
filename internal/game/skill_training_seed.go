package game

import (
	"fmt"
	"sort"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
)

// The pinned skills.cc seeds each 100-entry practice queue in random order
// from the square of the starting points. The queues then drift with practice.
func newPlayerSkillTraining(
	skills []character.Skill,
	rng *RNGStreams,
) (ecs.SkillTraining, error) {
	training := ecs.SkillTraining{
		CostLevel: 1,
		Settings:  make([]ecs.SkillTrainingSetting, 0, len(skills)),
	}

	for _, skill := range skills {
		training.Settings = append(training.Settings, ecs.SkillTrainingSetting{
			ID:      skill.ID,
			Enabled: true,
		})
	}

	var err error
	training.RecentPractice, err = seedSkillQueue(skills, rng)

	if err != nil {
		return ecs.SkillTraining{}, err
	}

	training.RecentAll, err = seedSkillQueue(skills, rng)

	return training, err
}

func seedSkillQueue(skills []character.Skill, rng *RNGStreams) ([]string, error) {
	counts := make([]int, len(skills))
	remainders := make([]int, len(skills))
	weightTotal := 0

	for _, skill := range skills {
		weightTotal += skill.Points * skill.Points
	}

	if weightTotal == 0 {
		return nil, fmt.Errorf("cannot seed training without starting points")
	}

	assigned := 0

	for i, skill := range skills {
		scaled := skill.Points * skill.Points * recentSkillLimit
		counts[i] = scaled / weightTotal
		remainders[i] = scaled % weightTotal
		assigned += counts[i]
	}

	order := make([]int, len(skills))

	for i := range order {
		order[i] = i
	}

	// This deliberately matches _scale_array's ascending remainder order.
	sort.SliceStable(order, func(i, j int) bool {
		return remainders[order[i]] < remainders[order[j]]
	})

	for i := 0; assigned < recentSkillLimit; i++ {
		counts[order[i]]++
		assigned++
	}

	queue := make([]string, 0, recentSkillLimit)

	for remaining := recentSkillLimit; remaining > 0; remaining-- {
		choice, err := rng.Intn("skill", remaining)

		if err != nil {
			return nil, err
		}

		for i, count := range counts {
			if choice < count {
				queue = append(queue, skills[i].ID)
				counts[i]--

				break
			}

			choice -= count
		}
	}

	return queue, nil
}
