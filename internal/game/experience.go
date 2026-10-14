package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"github.com/gravestench/akara"
)

func (g *Game) awardRatExperience(ratID akara.Entity, maxHP int) error {
	actor, found := g.stores.Actors.Get(ratID)
	if !found || actor.KindID != "MONS_RAT" {
		return fmt.Errorf("unsupported experience source %d", ratID)
	}
	rat, err := g.catalog.Monster(actor.KindID)
	if err != nil {
		return err
	}
	amount, err := character.RatKillExperience(rat, maxHP)
	if err != nil {
		return err
	}
	progress, found := g.stores.Progression.Get(g.player)
	if !found || progress.TotalXP != 0 {
		return fmt.Errorf("invalid fixed Dungeon experience state")
	}
	progress.TotalXP += amount
	return nil
}
