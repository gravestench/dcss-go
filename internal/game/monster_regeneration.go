package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

// monsterRegenerationSystem runs before a monster chooses its action.
// The supported HD-1 and HD-2 animals have a one-in-25 natural roll; a worm's
// M_FAST_REGEN heals one point without a draw. Source: mon-act.cc:125-160,1724.
type monsterRegenerationSystem struct {
	actors  *akara.Store[ecs.Actor]
	health  *akara.Store[ecs.Health]
	ai      *akara.Store[ecs.MonsterAI]
	catalog content.Catalog
	rng     monster.Roller
	turn    *TurnContext
}

func (s *monsterRegenerationSystem) Update(_ *akara.World, _ time.Duration) error {
	entity := s.turn.Actor

	if !s.ai.Has(entity) {
		return nil
	}

	actor, found := s.actors.Get(entity)

	if !found {
		return fmt.Errorf("regenerating monster %d has no actor", entity)
	}

	health, found := s.health.Get(entity)

	if !found ||
		health.Current < 0 ||
		health.Max <= 0 ||
		health.Current > health.Max {
		return fmt.Errorf("regenerating monster %d has invalid health", entity)
	}

	if health.Current == 0 {
		return nil
	}

	if health.Current == health.Max {
		return nil
	}

	if _, err := ordinaryAnimal(s.catalog, actor.KindID); err != nil {
		return err
	}

	profile, _ := character.OrdinaryAnimalProfile(actor.KindID)

	if profile.FastRegen {
		health.Current++

		return nil
	}

	// monster.cc:2934-2942 resolves to one at HD 1 and 2.
	if profile.HitDice < 1 || profile.HitDice > 2 {
		return fmt.Errorf("unsupported natural regeneration for %s", actor.KindID)
	}

	roll, err := s.rng.Intn("monster_regen", 25)

	if err != nil {
		return err
	}

	if roll == 0 {
		health.Current++
	}

	return nil
}
