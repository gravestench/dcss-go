package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/save"
)

func (g *Game) validateSavedPlayer(
	record save.EntityRecord,
	playerID uint64,
) (savedPlayerValidation, error) {
	if record.Player.Name != "" {
		if err := character.ValidateName(record.Player.Name); err != nil {
			return savedPlayerValidation{}, fmt.Errorf("invalid saved player name: %w", err)
		}
	}

	if record.ID != playerID ||
		record.Actor == nil ||
		record.Actor.Speed != 10 ||
		record.Position == nil ||
		record.Health == nil ||
		record.Attributes == nil ||
		record.Skills == nil ||
		record.SkillTraining == nil ||
		record.Magic == nil ||
		record.PlayerTurn == nil ||
		record.PlayerTurn.NextAut < 0 ||
		record.MonsterEnergy != nil {
		return savedPlayerValidation{}, fmt.Errorf("invalid player entity %d", record.ID)
	}

	return savedPlayerValidation{
		nextAut: record.PlayerTurn.NextAut,
		alive:   record.Health.Current > 0,
		pendingStat: record.Progression != nil &&
			record.Progression.PendingStatLevel != 0,
	}, nil
}
