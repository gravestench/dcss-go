package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
)

// SetSkillTrainingMode changes the player's training choice without time.
func (g *Game) SetSkillTrainingMode(manual bool) error {
	training, found := g.stores.SkillTraining.Get(g.player)

	if !found {
		return fmt.Errorf("player has no skill training")
	}

	training.Manual = manual

	return nil
}

// ChangeSkillTraining changes one supported player skill without spending aut.
// Selecting a zero-point skill creates its ECS entry so later practice and
// earned experience have an authoritative place to accumulate.
func (g *Game) ChangeSkillTraining(id string, focus bool) error {
	if !supportsMeleeSkillTraining(id) {
		return fmt.Errorf("training %s is unavailable in this Dungeon slice", id)
	}

	player, found := g.stores.Players.Get(g.player)

	if !found {
		return fmt.Errorf("player has no selected species")
	}

	species, err := g.catalog.Species(player.SpeciesID)

	if err != nil {
		return err
	}

	if _, err := species.SkillAptitude(id); err != nil {
		return err
	}

	skills, hasSkills := g.stores.Skills.Get(g.player)
	training, hasTraining := g.stores.SkillTraining.Get(g.player)

	if !hasSkills || !hasTraining {
		return fmt.Errorf("player lacks skill training state")
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

	if focus {
		setting.Focused = !setting.Focused
		setting.Enabled = true
	} else {
		setting.Enabled = !setting.Enabled

		if !setting.Enabled {
			setting.Focused = false
		}
	}

	return nil
}

// Only actions implemented in the current Dungeon slice can earn practice.
// Keep the menu entries for other skills visible; selecting them explains why
// their training is unavailable until their gameplay systems are ported.
func supportsMeleeSkillTraining(id string) bool {
	switch id {
	case "SK_FIGHTING", "SK_SHORT_BLADES", "SK_LONG_BLADES",
		"SK_MACES_FLAILS", "SK_AXES", "SK_POLEARMS",
		"SK_UNARMED_COMBAT", "SK_ARMOUR", "SK_DODGING", "SK_SHIELDS":
		return true
	}

	return false
}
