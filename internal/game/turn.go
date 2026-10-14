package game

import (
	"fmt"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

// Aut is DCSS logical action time, independent of wall-clock durations.
type Aut int64

// TurnScheduler applies source monster energy only on the player's floor.
// It reads and changes Akara components; the catalog holds immutable costs.
type TurnScheduler struct {
	actors    *akara.Store[ecs.Actor]
	positions *akara.Store[ecs.Position]
	energies  *akara.Store[ecs.MonsterEnergy]
	catalog   content.Catalog
	rng       *RNGStreams
}

// Grant follows mon-act.cc:_pre_monster_move. Entity order fixes the draw
// order for monsters whose speed needs random rounding.
func (s TurnScheduler) Grant(levelID int, elapsed Aut) error {
	if elapsed <= 0 || int64(int(elapsed)) != int64(elapsed) {
		return fmt.Errorf("invalid player action time %d", elapsed)
	}

	for _, entity := range s.energies.Entities() {
		position, found := s.positions.Get(entity)

		if !found {
			return fmt.Errorf("monster %d has energy but no position", entity)
		}

		if position.LevelID != levelID {
			continue
		}

		actor, found := s.actors.Get(entity)

		if !found {
			return fmt.Errorf("monster %d has energy but no actor", entity)
		}

		energy, _ := s.energies.Get(entity)
		grant, err := monster.GainActionEnergy(s.rng, actor.Speed, int(elapsed))

		if err != nil {
			return fmt.Errorf("monster %d energy grant: %w", entity, err)
		}

		energy.Points += grant
	}

	return nil
}

// NextReady chooses the most energetic monster. Entity ID settles source
// pointer-order ties in a way that survives save and restore.
func (s TurnScheduler) NextReady(levelID int) (akara.Entity, bool) {
	var chosen akara.Entity
	most := monster.ActionEnergyThreshold - 1

	for _, entity := range s.energies.Entities() {
		position, found := s.positions.Get(entity)

		if !found || position.LevelID != levelID {
			continue
		}

		energy, _ := s.energies.Get(entity)

		if energy.Points > most ||
			(energy.Points == most && entity < chosen) {
			chosen = entity
			most = energy.Points
		}
	}

	return chosen, chosen != 0
}

// Spend uses the final intent after movement has turned a bump into melee.
func (s TurnScheduler) Spend(entity akara.Entity, intent ecs.IntentKind) error {
	actor, found := s.actors.Get(entity)

	if !found {
		return fmt.Errorf("monster %d has no actor", entity)
	}

	energy, found := s.energies.Get(entity)

	if !found || energy.Points < monster.ActionEnergyThreshold {
		return fmt.Errorf("monster %d lacks action energy", entity)
	}

	definition, err := s.catalog.Monster(actor.KindID)

	if err != nil {
		return err
	}

	cost, err := monster.ActionEnergyCost(definition.Energy, intent)

	if err != nil {
		return err
	}

	energy.Points -= cost

	return nil
}
