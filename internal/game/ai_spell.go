package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// chooseMonsterSpell handles the supported one-slot natural books. Source
// selection compares frequency >= the 0..199 roll, so a frequency of 60
// covers 61 draws.
func (s *monsterDecisionSystem) chooseMonsterSpell(
	entity akara.Entity,
	position ecs.Position,
	player ecs.Position,
) (string, bool, error) {
	actor, found := s.actors.Get(entity)

	if !found {
		return "", false, fmt.Errorf("monster %d has no actor for spell choice", entity)
	}

	spellID := ""

	switch actor.KindID {
	case "MONS_ENDOPLASM":
		if adjacentActors(position, player) {
			spellID = "SPELL_FREEZE"
		}

	case "MONS_DART_SLUG":
		level := s.levels[position.LevelID]

		if level != nil &&
			position.LevelID == player.LevelID &&
			level.ClearProjectilePath(position.X, position.Y, player.X, player.Y) {
			spellID = "SPELL_SLUG_DART"
		}
	}

	if spellID == "" {
		return "", false, nil
	}

	definition, err := s.catalog.Monster(actor.KindID)

	if err != nil {
		return "", false, err
	}

	slots, err := s.catalog.MonsterSpellbook(definition.SpellbookID)

	if err != nil {
		return "", false, err
	}

	if len(slots) != 1 || slots[0].SpellID != spellID {
		return "", false, fmt.Errorf("unsupported %s spellbook %s", actor.KindID, definition.SpellbookID)
	}

	roll, err := s.rng.Intn("monster_spell", 200)

	if err != nil {
		return "", false, err
	}

	return spellID, roll <= slots[0].Frequency, nil
}
