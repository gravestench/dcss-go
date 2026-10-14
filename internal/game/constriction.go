package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// constrictSystem owns ongoing direct grips after movement and melee resolve.
// The player component is the sole live link between both actors.
type constrictSystem struct {
	player akara.Entity

	constricted *akara.Store[ecs.Constricted]
	actors      *akara.Store[ecs.Actor]
	health      *akara.Store[ecs.Health]
	positions   *akara.Store[ecs.Position]

	catalog content.Catalog
	fighter playerCombat
	roller  combat.Roller
	turn    *TurnContext
}

func newConstrictSystem(g *Game) *constrictSystem {
	return &constrictSystem{
		player: g.player,

		constricted: g.stores.Constricted,
		actors:      g.stores.Actors,
		health:      g.stores.Health,
		positions:   g.stores.Positions,

		catalog: g.catalog,
		fighter: newPlayerCombat(g),
		roller:  g.rng,
		turn:    &g.turn,
	}
}

func (s *constrictSystem) Update(_ *akara.World, _ time.Duration) error {
	grip, found := s.constricted.Get(s.player)

	if !found {
		return nil
	}

	playerHealth, playerAlive := s.health.Get(s.player)
	pythonHealth, pythonAlive := s.health.Get(grip.By)
	playerPos, playerLocated := s.positions.Get(s.player)
	pythonPos, pythonLocated := s.positions.Get(grip.By)

	if !playerAlive ||
		!pythonAlive ||
		playerHealth.Current <= 0 ||
		pythonHealth.Current <= 0 ||
		!playerLocated ||
		!pythonLocated ||
		!adjacentActors(*playerPos, *pythonPos) {
		s.constricted.Remove(s.player)

		return nil
	}

	if s.turn.Actor != grip.By {
		return nil
	}

	actor, found := s.actors.Get(grip.By)

	if !found {
		return fmt.Errorf("constrictor %d has no actor", grip.By)
	}

	definition, err := s.catalog.Monster(actor.KindID)

	if err != nil {
		return err
	}

	defense, err := s.fighter.defense()

	if err != nil {
		return err
	}

	damage, err := combat.ConstrictDamage(
		s.roller,
		definition.Attacks[1].Damage,
		defense.AC,
		actor.Speed,
	)

	if err != nil {
		return err
	}

	playerHealth.Current = max(0, playerHealth.Current-damage)
	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: fmt.Sprintf("The %s constricts you.", definition.Name),
	})

	if playerHealth.Current == 0 {
		s.constricted.Remove(s.player)
	}

	return nil
}

func adjacentActors(a, b ecs.Position) bool {
	if a.LevelID != b.LevelID {
		return false
	}

	dx, dy := a.X-b.X, a.Y-b.Y

	if dx < 0 {
		dx = -dx
	}

	if dy < 0 {
		dy = -dy
	}

	return dx <= 1 &&
		dy <= 1 &&
		(dx != 0 || dy != 0)
}
