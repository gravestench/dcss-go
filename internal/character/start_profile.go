package character

import (
	"fmt"

	"dcrawl-go/internal/content"
)

// StartProfile contains the source-backed values established at turn zero.
type StartProfile struct {
	Attributes Attributes
	Skills     []Skill
	MaxHP      int
	MaxMP      int
}

func scaledStartingSkill(skill Skill, scale int) int {
	previous := 25 * skill.Level * (skill.Level + 1)
	next := 25 * (skill.Level + 1) * (skill.Level + 2)
	return skill.Level*scale + (skill.Points-previous)*scale/(next-previous)
}

func startingHP(species content.SpeciesDef, skills []Skill) (int, error) {
	var fighting *Skill
	for i := range skills {
		if skills[i].ID == "SK_FIGHTING" {
			fighting = &skills[i]
			break
		}
	}
	if fighting == nil {
		return 0, fmt.Errorf("%s start lacks Fighting skill", species.ID)
	}
	// player.cc:get_real_hp at XL 1, with no mutations, drains, or item effects.
	hp := 1*11/2 + 8
	hp += scaledStartingSkill(*fighting, 5)/70 + (scaledStartingSkill(*fighting, 3)+1)/2
	hp = hp * (10 + species.HP) / 10
	if hp < 1 {
		hp = 1
	}
	return hp, nil
}

func startingMP(species content.SpeciesDef) int {
	// player.cc:get_real_mp at XL 1: Fighter has neither Spellcasting nor
	// Invocations, and Human has no magic mutations or equipment effects.
	mp := 1 + species.MPMod
	if mp < 0 {
		return 0
	}
	return mp
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
	hp, err := startingHP(species, skills)
	if err != nil {
		return StartProfile{}, err
	}
	return StartProfile{Attributes: attributes, Skills: skills, MaxHP: hp, MaxMP: startingMP(species)}, nil
}
