package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/character"
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
	CommandDrop
	CommandWield
	CommandOpenDoor
	CommandCloseDoor
	CommandWear
	CommandTakeOff
	CommandContinueEquipment
	CommandCancelEquipment
)

type Command struct {
	Kind     CommandKind
	DX       int
	DY       int
	ItemID   uint64
	Quantity int
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
	Actor          akara.Entity
	ResolvedIntent ecs.IntentKind

	Events   []Event
	Deaths   []akara.Entity
	Practice []string

	Pickup  akara.Entity
	Consume akara.Entity
	Drop    *pendingItemDrop
	Wield   *pendingItemWield

	PlayerKill akara.Entity
	Corpse     *pendingCorpse

	StairFrom int
	StairTo   int
}

func (g *Game) Step(command Command) (StepResult, error) {
	if g.playerDead() {
		return g.noTimeEvent(Event{
			Kind: "death",
			Text: "You die.",
		}), nil
	}

	if delay, active := g.stores.Equipment.Get(g.player); active {
		if command.Kind == CommandCancelEquipment {
			message := "You stop putting on your armour."

			if delay.Phase == "remove" {
				message = "You stop removing your armour."
			}

			g.stores.Equipment.Remove(g.player)

			return g.noTime(message), nil
		}

		if command.Kind != CommandInspect &&
			command.Kind != CommandContinueEquipment {
			return g.noTime("You are changing your equipment. Press Esc to stop."), nil
		}
	} else if command.Kind == CommandContinueEquipment ||
		command.Kind == CommandCancelEquipment {
		return g.noTime("You are not changing your equipment."), nil
	}

	if progress, found := g.stores.Progression.Get(g.player); found &&
		progress.PendingStatLevel != 0 && command.Kind != CommandInspect {
		return g.noTime("Choose Strength, Intelligence, or Dexterity first."), nil
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		return StepResult{}, fmt.Errorf("player %d has no position", g.player)
	}

	level := g.levels[position.LevelID]
	prepared, err := g.preparePlayerCommand(command, *position, level)

	if err != nil {
		return StepResult{}, err
	}

	if !prepared.spendsTime {
		return prepared.response, nil
	}

	cost, err := g.playerActionCost(prepared)

	if err != nil {
		return StepResult{}, err
	}

	intent := prepared.intent

	if combat, found := g.stores.Combat.Get(g.player); found {
		combat.ShieldBlocks = 0
	}

	startAut := g.currentAut
	events, err := g.runAction(g.player, intent, cost, "movement")

	if err != nil {
		return StepResult{}, err
	}

	if g.turn.StairFrom != 0 {
		from := g.levels[g.turn.StairFrom]
		to := g.levels[g.turn.StairTo]
		from.awaySinceAut = &startAut

		if err := g.activateLevel(to, startAut); err != nil {
			return StepResult{}, err
		}
	}

	if progress, found := g.stores.Progression.Get(g.player); found &&
		progress.PendingStatLevel != 0 {
		if err := g.refreshVisibility(); err != nil {
			return StepResult{}, err
		}

		return StepResult{
			Spent:  cost,
			Events: events,
			View:   g.View(),
		}, nil
	}

	result, err := g.finishTurn(startAut, cost, events)

	if err != nil ||
		result.View.PlayerDead {
		return result, err
	}

	return g.finishEquipmentCommand(command, prepared, result)
}

// preparedCommand separates validation and no-time responses from action
// execution. Only an accepted action reaches the scheduler and spends aut.
type preparedCommand struct {
	intent      ecs.Intent
	baseCost    Aut
	response    StepResult
	spendsTime  bool
	equipment   *ecs.EquipmentDelay
	attackDelay *combat.AttackDelayInput
}

func spendingCommand(intent ecs.Intent, cost Aut) preparedCommand {
	return preparedCommand{
		intent:     intent,
		baseCost:   cost,
		spendsTime: true,
	}
}

