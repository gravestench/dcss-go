package game

import "errors"

// SpendPotionExperienceSkill delegates skill allocation to the Lua ruleset.
func (g *Game) SpendPotionExperienceSkill(id string) error {
	result, err := g.scripts.Policy("character.potion_experience_choose", map[string]any{
		"id": id,
	})

	if err != nil {
		return err
	}

	if spent, ok := result["spent"].(int64); !ok || spent == 0 {
		message, _ := result["message"].(string)

		if message == "" {
			message = "that skill cannot receive potion experience"
		}

		return errors.New(message)
	}

	return g.scripts.ApplyPending()
}
