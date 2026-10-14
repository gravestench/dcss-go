package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type movementSystem struct {
	player akara.Entity

	positions   *akara.Store[ecs.Position]
	intents     *akara.Store[ecs.Intent]
	constricted *akara.Store[ecs.Constricted]
	actors      *akara.Store[ecs.Actor]
	energies    *akara.Store[ecs.MonsterEnergy]
	catalog     content.Catalog
	roller      combat.Roller
	levels      map[int]*Level
	turn        *TurnContext
}

func newMovementSystem(g *Game) *movementSystem {
	return &movementSystem{
		player: g.player,

		positions:   g.stores.Positions,
		intents:     g.stores.Intents,
		constricted: g.stores.Constricted,
		actors:      g.stores.Actors,
		energies:    g.stores.MonsterEnergy,
		catalog:     g.catalog,
		roller:      g.rng,
		levels:      g.levels,
		turn:        &g.turn,
	}
}

func (s *movementSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)

	if !found || intent.Kind != ecs.IntentMove {
		return nil
	}

	position, found := s.positions.Get(s.turn.Actor)

	if !found {
		return fmt.Errorf("moving actor %d has no position", s.turn.Actor)
	}

	level := s.levels[position.LevelID]
	x, y := position.X+intent.DX, position.Y+intent.DY

	if _, occupied := level.ActorAt(x, y); occupied {
		intent.Kind = ecs.IntentMelee

		return nil
	}

	if s.turn.Actor == s.player {
		escaped, err := s.attemptEscape(intent)

		if err != nil {
			return err
		}

		if !escaped {
			return nil
		}
	}

	return level.MoveActor(s.turn.Actor, x, y)
}

func (s *movementSystem) attemptEscape(intent *ecs.Intent) (bool, error) {
	grip, found := s.constricted.Get(s.player)

	if !found {
		return true, nil
	}

	actor, found := s.actors.Get(grip.By)

	if !found {
		return false, fmt.Errorf("constrictor %d has no actor", grip.By)
	}

	definition, err := s.catalog.Monster(actor.KindID)

	if err != nil {
		return false, err
	}

	grip.EscapeAttempts++
	escaped, err := combat.RollConstrictEscape(
		s.roller,
		grip.EscapeAttempts,
		definition.HD,
	)

	if err != nil {
		return false, err
	}

	if !escaped {
		intent.Kind = ecs.IntentWait
		s.turn.Events = append(s.turn.Events, Event{
			Kind: "combat",
			Text: fmt.Sprintf("The %s's grasp on you weakens, but your attempt to escape fails.", definition.Name),
		})

		return false, nil
	}

	s.constricted.Remove(s.player)

	energy, found := s.energies.Get(grip.By)

	if !found {
		return false, fmt.Errorf("constrictor %d has no energy", grip.By)
	}

	energy.Points -= 5
	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: fmt.Sprintf("You escape the %s's grasp.", definition.Name),
	})

	return true, nil
}

type stairSystem struct {
	positions *akara.Store[ecs.Position]
	intents   *akara.Store[ecs.Intent]
	levels    map[int]*Level
	turn      *TurnContext
}

func (s *stairSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)

	if !found ||
		(intent.Kind != ecs.IntentUpstairs &&
			intent.Kind != ecs.IntentDownstairs) {
		return nil
	}

	position, found := s.positions.Get(s.turn.Actor)

	if !found {
		return fmt.Errorf("stair actor %d has no position", s.turn.Actor)
	}

	from := s.levels[position.LevelID]

	if from == nil {
		return fmt.Errorf("stair actor %d has no level %d", s.turn.Actor, position.LevelID)
	}

	glyph := byte('>')

	if intent.Kind == ecs.IntentUpstairs {
		glyph = '<'
	}

	if from.terrain[position.Y][position.X] != glyph {
		return fmt.Errorf("stair actor %d is not on a %q stair", s.turn.Actor, glyph)
	}

	link, found := from.StairAt(position.X, position.Y)

	if !found {
		return fmt.Errorf(
			"stair actor %d has no link at (%d,%d)",
			s.turn.Actor,
			position.X,
			position.Y,
		)
	}

	if link.Unavailable != "" {
		return fmt.Errorf("stair actor %d tried an unavailable exit", s.turn.Actor)
	}

	to := s.levels[link.ToLevelID]

	if to == nil {
		return fmt.Errorf("destination floor %d is missing", link.ToLevelID)
	}

	x, y := link.ToX, link.ToY

	if !to.Walkable(x, y) {
		return fmt.Errorf("destination stair is blocked")
	}

	if _, occupied := to.ActorAt(x, y); occupied {
		return fmt.Errorf("destination stair is occupied")
	}

	oldX, oldY := position.X, position.Y

	if err := from.RemoveActor(s.turn.Actor); err != nil {
		return err
	}

	if err := to.PlaceActor(s.turn.Actor, x, y); err != nil {
		_ = from.PlaceActor(s.turn.Actor, oldX, oldY)

		return err
	}

	s.turn.StairFrom = from.ID
	s.turn.StairTo = to.ID
	s.turn.Events = append(s.turn.Events, Event{
		Kind: "stairs",
		Text: "You take the stairs.",
	})

	return nil
}
