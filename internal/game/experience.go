package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"github.com/gravestench/akara"
)

func (g *Game) awardAnimalExperience(animalID akara.Entity, maxHP int) error {
	actor, found := g.stores.Actors.Get(animalID)
	if !found || !isOrdinaryAnimal(actor.KindID) {
		return fmt.Errorf("unsupported experience source %d", animalID)
	}
	animal, err := g.ordinaryAnimal(actor.KindID)
	if err != nil {
		return err
	}
	amount, err := character.OrdinaryAnimalExperience(animal, maxHP)
	if err != nil {
		return err
	}
	progress, found := g.stores.Progression.Get(g.player)
	if !found || progress.TotalXP < 0 || progress.TotalXP+amount >= 9 {
		return fmt.Errorf("invalid fixed Dungeon experience state")
	}
	progress.TotalXP += amount
	return nil
}
