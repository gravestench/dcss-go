package character

import "dcrawl-go/internal/content"

// StartProfile contains the source-backed values established at turn zero.
type StartProfile struct {
	Attributes Attributes
	Skills     []Skill
	MaxHP      int
	MaxMP      int
}

// ScaledSkill projects stored Human skill points at a source skill scale.
func ScaledSkill(skill Skill, scale int) int {
	if skill.Level == HumanMaxSkillLevel {
		return skill.Level * scale
	}

	previous, _ := HumanSkillPointsNeeded(skill.Level)
	next, _ := HumanSkillPointsNeeded(skill.Level + 1)

	return skill.Level*scale + (skill.Points-previous)*scale/(next-previous)
}

// BuildStartProfile calculates the supported Human/Fighter normal Dungeon start.
func BuildStartProfile(c content.Catalog, speciesID, jobID, weaponID string) (StartProfile, error) {
	skills, err := StartingSkills(c, speciesID, jobID, weaponID)

	if err != nil {
		return StartProfile{}, err
	}

	attributes, err := BaseStatSum(c, speciesID, jobID)

	if err != nil {
		return StartProfile{}, err
	}

	species, err := c.Species(speciesID)

	if err != nil {
		return StartProfile{}, err
	}

	hp, err := HumanMaxHP(1, species, skills)

	if err != nil {
		return StartProfile{}, err
	}

	mp, err := HumanMaxMP(1, species)

	if err != nil {
		return StartProfile{}, err
	}

	return StartProfile{
		Attributes: attributes,
		Skills:     skills,
		MaxHP:      hp,
		MaxMP:      mp,
	}, nil
}