// playerActionCost chooses speed once after a command is accepted. Melee
// and wielding then apply their own source timing rules to that speed.
func (g *Game) playerActionCost(prepared preparedCommand) (Aut, error) {
	durations, found := g.stores.Durations.Get(g.player)

	if !found {
		return 0, fmt.Errorf("player has no duration state for action timing")
	}

	timeTaken, err := character.PlayerActionTime(g.rng, durations.HasteAut > 0)

	if err != nil {
		return 0, err
	}

	if prepared.attackDelay != nil {
		delay, err := combat.PlayerAttackDelay(g.rng, *prepared.attackDelay, timeTaken)

		return Aut(delay), err
	}

	if prepared.intent.Kind == ecs.IntentWield {
		return wieldActionCost(timeTaken, prepared.intent.ItemID), nil
	}

	if prepared.baseCost != 10 {
		return 0, fmt.Errorf("unsupported action cost %d", prepared.baseCost)
	}

	return Aut(timeTaken), nil
}

func freeCommand(response StepResult) preparedCommand {
	return preparedCommand{
		response: response,
	}
}

func (g *Game) preparePlayerCommand(
	command Command,
	position ecs.Position,
	level *Level,
) (preparedCommand, error) {
	const ordinaryCost Aut = 10

	switch command.Kind {
	case CommandInspect:
		return freeCommand(StepResult{View: g.View()}), nil

	case CommandMove:
		return g.prepareMoveCommand(command, position, level)

	case CommandUpstairs, CommandDownstairs:
		return g.prepareStairCommand(command.Kind, position, level), nil

	case CommandWait:
		return spendingCommand(ecs.Intent{Kind: ecs.IntentWait}, ordinaryCost), nil

	case CommandPickup:
		return g.preparePickupCommand(position), nil

	case CommandQuaff:
		return g.prepareQuaffCommand(command.ItemID)

	case CommandDrop:
		return g.prepareDropCommand(command)

	case CommandWield:
		return g.prepareWieldCommand(command.ItemID)

	case CommandWear, CommandTakeOff:
		return g.prepareEquipmentCommand(command)

	case CommandContinueEquipment:
		return spendingCommand(ecs.Intent{Kind: ecs.IntentWait}, ordinaryCost), nil

	case CommandOpenDoor, CommandCloseDoor:
		return g.prepareDoorCommand(command, position, level)

	default:
		return freeCommand(g.noTime("Unknown command.")), nil
	}
}

func (g *Game) prepareMoveCommand(
	command Command,
	position ecs.Position,
	level *Level,
) (preparedCommand, error) {
	if command.DX < -1 ||
		command.DX > 1 ||
		command.DY < -1 ||
		command.DY > 1 ||
		(command.DX == 0 && command.DY == 0) {
		return freeCommand(g.noTime("Invalid movement direction.")), nil
	}

	x := position.X + command.DX
	y := position.Y + command.DY

	if !level.inBounds(x, y) {
		return freeCommand(g.noTime("You cannot move there.")), nil
	}

	if level.terrain[y][x] == '+' {
		return spendingCommand(ecs.Intent{
			Kind: ecs.IntentOpenDoor,
			DX:   command.DX,
			DY:   command.DY,
		}, 10), nil
	}

	if !level.Walkable(x, y) {
		return freeCommand(g.noTime("You cannot move there.")), nil
	}

	var attackDelay *combat.AttackDelayInput

	if target, occupied := level.ActorAt(x, y); occupied {
		actor, found := g.stores.Actors.Get(target)

		if !found || !isOrdinaryAnimal(actor.KindID) {
			return preparedCommand{}, fmt.Errorf("unsupported player melee target %d", target)
		}

		input, err := newPlayerCombat(g).attackDelayInput(actor.KindID)

		if err != nil {
			return preparedCommand{}, err
		}

		attackDelay = &input
	}

	prepared := spendingCommand(ecs.Intent{
		Kind: ecs.IntentMove,
		DX:   command.DX,
		DY:   command.DY,
	}, 10)

	prepared.attackDelay = attackDelay

	return prepared, nil
}

