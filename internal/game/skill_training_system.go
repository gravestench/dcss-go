package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type skillTrainingSystem struct {
	player       akara.Entity
	skills       *akara.Store[ecs.Skills]
	training     *akara.Store[ecs.SkillTraining]
	progression  *akara.Store[ecs.Progression]
	health       *akara.Store[ecs.Health]
	regeneration *akara.Store[ecs.Regeneration]
	catalog      content.Catalog
	rng          *RNGStreams
	turn         *TurnContext
}

func newSkillTrainingSystem(g *Game) *skillTrainingSystem {
	return &skillTrainingSystem{
		player:       g.player,
		skills:       g.stores.Skills,
		training:     g.stores.SkillTraining,
		progression:  g.stores.Progression,
		health:       g.stores.Health,
		regeneration: g.stores.Regeneration,
		catalog:      g.catalog,
		rng:          g.rng,
		turn:         &g.turn,
	}
}

func (s *skillTrainingSystem) Update(_ *akara.World, _ time.Duration) error {
	skills, hasSkills := s.skills.Get(s.player)
	training, hasTraining := s.training.Get(s.player)

	if !hasSkills || !hasTraining {
		return fmt.Errorf("player lacks skill training state")
	}

	for _, id := range s.turn.Practice {
		if err := s.recordPractice(skills, training, id); err != nil {
			return err
		}
	}

	fightingBefore := skillPoints(skills.Entries, "SK_FIGHTING")

	if err := s.spend(skills, training); err != nil {
		return err
	}

	if skillPoints(skills.Entries, "SK_FIGHTING") != fightingBefore {
		return s.recalculateFightingHP(skills.Entries)
	}

	return nil
}

func skillPoints(skills []character.Skill, id string) int {
	for _, skill := range skills {
		if skill.ID == id {
			return skill.Points
		}
	}

	return 0
}

func (s *skillTrainingSystem) recalculateFightingHP(skills []character.Skill) error {
	progress, hasProgress := s.progression.Get(s.player)
	health, hasHealth := s.health.Get(s.player)
	regeneration, hasRegeneration := s.regeneration.Get(s.player)

	if !hasProgress || !hasHealth || !hasRegeneration {
		return fmt.Errorf("player lacks Fighting HP state")
	}

	species, err := s.catalog.Species("SP_HUMAN")

	if err != nil {
		return err
	}

	nextHP, err := character.HumanMaxHP(progress.Level, species, skills)

	if err != nil {
		return err
	}

	rescaleHealth(health, regeneration, nextHP)

	return nil
}

func (s *skillTrainingSystem) recordPractice(
	skills *ecs.Skills,
	training *ecs.SkillTraining,
	id string,
) error {
	if !supportsMeleeSkillTraining(id) {
		return fmt.Errorf("unsupported Dungeon skill practice %s", id)
	}

	for _, skill := range skills.Entries {
		if skill.ID == id && skill.Level == character.HumanMaxSkillLevel {
			return nil
		}
	}

	species, err := s.catalog.Species("SP_HUMAN")

	if err != nil {
		return err
	}

	aptitude, known := species.Aptitudes[id]

	if !known || !aptitude.Allowed {
		return fmt.Errorf("invalid Human skill practice %s", id)
	}

	setting := trainingSetting(training, id)

	if setting == nil {
		skills.Entries = append(skills.Entries, character.Skill{
			ID: id,
		})

		training.Settings = append(training.Settings, ecs.SkillTrainingSetting{
			ID:      id,
			Enabled: !training.Manual,
		})

		setting = &training.Settings[len(training.Settings)-1]
	}

	training.RecentAll = appendRecentSkill(training.RecentAll, id)

	if setting.Enabled {
		training.RecentPractice = appendRecentSkill(training.RecentPractice, id)
	}

	return nil
}

func appendRecentSkill(queue []string, id string) []string {
	if len(queue) == recentSkillLimit {
		copy(queue, queue[1:])
		queue[len(queue)-1] = id

		return queue
	}

	return append(queue, id)
}

func trainingSetting(training *ecs.SkillTraining, id string) *ecs.SkillTrainingSetting {
	for i := range training.Settings {
		if training.Settings[i].ID == id {
			return &training.Settings[i]
		}
	}

	return nil
}

func (s *skillTrainingSystem) spend(
	skills *ecs.Skills,
	training *ecs.SkillTraining,
) error {
	for {
		cost, err := character.SkillPointCost(training.CostLevel)

		if err != nil {
			return err
		}

		if training.AvailableXP < cost {
			return nil
		}

		weights := trainingWeights(skills.Entries, training)
		chosen, err := chooseWeightedSkill(weights, s.rng)

		if err != nil {
			return err
		}

		if chosen < 0 {
			return nil
		}

		skill := &skills.Entries[chosen]
		skill.Points++
		training.AvailableXP -= cost
		training.SpentXP += cost

		level, err := character.HumanSkillLevel(skill.Points)

		if err != nil {
			return err
		}

		if level > skill.Level {
			skill.Level = level
			s.turn.Events = append(s.turn.Events, Event{
				Kind: "skill-up",
				Text: fmt.Sprintf("Your %s skill increases to level %d!", skill.ID, level),
			})
		}

		training.CostLevel, err = character.SkillCostLevel(training.SpentXP)

		if err != nil {
			return err
		}
	}
}
