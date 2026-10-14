package game

import (
	"fmt"
	"sort"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
)

// scaledTrainingWeights follows skills.cc:_scale_array. Automatic mode
// distributes the leftover percent by ascending remainder, as the source
// does; manual mode keeps the truncated shares.
func scaledTrainingWeights(
	skills []character.Skill,
	training *ecs.SkillTraining,
) []int {
	weights := trainingWeights(skills, training)
	total := 0

	for _, weight := range weights {
		total += weight
	}

	if total == 0 {
		return weights
	}

	type remainder struct {
		index int
		value int
	}

	var remainders []remainder
	scaledTotal := 0

	for index, weight := range weights {
		if weight == 0 {
			continue
		}

		product := weight * 100
		weights[index] = product / total
		scaledTotal += weights[index]

		if rest := product % total; rest > 0 {
			remainders = append(remainders, remainder{
				index: index,
				value: rest,
			})
		}
	}

	if !training.Manual {
		sort.SliceStable(remainders, func(i, j int) bool {
			return remainders[i].value < remainders[j].value
		})

		for _, rest := range remainders {
			if scaledTotal == 100 {
				break
			}

			weights[rest.index]++
			scaledTotal++
		}
	}

	return weights
}

func trainingWeights(
	skills []character.Skill,
	training *ecs.SkillTraining,
) []int {
	weights := make([]int, len(skills))
	hadPractice := false

	for i, skill := range skills {
		setting := trainingSetting(training, skill.ID)

		if setting == nil ||
			!setting.Enabled ||
			skill.Level == character.HumanMaxSkillLevel {
			continue
		}

		weight := 1

		if training.Manual {
			if setting.Focused {
				weight = 2
			}
		} else {
			weight = max(
				countRecentSkill(training.RecentPractice, skill.ID),
				countRecentSkill(training.RecentAll, skill.ID),
			)

			if setting.Focused {
				weight *= 2
			}

			hadPractice = hadPractice || weight > 0
		}

		weights[i] = weight
	}

	if !training.Manual && !hadPractice {
		for i, skill := range skills {
			setting := trainingSetting(training, skill.ID)

			if setting != nil &&
				setting.Enabled &&
				skill.Level < character.HumanMaxSkillLevel {
				weights[i] = 1

				if setting.Focused {
					weights[i] = 2
				}
			}
		}
	}

	if !training.Manual {
		for i, skill := range skills {
			setting := trainingSetting(training, skill.ID)

			if setting == nil ||
				!setting.Enabled ||
				!setting.Focused ||
				skill.Level == character.HumanMaxSkillLevel {
				continue
			}

			// DCSS gives a rare focused skill extra weight before scaling.
			if weights[i] < 20 {
				weights[i] += 5 * (5 - weights[i]/4)
			}
		}
	}

	return weights
}

func skillTrainingPercent(
	skills []character.Skill,
	training *ecs.SkillTraining,
) map[string]int {
	weights := scaledTrainingWeights(skills, training)
	percent := make(map[string]int, len(skills))

	for i, skill := range skills {
		percent[skill.ID] = weights[i]
	}

	return percent
}

func countRecentSkill(queue []string, id string) int {
	count := 0

	for _, candidate := range queue {
		if candidate == id {
			count++
		}
	}

	return count
}

func chooseWeightedSkill(weights []int, rng *RNGStreams) (int, error) {
	total := 0

	for _, weight := range weights {
		total += weight
	}

	if total == 0 {
		return -1, nil
	}

	choice, err := rng.Intn("skill", total)

	if err != nil {
		return -1, err
	}

	for i, weight := range weights {
		if choice < weight {
			return i, nil
		}

		choice -= weight
	}

	return -1, fmt.Errorf("skill weight selection escaped total %d", total)
}
