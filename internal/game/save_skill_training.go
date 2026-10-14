package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

const recentSkillLimit = 100

func validateSavedSkillTraining(
	record save.EntityRecord,
	profile character.StartProfile,
	catalog content.Catalog,
	totalXP int,
) error {
	training := record.SkillTraining

	if err := validateSavedTrainingExperience(training, totalXP); err != nil {
		return err
	}

	known, err := supportedSavedHumanSkills(catalog)

	if err != nil {
		return err
	}

	seen, err := validateSavedSkillProgress(
		record.Skills.Entries,
		profile.Skills,
		known,
		training.SpentXP,
	)

	if err != nil {
		return err
	}

	return validateSavedTrainingChoices(training, known, seen)
}

func validateSavedTrainingExperience(training *ecs.SkillTraining, totalXP int) error {
	if training.AvailableXP < 0 || training.SpentXP < 0 ||
		int64(training.AvailableXP)+int64(training.SpentXP) != int64(totalXP)*10 {
		return fmt.Errorf("player skill experience disagrees with earned XP")
	}

	costLevel, err := character.SkillCostLevel(training.SpentXP)

	if err != nil || training.CostLevel != costLevel {
		return fmt.Errorf("invalid player skill cost level %d", training.CostLevel)
	}

	if len(training.RecentPractice) > recentSkillLimit ||
		len(training.RecentAll) > recentSkillLimit {
		return fmt.Errorf("player skill practice history exceeds %d", recentSkillLimit)
	}

	return nil
}

func supportedSavedHumanSkills(catalog content.Catalog) (map[string]bool, error) {
	species, err := catalog.Species("SP_HUMAN")

	if err != nil {
		return nil, err
	}

	known := make(map[string]bool)

	for _, column := range catalog.Presentation().SkillColumns {
		for _, id := range column {
			if id != "" && species.Aptitudes[id].Allowed &&
				supportsMeleeSkillTraining(id) {
				known[id] = true
			}
		}
	}

	return known, nil
}

func validateSavedSkillProgress(
	entries []character.Skill,
	startingSkills []character.Skill,
	known map[string]bool,
	spentXP int,
) (map[string]bool, error) {
	starting := make(map[string]int, len(startingSkills))

	for _, skill := range startingSkills {
		starting[skill.ID] = skill.Points
	}

	seenSkills := make(map[string]bool, len(entries))
	gainedPoints := 0

	for index, skill := range entries {
		if !known[skill.ID] || seenSkills[skill.ID] ||
			skill.Points < starting[skill.ID] ||
			skill.Points > maxHumanSkillPoints() {
			return nil, fmt.Errorf("invalid player skill %s", skill.ID)
		}

		if index < len(startingSkills) && skill.ID != startingSkills[index].ID {
			return nil, fmt.Errorf("starting player skill order changed at %d", index)
		}

		level, err := character.HumanSkillLevel(skill.Points)

		if err != nil || skill.Level != level {
			return nil, fmt.Errorf("invalid player skill level for %s", skill.ID)
		}

		seenSkills[skill.ID] = true
		gainedPoints += skill.Points - starting[skill.ID]
	}

	if gainedPoints > spentXP {
		return nil, fmt.Errorf("player skill points exceed spent skill experience")
	}

	for _, skill := range startingSkills {
		if !seenSkills[skill.ID] {
			return nil, fmt.Errorf("missing starting skill %s", skill.ID)
		}
	}

	return seenSkills, nil
}

func validateSavedTrainingChoices(
	training *ecs.SkillTraining,
	known map[string]bool,
	seenSkills map[string]bool,
) error {
	seenSettings := make(map[string]bool, len(training.Settings))

	for _, setting := range training.Settings {
		if !known[setting.ID] || !seenSkills[setting.ID] ||
			seenSettings[setting.ID] || setting.Focused && !setting.Enabled {
			return fmt.Errorf("invalid player skill training setting %s", setting.ID)
		}

		seenSettings[setting.ID] = true
	}

	if len(seenSettings) != len(seenSkills) {
		return fmt.Errorf("player skills lack training settings")
	}

	for _, id := range training.RecentPractice {
		if !known[id] {
			return fmt.Errorf("unknown practiced skill %s", id)
		}
	}

	for _, id := range training.RecentAll {
		if !known[id] {
			return fmt.Errorf("unknown recent skill %s", id)
		}
	}

	return nil
}

func maxHumanSkillPoints() int {
	points, _ := character.HumanSkillPointsNeeded(character.HumanMaxSkillLevel)

	return points
}
