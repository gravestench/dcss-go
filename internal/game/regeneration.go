package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// regenerationSystem follows player_reacts after duration decay. Its counters
// advance once per player action, even while monsters take intervening turns.
type regenerationSystem struct {
	player       akara.Entity
	health       *akara.Store[ecs.Health]
	magic        *akara.Store[ecs.Magic]
	regeneration *akara.Store[ecs.Regeneration]
	rng          character.Roller
	turn         *TurnContext
}

func (s *regenerationSystem) Update(_ *akara.World, delta time.Duration) error {
	if s.turn.Actor != s.player {
		return nil
	}
	health, hasHealth := s.health.Get(s.player)
	magic, hasMagic := s.magic.Get(s.player)
	progress, hasProgress := s.regeneration.Get(s.player)
	if !hasHealth || !hasMagic || !hasProgress {
		return fmt.Errorf("player lacks health, magic, or regeneration state")
	}
	state, err := character.Regenerate(s.rng, character.Vitality{
		HP:         health.Current,
		MaxHP:      health.Max,
		MP:         magic.Current,
		MaxMP:      magic.Max,
		HPProgress: progress.HPProgress,
		MPProgress: progress.MPProgress,
	}, int(delta))
	if err != nil {
		return err
	}
	health.Current, magic.Current = state.HP, state.MP
	progress.HPProgress, progress.MPProgress = state.HPProgress, state.MPProgress
	return nil
}
