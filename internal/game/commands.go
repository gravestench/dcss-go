package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type CommandKind uint8

const (
	CommandMove CommandKind = iota + 1
	CommandUpstairs
	CommandDownstairs
	CommandPickup
	CommandWait
	CommandInspect
)

type Command struct {
	Kind CommandKind
	DX   int
	DY   int
}

type Event struct {
	Kind string
	Text string
}

type StepResult struct {
	Spent  Aut
	Events []Event
	View   View
}

// TurnContext is updated by Game before ordered Akara systems run.
type TurnContext struct {
	Actor  akara.Entity
	Events []Event
}

func (g *Game) Step(command Command) (StepResult, error) {
	position, found := g.stores.Positions.Get(g.player)
	if !found {
		return StepResult{}, fmt.Errorf("player %d has no position", g.player)
	}
	level := g.levels[position.LevelID]
	var intent ecs.Intent
	const cost Aut = 10
	switch command.Kind {
	case CommandInspect:
		return StepResult{View: g.View()}, nil
	case CommandMove:
		if command.DX < -1 || command.DX > 1 || command.DY < -1 || command.DY > 1 || (command.DX == 0 && command.DY == 0) {
			return g.noTime("Invalid movement direction."), nil
		}
		x, y := position.X+command.DX, position.Y+command.DY
		if !level.Walkable(x, y) {
			return g.noTime("You cannot move there."), nil
		}
		intent = ecs.Intent{Kind: ecs.IntentMove, DX: command.DX, DY: command.DY}
	case CommandUpstairs:
		if level.terrain[position.Y][position.X] != '<' || position.LevelID != 2 {
			return g.noTime("There are no stairs up here."), nil
		}
		intent = ecs.Intent{Kind: ecs.IntentUpstairs}
	case CommandDownstairs:
		if level.terrain[position.Y][position.X] != '>' || position.LevelID != 1 {
			return g.noTime("There are no stairs down here."), nil
		}
		intent = ecs.Intent{Kind: ecs.IntentDownstairs}
	case CommandWait:
		intent = ecs.Intent{Kind: ecs.IntentWait}
	case CommandPickup:
		return g.noTime("There is nothing to pick up here."), nil
	default:
		return g.noTime("Unknown command."), nil
	}
	events, err := g.runAction(g.player, intent, cost, "movement")
	if err != nil {
		return StepResult{}, err
	}
	actor, _ := g.stores.Actors.Get(g.player)
	g.currentAut = Aut(actor.NextAut)
	return StepResult{Spent: cost, Events: events, View: g.View()}, nil
}

func (g *Game) noTime(message string) StepResult {
	event := Event{Kind: "notice", Text: message}
	g.messages = append(g.messages, message)
	return StepResult{Events: []Event{event}, View: g.View()}
}

// runAction is the only bridge from logical auts to Akara's duration argument.
func (g *Game) runAction(actor akara.Entity, intent ecs.Intent, cost Aut, phase string) ([]Event, error) {
	if _, err := g.stores.Intents.Set(actor, intent); err != nil {
		return nil, fmt.Errorf("%s actor %d intent: %w", phase, actor, err)
	}
	g.turn.Actor = actor
	g.turn.Events = nil
	err := g.world.Update(time.Duration(cost))
	g.stores.Intents.Remove(actor)
	if err != nil {
		return nil, fmt.Errorf("%s actor %d: %w", phase, actor, err)
	}
	if g.stores.Actors.Has(actor) {
		if err := g.scheduler.ScheduleAfter(actor, cost); err != nil {
			return nil, fmt.Errorf("%s actor %d schedule: %w", phase, actor, err)
		}
	}
	events := append([]Event(nil), g.turn.Events...)
	for _, event := range events {
		g.messages = append(g.messages, event.Text)
	}
	return events, nil
}
