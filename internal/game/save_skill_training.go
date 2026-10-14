package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
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
	progress := record.Skills

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

	species, err := catalog.Species("SP_HUMAN")

	if err != nil {
		return err
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

	starting := make(map[string]int, len(profile.Skills))

	for _, skill := range profile.Skills {
		starting[skill.ID] = skill.Points
	}

	seenSkills := make(map[string]bool, len(progress.Entries))
	gainedPoints := 0

	for index, skill := range progress.Entries {
		if !known[skill.ID] || seenSkills[skill.ID] ||
			skill.Points < starting[skill.ID] ||
			skill.Points > maxHumanSkillPoints() {
			return fmt.Errorf("invalid player skill %s", skill.ID)
		}

		if index < len(profile.Skills) && skill.ID != profile.Skills[index].ID {
			return fmt.Errorf("starting player skill order changed at %d", index)
		}

		level, err := character.HumanSkillLevel(skill.Points)

		if err != nil || skill.Level != level {
			return fmt.Errorf("invalid player skill level for %s", skill.ID)
		}

		seenSkills[skill.ID] = true
		gainedPoints += skill.Points - starting[skill.ID]
	}

	if gainedPoints > training.SpentXP {
		return fmt.Errorf("player skill points exceed spent skill experience")
	}

	for _, skill := range profile.Skills {
		if !seenSkills[skill.ID] {
			return fmt.Errorf("missing starting skill %s", skill.ID)
		}
	}

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
