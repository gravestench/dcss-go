package character

import (
	"fmt"

	"dcrawl-go/internal/content"
)

// Skill keeps both the displayed level and the source-derived training points.
type Skill struct {
	ID     string `json:"id"`
	Level  int    `json:"level"`
	Points int    `json:"points"`
}

func resolveChosenWeaponSkill(kind content.ItemDef, species content.SpeciesDef) (string, error) {
	if kind.Class != "OBJ_WEAPONS" || kind.WeaponSkill == "" {
		return "", fmt.Errorf("weapon %s has no usable weapon skill", kind.ID)
	}

	if aptitude, found := species.Aptitudes[kind.WeaponSkill]; !found ||
		!aptitude.Allowed {
		return "", fmt.Errorf(
			"weapon %s has unsupported skill %s for %s",
			kind.ID,
			kind.WeaponSkill,
			species.ID,
		)
	}

	return kind.WeaponSkill, nil
}

// humanSkillPoints follows skills.cc:2047-2083 for levels below the first
// cost breakpoint. Human's aptitude factor is one at the supported start.
func humanSkillPoints(level int) (int, error) {
	if level < 1 || level > 9 {
		return 0, fmt.Errorf("unsupported Human starting skill level %d", level)
	}

	needed, _ := SkillPointsNeeded(level, 0)

	return needed + 1, nil
}

// SupportedFighterSpecies identifies species whose Fighter start and innate
// rules are implemented in the current Dungeon slice.
func SupportedFighterSpecies(speciesID string) bool {
	switch speciesID {
	case "SP_HUMAN", "SP_HILL_ORC", "SP_DEEP_ELF", "SP_MINOTAUR":
		return true
	}

	return false
}

func SupportedFighterStart(speciesID, jobID string) bool {
	return jobID == "JOB_FIGHTER" && SupportedFighterSpecies(speciesID)
}

// StartingSkills resolves Fighter's SK_WEAPON grant after the weapon choice.
func StartingSkills(c content.Catalog, speciesID, jobID, weaponID string) ([]Skill, error) {
	if !SupportedFighterStart(speciesID, jobID) {
		return nil, fmt.Errorf("unsupported starting skills for %s/%s", speciesID, jobID)
	}

	if err := ValidateWeaponChoice(c, speciesID, jobID, weaponID); err != nil {
		return nil, err
	}

	species, err := c.Species(speciesID)

	if err != nil {
		return nil, err
	}

	job, err := c.Job(jobID)

	if err != nil {
		return nil, err
	}

	weaponSkill := "SK_UNARMED_COMBAT"

	if weaponID != "WPN_UNARMED" {
		kind, err := c.Item(weaponID)

		if err != nil {
			return nil, err
		}

		weaponSkill, err = resolveChosenWeaponSkill(kind, species)

		if err != nil {
			return nil, err
		}
	}

	skills := make([]Skill, 0, len(job.Skills))
	seen := map[string]bool{}

	for _, grant := range job.Skills {
		id := grant.ID

		if id == "SK_WEAPON" {
			id = weaponSkill
		}

		aptitude, found := species.Aptitudes[id]

		if !found || !aptitude.Allowed {
			return nil, fmt.Errorf("%s/%s cannot train %s", speciesID, jobID, id)
		}

		if seen[id] {
			return nil, fmt.Errorf("%s/%s has duplicate starting skill %s", speciesID, jobID, id)
		}

		seen[id] = true

		points, err := humanSkillPoints(grant.Level)

		if err != nil {
			return nil, fmt.Errorf("%s/%s %s: %w", speciesID, jobID, id, err)
		}

		level, err := reassessedStartingLevel(points, aptitude.Value)

		if err != nil {
			return nil, fmt.Errorf("%s/%s %s: %w", speciesID, jobID, id, err)
		}

		skills = append(skills, Skill{
			ID:     id,
			Level:  level,
			Points: points,
		})
	}

	return skills, nil
}

// reassess_starting_skills in skills.cc uses a strict greater-than check.
// Runtime skill training uses its own threshold comparison.
func reassessedStartingLevel(points, aptitude int) (int, error) {
	level := 0

	for next := 1; next <= 8; next++ {
		needed, err := SkillPointsNeeded(next, aptitude)

		if err != nil {
			return 0, err
		}

		if points <= needed {
			break
		}

		level = next
	}

	return level, nil
}