func (g *Game) prepareStairCommand(
	kind CommandKind,
	position ecs.Position,
	level *Level,
) preparedCommand {
	wantedGlyph := byte('<')
	missingMessage := "There are no stairs up here."
	intentKind := ecs.IntentUpstairs

	if kind == CommandDownstairs {
		wantedGlyph = '>'
		missingMessage = "There are no stairs down here."
		intentKind = ecs.IntentDownstairs
	}

	link, linked := level.StairAt(position.X, position.Y)

	if level.terrain[position.Y][position.X] != wantedGlyph || !linked {
		return freeCommand(g.noTime(missingMessage))
	}

	if link.Unavailable != "" {
		return freeCommand(g.noTime(link.Unavailable))
	}

	return spendingCommand(ecs.Intent{Kind: intentKind}, 10)
}

func (g *Game) preparePickupCommand(position ecs.Position) preparedCommand {
	item, found := g.floorItemAt(position)

	if !found {
		return freeCommand(g.noTime("There is nothing to pick up here."))
	}

	if g.stores.Corpses.Has(item) {
		return freeCommand(g.noTime("You can't pick that up."))
	}

	return spendingCommand(ecs.Intent{Kind: ecs.IntentPickup}, 10)
}

func (g *Game) prepareQuaffCommand(itemID uint64) (preparedCommand, error) {
	entity := akara.Entity(itemID)
	item, found := g.stores.Items.Get(entity)
	carrier, carried := g.stores.CarriedBy.Get(entity)

	if !found ||
		!carried || carrier.Holder != g.player {
		return freeCommand(g.noTime("You are not carrying that potion.")), nil
	}

	kind, err := g.catalog.Item(item.KindID)

	if err != nil {
		return preparedCommand{}, err
	}

	if err := validateItemProperties(*item, kind); err != nil {
		return preparedCommand{}, fmt.Errorf("cannot quaff item %d: %w", entity, err)
	}

	if kind.Class != "OBJ_POTIONS" {
		return freeCommand(g.noTime("You cannot drink that.")), nil
	}

	if item.KindID != "POT_CURING" &&
		item.KindID != "POT_MIGHT" &&
		item.KindID != "POT_HASTE" &&
		item.KindID != "POT_HEAL_WOUNDS" {
		return freeCommand(g.noTime("That potion's effect is unavailable in the Go port.")), nil
	}

	if item.KindID == "POT_HEAL_WOUNDS" {
		health, found := g.stores.Health.Get(g.player)

		if !found {
			return preparedCommand{}, fmt.Errorf("player has no health for heal wounds")
		}

		if health.Current == health.Max {
			return freeCommand(g.noTime("Your health is already full.")), nil
		}
	}

	return spendingCommand(ecs.Intent{
		Kind:   ecs.IntentQuaff,
		ItemID: entity,
	}, 10), nil
}

// finishTurn resumes the scheduled monster phase after a level-up prompt.
// The player action has already spent its aut and advanced its turn clock.
func (g *Game) finishTurn(startAut, cost Aut, events []Event) (StepResult, error) {
	const monsterCost Aut = 10
	position, located := g.stores.Positions.Get(g.player)

	if !located {
		return StepResult{}, fmt.Errorf("player has no position for scheduling")
	}

	if err := g.scheduler.Grant(position.LevelID, cost); err != nil {
		return StepResult{}, err
	}

	for !g.playerDead() {
		actor, ready := g.scheduler.NextReady(position.LevelID)

		if !ready {
			break
		}

		monsterEvents, err := g.runAction(actor, ecs.Intent{}, monsterCost, "monster")

		if err != nil {
			return StepResult{}, err
		}

		events = append(events, monsterEvents...)

		if g.stores.MonsterEnergy.Has(actor) {
			if err := g.scheduler.Spend(actor, g.turn.ResolvedIntent); err != nil {
				return StepResult{}, err
			}
		}
	}

	playerTurn, found := g.stores.PlayerTurn.Get(g.player)

	if !found {
		return StepResult{}, fmt.Errorf("player has no turn clock")
	}

	g.currentAut = Aut(playerTurn.NextAut)

	if elapsed := corpseTickElapsed(startAut, startAut+cost); elapsed > 0 {
		position, found := g.stores.Positions.Get(g.player)

		if !found {
			return StepResult{}, fmt.Errorf("player has no position for corpse timer")
		}

		if err := g.corpseAging.TickLevel(position.LevelID, elapsed); err != nil {
			return StepResult{}, err
		}
	}

	if err := g.refreshVisibility(); err != nil {
		return StepResult{}, err
	}

	return StepResult{
		Spent:  cost,
		Events: events,
		View:   g.View(),
	}, nil
}

