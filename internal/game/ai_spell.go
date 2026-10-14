package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// chooseEndoplasmSpell handles the first supported monster spellbook.
// Freeze can only target an adjacent foe. Source selection compares
// frequency >= the 0..199 roll, so frequency 70 covers 71 draws.
func (s *monsterDecisionSystem) chooseEndoplasmSpell(
	entity akara.Entity,
	position ecs.Position,
	player ecs.Position,
) (string, bool, error) {
	actor, found := s.actors.Get(entity)

	if !found {
		return "", false, fmt.Errorf("monster %d has no actor for spell choice", entity)
	}

	if actor.KindID != "MONS_ENDOPLASM" ||
		!adjacentActors(position, player) {
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

	if len(slots) != 1 || slots[0].SpellID != "SPELL_FREEZE" {
		return "", false, fmt.Errorf("unsupported endoplasm spellbook %s", definition.SpellbookID)
	}

	roll, err := s.rng.Intn("monster_spell", 200)

	if err != nil {
		return "", false, err
	}

	return slots[0].SpellID, roll <= slots[0].Frequency, nil
}
