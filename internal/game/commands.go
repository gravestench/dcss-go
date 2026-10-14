package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/combat"
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
	CommandQuaff
)

type Command struct {
	Kind   CommandKind
	DX     int
	DY     int
	ItemID uint64
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
	Actor      akara.Entity
	Events     []Event
	Deaths     []akara.Entity
	Pickup     akara.Entity
	Consume    akara.Entity
	PlayerKill akara.Entity
}

func (g *Game) Step(command Command) (StepResult, error) {
	if g.playerDead() {
		return g.noTimeEvent(Event{Kind: "death", Text: "You die."}), nil
	}
	position, found := g.stores.Positions.Get(g.player)
	if !found {
		return StepResult{}, fmt.Errorf("player %d has no position", g.player)
	}
	level := g.levels[position.LevelID]
	var intent ecs.Intent
	const monsterCost Aut = 10
	cost := monsterCost
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
		if target, occupied := level.ActorAt(x, y); occupied {
			actor, found := g.stores.Actors.Get(target)
			if !found || actor.KindID != "MONS_RAT" {
				return StepResult{}, fmt.Errorf("unsupported player melee target %d", target)
			}
			input, err := g.playerAttackDelayInput()
			if err != nil {
				return StepResult{}, err
			}
			delay, err := combat.PlayerAttackDelay(g.rng, input)
			if err != nil {
				return StepResult{}, err
			}
			cost = Aut(delay)
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
		if _, found := g.floorItemAt(*position); !found {
			return g.noTime("There is nothing to pick up here."), nil
		}
		intent = ecs.Intent{Kind: ecs.IntentPickup}
	case CommandQuaff:
		itemID := akara.Entity(command.ItemID)
		item, found := g.stores.Items.Get(itemID)
		carrier, carried := g.stores.CarriedBy.Get(itemID)
		if !found || !carried || carrier.Holder != g.player {
			return g.noTime("You are not carrying that potion."), nil
		}
		kind, err := g.catalog.Item(item.KindID)
		if err != nil {
			return StepResult{}, err
		}
		if err := validateItemProperties(*item, kind); err != nil {
			return StepResult{}, fmt.Errorf("cannot quaff item %d: %w", itemID, err)
		}
		if kind.Class != "OBJ_POTIONS" {
			return g.noTime("You cannot drink that."), nil
		}
		if item.KindID != "POT_CURING" && item.KindID != "POT_MIGHT" {
			return g.noTime("That potion's effect is unavailable in the Go port."), nil
		}
		intent = ecs.Intent{Kind: ecs.IntentQuaff, ItemID: itemID}
	default:
		return g.noTime("Unknown command."), nil
	}
	if combat, found := g.stores.Combat.Get(g.player); found {
		combat.ShieldBlocks = 0
	}
	events, err := g.runAction(g.player, intent, cost, "movement")
	if err != nil {
		return StepResult{}, err
	}
	for !g.playerDead() {
		actor, at, found := g.scheduler.Next()
		if !found || actor == g.player {
			g.currentAut = at
			break
		}
		g.currentAut = at
		intent, err := g.chooseMonsterIntent(actor)
		if err != nil {
			return StepResult{}, err
		}
		monsterEvents, err := g.runAction(actor, intent, monsterCost, "monster")
		if err != nil {
			return StepResult{}, err
		}
		events = append(events, Event{Kind: "monster", Text: "The rat acts."})
		events = append(events, monsterEvents...)
	}
	if err := g.refreshVisibility(); err != nil {
		return StepResult{}, err
	}
	return StepResult{Spent: cost, Events: events, View: g.View()}, nil
}

func (g *Game) noTime(message string) StepResult {
	return g.noTimeEvent(Event{Kind: "notice", Text: message})
}

func (g *Game) noTimeEvent(event Event) StepResult {
	g.messages = append(g.messages, event.Text)
	return StepResult{Events: []Event{event}, View: g.View()}
}

func (g *Game) playerDead() bool {
	health, found := g.stores.Health.Get(g.player)
	return !found || health.Current <= 0
}

// runAction is the only bridge from logical auts to Akara's duration argument.
func (g *Game) runAction(actor akara.Entity, intent ecs.Intent, cost Aut, phase string) ([]Event, error) {
	if _, err := g.stores.Intents.Set(actor, intent); err != nil {
		return nil, fmt.Errorf("%s actor %d intent: %w", phase, actor, err)
	}
	g.turn.Actor = actor
	g.turn.Events = nil
	g.turn.Deaths = nil
	g.turn.Pickup = 0
	g.turn.Consume = 0
	g.turn.PlayerKill = 0
	err := g.world.Update(time.Duration(cost))
	g.stores.Intents.Remove(actor)
	if err != nil {
		return nil, fmt.Errorf("%s actor %d: %w", phase, actor, err)
	}
	if item := g.turn.Pickup; item != 0 {
		// World.Update has completed; this is the structural pickup barrier.
		if !g.stores.Positions.Remove(item) {
			return nil, fmt.Errorf("%s actor %d pickup item %d lost its position", phase, actor, item)
		}
		if _, err := g.stores.CarriedBy.Set(item, ecs.CarriedBy{Holder: actor}); err != nil {
			return nil, fmt.Errorf("%s actor %d pickup item %d: %w", phase, actor, item, err)
		}
	}
	buffer := akara.NewCommandBuffer()
	if itemID := g.turn.Consume; itemID != 0 {
		item, found := g.stores.Items.Get(itemID)
		if !found || item.Quantity <= 0 {
			return nil, fmt.Errorf("%s actor %d consumed invalid item %d", phase, actor, itemID)
		}
		if item.Quantity == 1 {
			buffer.Destroy(g.world, itemID)
		} else {
			item.Quantity--
		}
	}
	for _, dead := range g.turn.Deaths {
		if position, found := g.stores.Positions.Get(dead); found {
			if err := g.levels[position.LevelID].RemoveActor(dead); err != nil {
				return nil, fmt.Errorf("%s actor %d death: %w", phase, actor, err)
			}
		}
		buffer.Destroy(g.world, dead)
	}
	if err := buffer.Apply(); err != nil {
		return nil, fmt.Errorf("%s actor %d deaths: %w", phase, actor, err)
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
