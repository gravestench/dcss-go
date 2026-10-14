package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
)

const skillChunkXP = 2650

// spendBatch follows skills.cc:train_skills and _train_skills for a Human
// without manuals, training targets, or cross-training. The player component
// remains the only owner of the XP pools and skill points.
func (s *skillTrainingSystem) spendBatch(
	skills *ecs.Skills,
	training *ecs.SkillTraining,
) (int, error) {
	cost, err := character.SkillPointCost(training.CostLevel)

	if err != nil {
		return 0, err
	}

	if training.AvailableXP < cost {
		return 0, nil
	}

	batchXP, err := skillBatchLimit(training, cost)

	if err != nil {
		return 0, err
	}

	weights := scaledTrainingWeights(skills.Entries, training)
	shares, skipFirst := allocatedSkillShares(weights, batchXP, cost)
	order := make([]int, 0, len(weights))

	for index, weight := range weights {
		if weight > 0 {
			order = append(order, index)
		}
	}

	remaining := batchXP

	if !skipFirst {
		remaining, err = s.spendAllocatedShares(
			skills,
			training,
			shares,
			order,
			remaining,
		)

		if err != nil {
			return batchXP - remaining, err
		}
	}

	remaining, err = s.spendWeightedRemainder(
		skills,
		training,
		shares,
		skipFirst,
		remaining,
	)

	return batchXP - remaining, err
}

func (s *skillTrainingSystem) spendAllocatedShares(
	skills *ecs.Skills,
	training *ecs.SkillTraining,
	shares []int,
	order []int,
	remaining int,
) (int, error) {
	if err := shuffleTrainingOrder(order, s.rng); err != nil {
		return remaining, err
	}

	for _, index := range order {
		for shares[index] > 0 {
			spent, err := s.trainChunk(
				&skills.Entries[index],
				training,
				min(shares[index], remaining),
			)

			if err != nil {
				return remaining, err
			}

			if spent == 0 {
				break
			}

			shares[index] -= spent
			remaining -= spent

			if !trainableSkill(skills.Entries[index], training) {
				shares[index] = 0
			}
		}
	}

	return remaining, nil
}

func (s *skillTrainingSystem) spendWeightedRemainder(
	skills *ecs.Skills,
	training *ecs.SkillTraining,
	shares []int,
	skipFirst bool,
	remaining int,
) (int, error) {
	for remaining > 0 {
		cost, err := character.SkillPointCost(training.CostLevel)

		if err != nil {
			return remaining, err
		}

		if remaining < cost {
			break
		}

		chosen := -1

		if !skipFirst {
			chosen, err = chooseWeightedSkill(shares, s.rng)

			if err != nil {
				return remaining, err
			}
		}

		if chosen < 0 || !trainableSkill(skills.Entries[chosen], training) {
			chosen, err = chooseWeightedSkill(
				scaledTrainingWeights(skills.Entries, training),
				s.rng,
			)

			if err != nil {
				return remaining, err
			}
		}

		if chosen < 0 {
			break
		}

		spent, err := s.trainChunk(&skills.Entries[chosen], training, remaining)

		if err != nil {
			return remaining, err
		}

		if spent == 0 {
			break
		}

		remaining -= spent
		shares[chosen] = 0
	}

	return remaining, nil
}

func allocatedSkillShares(weights []int, batchXP, cost int) ([]int, bool) {
	shares := make([]int, len(weights))
	skipFirst := false

	for index, weight := range weights {
		if weight == 0 {
			continue
		}

		shares[index] = weight * batchXP / 100

		if shares[index] < cost {
			skipFirst = true
		}
	}

	return shares, skipFirst
}

func skillBatchLimit(training *ecs.SkillTraining, cost int) (int, error) {
	batch := training.AvailableXP

	if training.CostLevel == character.HumanMaxSkillLevel {
		return batch, nil
	}

	nextThreshold, err := character.HumanExperienceNeeded(training.CostLevel + 1)

	if err != nil {
		return 0, err
	}

	untilNext := 13*nextThreshold - training.SpentXP

	if untilNext <= 0 {
		return 0, fmt.Errorf("skill cost level lags spent XP")
	}

	return min(batch, untilNext+cost-1), nil
}

func shuffleTrainingOrder(order []int, rng *RNGStreams) error {
	for count := len(order); count > 1; count-- {
		index, err := rng.Intn("skill", count)

		if err != nil {
			return err
		}

		order[index], order[count-1] = order[count-1], order[index]
	}

	return nil
}

func trainableSkill(skill character.Skill, training *ecs.SkillTraining) bool {
	setting := trainingSetting(training, skill.ID)

	return setting != nil &&
		setting.Enabled &&
		skill.Level < character.HumanMaxSkillLevel
}

func (s *skillTrainingSystem) trainChunk(
	skill *character.Skill,
	training *ecs.SkillTraining,
	budget int,
) (int, error) {
	if !trainableSkill(*skill, training) {
		return 0, nil
	}

	cost, err := character.SkillPointCost(training.CostLevel)

	if err != nil {
		return 0, err
	}

	maximum, err := character.HumanSkillPointsNeeded(character.HumanMaxSkillLevel)

	if err != nil {
		return 0, err
	}

	limit := min(skillChunkXP, budget, training.AvailableXP)
	points := min(limit/cost, maximum-skill.Points)

	if points <= 0 {
		return 0, nil
	}

	spent := points * cost
	skill.Points += points
	training.AvailableXP -= spent
	training.SpentXP += spent

	level, err := character.HumanSkillLevel(skill.Points)

	if err != nil {
		return 0, err
	}

	for next := skill.Level + 1; next <= level; next++ {
		s.turn.Events = append(s.turn.Events, Event{
			Kind: "skill-up",
			Text: fmt.Sprintf("Your %s skill increases to level %d!", skill.ID, next),
		})
	}

	skill.Level = level
	training.CostLevel, err = character.SkillCostLevel(training.SpentXP)

	return spent, err
}
