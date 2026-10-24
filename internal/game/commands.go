package game

import (
	"errors"
	"fmt"
	"time"

	"crawl/internal/ecs"
	"crawl/internal/save"
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
	CommandFire
	CommandThrow
	CommandMemorise
	CommandCancelMemorise
	CommandCast
	CommandForceCast
	CommandAbility
	CommandEvokeWand
	CommandRead
	CommandPray
	CommandEvokeItem
)

const CommandCancelVampire = CommandCancelMemorise

type Command struct {
	Kind      CommandKind
	DX        int
	DY        int
	ItemID    uint64
	Quantity  int
	SpellID   string
	AbilityID string
	TargetID  string
	Cancelled bool
	Forced    bool
}

type Event struct {
	Kind string
	Text string
}

type StepResult struct {
	Spent              Aut
	Events             []Event
	View               View
	Confirmation       string
	ConfirmationTarget string
	Selection          *SelectionRequest
}

// TurnContext is updated by Game before ordered Akara systems run.
type TurnContext struct {
	Actor          akara.Entity
	ResolvedIntent ecs.IntentKind
	ResolvedItemID akara.Entity

	Events []Event
}

func (g *Game) Step(command Command) (result StepResult, err error) {
	if outcome, err := g.outcome(); err != nil {
		return StepResult{}, err
	} else if outcome != "" {
		return StepResult{View: g.View()}, nil
	}

	revivalEvents, err := g.resumePendingRevival()

	if err != nil {
		return StepResult{}, err
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		return StepResult{}, fmt.Errorf("player %d has no position", g.player)
	}

	portalOrigin := *position

	// Lua ability preparation can commit a card effect that asks for travel.
	// Keep its pre-draw state until the destination is known to be valid.
	var abilityCheckpoint *save.Snapshot

	if command.Kind == CommandAbility {
		checkpoint := g.Snapshot()
		abilityCheckpoint = &checkpoint
	}

	prepared, err := g.prepareScriptCommand(command, position)

	if err != nil {
		return StepResult{}, err
	}

	if !prepared.spendsTime {
		prepared.response.Events = append(revivalEvents,
			prepared.response.Events...)

		return prepared.response, nil
	}

	forced, err := g.scripts.Policy("world.pending_forced_portal", nil)

	if err != nil {
		return StepResult{}, err
	}

	forcedPortalPotential, _ := forced["potential"].(bool)

	shaftRequest, pendingShaft, err := g.pendingShaft()

	if err != nil {
		return StepResult{}, err
	}

	var portal portalAction
	pendingStair := false

	if prepared.intent.Kind == ecs.IntentUpstairs ||
		prepared.intent.Kind == ecs.IntentDownstairs {
		if level := g.levels[position.LevelID]; level != nil {
			if link, found := level.StairAt(position.X, position.Y); found {
				pendingStair = link.Pending
			}
		}
	}

	if prepared.portal != nil ||
		pendingStair ||
		pendingShaft ||
		forcedPortalPotential {
		// First entry to a portal or generated branch changes floors,
		// actors, and RNG. A failed destination must restore the run.
		checkpoint := g.Snapshot()

		if abilityCheckpoint != nil &&
			(pendingShaft || prepared.portal != nil) {
			checkpoint = *abilityCheckpoint
		}

		defer func() {
			if portal != nil && portal.staged() != nil {
				err = errors.Join(err, portal.staged().rollback())
			}

			if err != nil {
				err = errors.Join(err, g.restoreCheckpoint(checkpoint))
				result = StepResult{}
			}
		}()

		if pendingShaft {
			portal, err = g.prepareShaftPortal(shaftRequest, position)

			if err != nil {
				return StepResult{}, err
			}
		} else if prepared.portal != nil {
			portal, err = g.preparePortal(prepared.portal, position)

			if err != nil {
				return StepResult{}, err
			}
		}
	}

	if err := g.populateStairDestination(prepared.intent.Kind, position); err != nil {
		return StepResult{}, err
	}

	for _, event := range prepared.response.Events {
		g.messages = append(g.messages, event.Text)
	}

	// Timing policies run inside this action context. Source projectile
	// practice happens before the delay roll and remains visible to systems.
	g.scripts.BeginAction()

	if _, err := g.scripts.Policy("command.action_start", map[string]any{
		"waited_explicitly": prepared.waitedExplicitly,
		"portal_travel":     prepared.portal != nil,
		"stair_travel": prepared.portal == nil &&
			(prepared.intent.Kind == ecs.IntentUpstairs ||
				prepared.intent.Kind == ecs.IntentDownstairs),
	}); err != nil {
		g.scripts.DiscardPending()

		return StepResult{}, err
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return StepResult{}, err
	}

	cost, err := g.playerActionCost(prepared)

	if err != nil {
		g.scripts.DiscardPending()

		return StepResult{}, err
	}

	intent := prepared.intent

	if combat, found := g.stores.Combat.Get(g.player); found {
		combat.ShieldBlocks = 0
	}

	startAut := g.currentAut
	events, err := g.runActionStarted(g.player, intent, cost, "movement")

	if err != nil {
		return StepResult{}, err
	}

	events = append(prepared.response.Events, events...)
	events = append(revivalEvents, events...)

	if portal == nil && forcedPortalPotential {
		forced, forcedErr := g.scripts.Policy(
			"world.pending_forced_portal", nil)

		if forcedErr != nil {
			return StepResult{}, forcedErr
		}

		if plan, found := forced["portal"].(map[string]any); found {
			current, positioned := g.stores.Positions.Get(g.player)

			if !positioned {
				return StepResult{}, fmt.Errorf("forced portal player has no position")
			}

			portal, err = g.preparePortal(plan, current)

			if err != nil {
				return StepResult{}, err
			}
		}
	}

	if outcome, err := g.outcome(); err != nil {
		return StepResult{}, err
	} else if outcome != "" {
		// A terminal result can stop travel before the portal commits. The
		// source wave is action-local even if the player never arrives.
		if portal != nil {
			if err := g.transferPortalFollowers(portalOrigin); err != nil {
				return StepResult{}, err
			}
		}

		playerTurn, found := g.stores.PlayerTurn.Get(g.player)

		if !found {
			return StepResult{}, fmt.Errorf("player has no terminal turn clock")
		}

		g.currentAut = Aut(playerTurn.NextAut)

		return StepResult{
			Spent:  cost,
			Events: events,
			View:   g.View(),
		}, nil
	}

	if portal != nil {
		// The player action's events were copied before portal.commit.
		// Lua travel policies can emit more messages while moving the player;
		// publish only those new events after the stair announcement.
		before := len(g.turn.Events)
		travelEvent, travelErr := portal.commit(g)

		if travelErr != nil {
			return StepResult{}, travelErr
		}

		if err := g.transferPortalFollowers(portalOrigin); err != nil {
			return StepResult{}, err
		}

		if travelEvent.Text != "" {
			events = append(events, travelEvent)
			g.messages = append(g.messages, travelEvent.Text)
		}

		for _, event := range g.turn.Events[before:] {
			events = append(events, event)
			g.messages = append(g.messages, event.Text)
		}
	}

	if arrived, found := g.stores.Positions.Get(g.player); found &&
		arrived.LevelID != position.LevelID {
		before := len(g.turn.Events)

		if err := g.activateTransition(position.LevelID, arrived.LevelID, startAut); err != nil {
			return StepResult{}, err
		}

		for _, event := range g.turn.Events[before:] {
			events = append(events, event)
			g.messages = append(g.messages, event.Text)
		}
	}

	if portal != nil && portal.retiredLevelID() != 0 {
		if err := g.retireLevel(portal.retiredLevelID()); err != nil {
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

	result, err = g.finishTurn(startAut, cost, events)

	if err != nil ||
		result.View.PlayerDead {
		return result, err
	}

	return g.finishScriptEquipment(command, prepared, result)
}

// preparedCommand separates validation and no-time responses from action
// execution. Only an accepted action reaches the scheduler and spends aut.
type preparedCommand struct {
	intent           ecs.Intent
	response         StepResult
	spendsTime       bool
	equipment        *ecs.EquipmentDelay
	attackTarget     akara.Entity
	portal           map[string]any
	waitedExplicitly bool
}

func spendingCommand(intent ecs.Intent, cost Aut) preparedCommand {
	return preparedCommand{
		intent:     intent,
		spendsTime: true,
	}
}

// playerActionCost chooses speed once after a command is accepted. Melee
// and wielding then apply their own source timing rules to that speed.
func (g *Game) playerActionCost(prepared preparedCommand) (Aut, error) {
	decision, err := g.scripts.Policy("command.timing", map[string]any{
		"attack_target": prepared.attackTarget != 0,
		"intent_kind":   int(prepared.intent.Kind),
		"item_id":       uint64(prepared.intent.ItemID),
		"ability_id":    prepared.intent.AbilityID,
	})

	if err != nil {
		return 0, err
	}

	cost, err := decisionInteger(decision, "cost")

	return Aut(cost), err
}

func freeCommand(response StepResult) preparedCommand {
	return preparedCommand{
		response: response,
	}
}

// finishTurn resumes the scheduled monster phase after a level-up prompt.
// The player action has already spent its aut and advanced its turn clock.
func (g *Game) finishTurn(startAut, cost Aut, events []Event) (StepResult, error) {
	const monsterCost Aut = 10
	position, located := g.stores.Positions.Get(g.player)

	if !located {
		return StepResult{}, fmt.Errorf("player has no position for scheduling")
	}

	activeLevelID := position.LevelID

	if err := g.scheduler.Grant(activeLevelID, cost); err != nil {
		return StepResult{}, err
	}

	for !g.playerDead() {
		actor, ready, err := g.scheduler.NextReady(activeLevelID)

		if err != nil {
			return StepResult{}, err
		}

		if !ready {
			break
		}

		monsterEvents, err := g.runAction(actor, ecs.Intent{}, monsterCost, "monster")

		if err != nil {
			return StepResult{}, err
		}

		events = append(events, monsterEvents...)

		if g.stores.MonsterEnergy.Has(actor) {
			if err := g.scheduler.SpendSelected(actor, ecs.Intent{
				Kind:   g.turn.ResolvedIntent,
				ItemID: g.turn.ResolvedItemID,
			}); err != nil {
				return StepResult{}, err
			}
		}

		arrived, found := g.stores.Positions.Get(g.player)

		if found && arrived.LevelID != activeLevelID {
			before := len(g.turn.Events)

			if err := g.activateTransition(activeLevelID, arrived.LevelID,
				startAut+cost); err != nil {
				return StepResult{}, err
			}

			for _, event := range g.turn.Events[before:] {
				events = append(events, event)
				g.messages = append(g.messages, event.Text)
			}

			break
		}
	}

	playerTurn, found := g.stores.PlayerTurn.Get(g.player)

	if !found {
		return StepResult{}, fmt.Errorf("player has no turn clock")
	}

	g.currentAut = Aut(playerTurn.NextAut)

	if !g.playerDead() {
		arrived, found := g.stores.Positions.Get(g.player)

		if !found {
			return StepResult{}, fmt.Errorf("player has no position after turn")
		}

		activeLevel := g.levels[arrived.LevelID]

		if activeLevel == nil {
			return StepResult{}, fmt.Errorf("player is on missing level %d", arrived.LevelID)
		}

		if err := g.runWorldPolicy("world.zot_clock", map[string]any{
			"level_id":    arrived.LevelID,
			"branch_id":   activeLevel.BranchID,
			"elapsed_aut": int64(cost),
		}); err != nil {
			return StepResult{}, err
		}
	}

	if err := g.runWorldPolicy("world.age_corpses", map[string]any{
		"level_id":  activeLevelID,
		"start_aut": int64(startAut),
		"end_aut":   int64(startAut + cost),
	}); err != nil {
		return StepResult{}, err
	}

	fieldLevelID := activeLevelID

	if arrived, found := g.stores.Positions.Get(g.player); found {
		fieldLevelID = arrived.LevelID
	}

	if err := g.runWorldPolicy("world.cloud_field", map[string]any{
		"level_id":    fieldLevelID,
		"elapsed_aut": int64(cost),
	}); err != nil {
		return StepResult{}, err
	}

	if err := g.runWorldPolicy("world.fog_machines", map[string]any{
		"source_level_id":      activeLevelID,
		"destination_level_id": fieldLevelID,
		"elapsed_aut":          int64(cost),
		"enter":                fieldLevelID != activeLevelID,
	}); err != nil {
		return StepResult{}, err
	}

	if err := g.runWorldPolicy("world.lugonu_corruption", map[string]any{
		"level_id":    activeLevelID,
		"elapsed_aut": int64(cost),
	}); err != nil {
		return StepResult{}, err
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
	g.scripts.BeginAction()

	return g.runActionStarted(actor, intent, cost, phase)
}

// runActionStarted preserves signals emitted while pricing a player action.
func (g *Game) runActionStarted(
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

	if err != nil {
		g.scripts.DiscardPending()

		return nil, fmt.Errorf("%s actor %d: %w", phase, actor, err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return nil, fmt.Errorf("%s actor %d Lua changes: %w", phase, actor, err)
	}

	resolved, producedIntent := g.stores.Intents.Get(actor)

	if !producedIntent {
		if actor == g.player || g.stores.Actors.Has(actor) {
			return nil, fmt.Errorf("%s actor %d produced no intent", phase, actor)
		}

		// A status or terrain effect can kill the active monster before its
		// intent resolves. It has no remaining energy to spend.
		resolved = &ecs.Intent{Kind: ecs.IntentWait}
	}

	g.turn.ResolvedIntent = resolved.Kind
	g.turn.ResolvedItemID = resolved.ItemID

	if producedIntent {
		g.stores.Intents.Remove(actor)
	}

	if actor == g.player {
		playerTurn, found := g.stores.PlayerTurn.Get(actor)

		if !found {
			return nil, fmt.Errorf("player %d has no turn clock", actor)
		}

		playerTurn.NextAut += int64(cost)
		playerTurn.Count++
	}

	events := append([]Event(nil), g.turn.Events...)

	for _, event := range events {
		g.messages = append(g.messages, event.Text)
	}

	return events, nil
}
