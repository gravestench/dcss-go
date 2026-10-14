package character

import "dcrawl-go/internal/content"

// StartProfile contains the source-backed values established at turn zero.
type StartProfile struct {
	Attributes Attributes
	Skills     []Skill
	MaxHP      int
	MaxMP      int
}

// ScaledSkill projects stored points at a source skill scale and aptitude.
func ScaledSkill(skill Skill, scale, aptitude int) (int, error) {
	if _, err := SkillPointsNeeded(1, aptitude); err != nil {
		return 0, err
	}

	if skill.Level == MaxSkillLevel {
		return skill.Level * scale, nil
	}

	previous, err := SkillPointsNeeded(skill.Level, aptitude)

	if err != nil {
		return 0, err
	}

	next, err := SkillPointsNeeded(skill.Level+1, aptitude)

	if err != nil {
		return 0, err
	}

	return skill.Level*scale + (skill.Points-previous)*scale/(next-previous), nil
}

// BuildStartProfile calculates a supported Fighter normal Dungeon start.
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

	hp, err := BaseMaxHP(1, species, skills)

	if err != nil {
		return StartProfile{}, err
	}

	mp, err := BaseMaxMP(1, species)

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
