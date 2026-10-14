package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
	"github.com/gravestench/akara"
)

// regenerationSystem follows player_reacts after duration decay. Its counters
// advance once per player action, even while monsters take intervening turns.
type regenerationSystem struct {
	game *Game
	turn *TurnContext
}

func (s *regenerationSystem) Update(_ *akara.World, delta time.Duration) error {
	if s.turn.Actor != s.game.player {
		return nil
	}
	g := s.game
	health, hasHealth := g.stores.Health.Get(g.player)
	magic, hasMagic := g.stores.Magic.Get(g.player)
	progress, hasProgress := g.stores.Regeneration.Get(g.player)
	if !hasHealth || !hasMagic || !hasProgress {
		return fmt.Errorf("player lacks health, magic, or regeneration state")
	}
	state, err := character.Regenerate(g.rng, character.Vitality{
		HP: health.Current, MaxHP: health.Max, MP: magic.Current, MaxMP: magic.Max,
		HPProgress: progress.HPProgress, MPProgress: progress.MPProgress,
	}, int(delta))
	if err != nil {
		return err
	}
	health.Current, magic.Current = state.HP, state.MP
	progress.HPProgress, progress.MPProgress = state.HPProgress, state.MPProgress
	return nil
}
