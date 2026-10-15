package game

import "errors"

// SetSkillTrainingMode changes the player's training choice without time.
func (g *Game) SetSkillTrainingMode(manual bool) error {
	_, err := g.scripts.Policy("character.training_mode", map[string]any{
		"manual": manual,
	})

	if err != nil {
		return err
	}

	return g.scripts.ApplyPending()
}

// ChangeSkillTraining updates one skill through the effective Lua ruleset.
func (g *Game) ChangeSkillTraining(id string, focus bool) error {
	result, err := g.scripts.Policy("character.training_change", map[string]any{
		"id":    id,
		"focus": focus,
	})

	if err != nil {
		return err
	}

	if changed, ok := result["changed"].(bool); ok && !changed {
		message, _ := result["message"].(string)

		if message == "" {
			message = "skill training change rejected"
		}

		return errors.New(message)
	}

	return g.scripts.ApplyPending()
}
