package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/rules"
	"github.com/gravestench/akara"
)

type combatSystem struct {
	positions *akara.Store[ecs.Position]
	intents   *akara.Store[ecs.Intent]
	combat    *akara.Store[ecs.Combatant]
	health    *akara.Store[ecs.Health]
	levels    map[int]*Level
	rng       *RNGStreams
	turn      *TurnContext
	player    akara.Entity
}

func (s *combatSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)
	if !found || intent.Kind != ecs.IntentMelee {
		return nil
	}
	position, found := s.positions.Get(s.turn.Actor)
	if !found {
		return fmt.Errorf("attacker %d has no position", s.turn.Actor)
	}
	target, found := s.levels[position.LevelID].ActorAt(position.X+intent.DX, position.Y+intent.DY)
	if !found || target == s.turn.Actor {
		return fmt.Errorf("attacker %d has no target", s.turn.Actor)
	}
	attack, found := s.combat.Get(s.turn.Actor)
	if !found {
		return fmt.Errorf("attacker %d has no combat stats", s.turn.Actor)
	}
	victim, found := s.health.Get(target)
	if !found {
		return fmt.Errorf("target %d has no health", target)
	}
	roll, err := s.rng.Intn("melee", attack.BaseDamage+1)
	if err != nil {
		return err
	}
	damage := rules.MeleeDamage(attack.BaseDamage, roll)
	victim.Current -= damage
	if victim.Current < 0 {
		victim.Current = 0
	}
	if s.turn.Actor == s.player {
		s.turn.Events = append(s.turn.Events, Event{Kind: "combat", Text: fmt.Sprintf("You hit the rat for %d damage.", damage)})
	} else {
		s.turn.Events = append(s.turn.Events, Event{Kind: "combat", Text: fmt.Sprintf("The rat hits you for %d damage.", damage)})
	}
	return nil
}

type deathSystem struct {
	health *akara.Store[ecs.Health]
	player akara.Entity
	turn   *TurnContext
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
			s.turn.Deaths = append(s.turn.Deaths, entity)
			s.turn.Events = append(s.turn.Events, Event{Kind: "death", Text: "The rat dies."})
		}
	}
	return nil
}