func (g *Game) noTime(message string) StepResult {
	return g.noTimeEvent(Event{
		Kind: "notice",
		Text: message,
	})
}

func (g *Game) noTimeEvent(event Event) StepResult {
	g.messages = append(g.messages, event.Text)

	return StepResult{
		Events: []Event{event},
		View:   g.View(),
	}
}

func (g *Game) playerDead() bool {
	health, found := g.stores.Health.Get(g.player)

	return !found || health.Current <= 0
}

// runAction is the only bridge from logical auts to Akara's duration argument.
func (g *Game) runAction(
	actor akara.Entity,
	intent ecs.Intent,
	cost Aut,
	phase string,
) ([]Event, error) {
	if intent.Kind != 0 {
		if _, err := g.stores.Intents.Set(actor, intent); err != nil {
			return nil, fmt.Errorf("%s actor %d intent: %w", phase, actor, err)
		}
	} else if g.stores.Intents.Has(actor) {
		return nil, fmt.Errorf("%s actor %d has a stale intent", phase, actor)
	}

	// Every system shares this context; reset all pending work for each actor.
	g.turn = TurnContext{Actor: actor}

	err := g.world.Update(time.Duration(cost))
	resolved, producedIntent := g.stores.Intents.Get(actor)
	var resolvedKind ecs.IntentKind

	if producedIntent {
		resolvedKind = resolved.Kind
	}

	g.stores.Intents.Remove(actor)

	if err != nil {
		return nil, fmt.Errorf("%s actor %d: %w", phase, actor, err)
	}

	if !producedIntent {
		return nil, fmt.Errorf("%s actor %d produced no intent", phase, actor)
	}

	g.turn.ResolvedIntent = resolvedKind

	buffer := akara.NewCommandBuffer()

	if item := g.turn.Pickup; item != 0 {
		// World.Update has completed; this is the structural pickup barrier.
		if err := g.applyPickup(actor, item, buffer); err != nil {
			return nil, fmt.Errorf("%s actor %d pickup item %d: %w", phase, actor, item, err)
		}
	}

	if g.turn.Drop != nil {
		if err := g.applyDrop(*g.turn.Drop, buffer); err != nil {
			return nil, fmt.Errorf("%s actor %d drop: %w", phase, actor, err)
		}
	}

	if g.turn.Wield != nil {
		if err := g.applyWield(*g.turn.Wield); err != nil {
			return nil, fmt.Errorf("%s actor %d wield: %w", phase, actor, err)
		}
	}

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

	if g.turn.Corpse != nil {
		if err := g.placeCorpse(*g.turn.Corpse); err != nil {
			return nil, fmt.Errorf("%s actor %d corpse: %w", phase, actor, err)
		}
	}

	if actor == g.player {
		playerTurn, found := g.stores.PlayerTurn.Get(actor)

		if !found {
			return nil, fmt.Errorf("player %d has no turn clock", actor)
		}

		playerTurn.NextAut += int64(cost)
	}

	events := append([]Event(nil), g.turn.Events...)

	for _, event := range events {
		g.messages = append(g.messages, event.Text)
	}

	return events, nil
}
