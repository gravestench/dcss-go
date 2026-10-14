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

type deathSystem struct {
	actors      *akara.Store[ecs.Actor]
	positions   *akara.Store[ecs.Position]
	health      *akara.Store[ecs.Health]
	progression *akara.Store[ecs.Progression]
	catalog     content.Catalog
	rng         *RNGStreams
	player      akara.Entity
	turn        *TurnContext
}

func newDeathSystem(g *Game) *deathSystem {
	s := g.stores
	return &deathSystem{actors: s.Actors, positions: s.Positions, health: s.Health,
		progression: s.Progression, catalog: g.catalog, rng: g.rng, player: g.player, turn: &g.turn}
}

func (s *deathSystem) Update(_ *akara.World, _ time.Duration) error {
	for _, entity := range s.health.Entities() {
		health, _ := s.health.Get(entity)
		if health.Current > 0 {
			continue
		}
		if entity == s.player {
			s.turn.Events = append(s.turn.Events, Event{Kind: "death", Text: "You die."})
		} else {
			actor, found := s.actors.Get(entity)
			if !found {
				return fmt.Errorf("dead monster %d has no actor", entity)
			}
			definition, err := ordinaryAnimal(s.catalog, actor.KindID)
			if err != nil {
				return err
			}
			if entity == s.turn.PlayerKill {
				if err := s.awardAnimalExperience(definition, health.Max); err != nil {
					return err
				}
				if definition.LeavesCorpse {
					appearance, dropped, err := monster.RollCorpse(s.rng)
					if err != nil {
						return err
					}
					if dropped {
						position, found := s.positions.Get(entity)
						if !found {
							return fmt.Errorf("killed animal %d has no position", entity)
						}
						s.turn.Corpse = &pendingCorpse{MonsterID: actor.KindID, Position: *position, Appearance: appearance}
					}
				}
			}
			s.turn.Deaths = append(s.turn.Deaths, entity)
			s.turn.Events = append(s.turn.Events, Event{Kind: "death", Text: fmt.Sprintf("The %s dies.", definition.Name)})
		}
	}
	return nil
}

func (s *deathSystem) awardAnimalExperience(definition content.MonsterDef, maxHP int) error {
	amount, err := character.OrdinaryAnimalExperience(definition, maxHP)
	if err != nil {
		return err
	}
	progress, found := s.progression.Get(s.player)
	if !found || progress.TotalXP < 0 || progress.TotalXP+amount >= 9 {
		return fmt.Errorf("invalid fixed Dungeon experience state")
	}
	progress.TotalXP += amount
	return nil
}
