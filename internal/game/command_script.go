package game

import (
	"fmt"

	"crawl/internal/ecs"
	"crawl/internal/vault"
	"github.com/gravestench/akara"
)

// prepareScriptCommand decodes the one generic Lua command decision. The
// command language and its validation live in the effective mod ruleset.
func (g *Game) prepareScriptCommand(
	command Command,
	position *ecs.Position,
) (_ preparedCommand, err error) {
	defer func() {
		if err != nil {
			g.scripts.DiscardPending()
		}
	}()

	activePanIDs := []any{}

	if g.panState != nil &&
		g.panState.ActiveLevelID == position.LevelID {
		for _, id := range g.levels[position.LevelID].VaultIDs() {
			activePanIDs = append(activePanIDs, id)
		}
	}

	beforeEvents := len(g.turn.Events)
	decision, err := g.scripts.Policy("command.prepare", map[string]any{
		"pan_state":             luaPanState(g.panState),
		"hell_state":            luaHellState(g.hellState),
		"pan_current_vault_ids": activePanIDs,
		"kind":                  int(command.Kind),
		"dx":                    command.DX,
		"dy":                    command.DY,
		"item_id":               command.ItemID,
		"quantity":              command.Quantity,
		"spell_id":              command.SpellID,
		"ability_id":            command.AbilityID,
		"target_id":             command.TargetID,
		"cancelled":             command.Cancelled,
		"forced":                command.Forced,
		"pending_vault_item":    g.pendingVaultItemAt(position),
	})

	if err != nil {
		g.turn.Events = g.turn.Events[:beforeEvents]

		return preparedCommand{}, err
	}

	// Lua can resolve a committed card while preparing its one timed
	// intent. Preserve those emitted events across runActionStarted, which
	// resets the turn context before Akara systems run.
	preparationEvents := append([]Event(nil),
		g.turn.Events[beforeEvents:]...)

	g.turn.Events = g.turn.Events[:beforeEvents]

	freePrepared := func(result StepResult) preparedCommand {
		result.Events = append(preparationEvents, result.Events...)

		for _, event := range preparationEvents {
			g.messages = append(g.messages, event.Text)
		}

		return freeCommand(result)
	}

	if selection, found := decision["selection"]; found {
		if decision["intent"] != nil ||
			decision["message"] != nil ||
			decision["confirmation"] != nil {
			return preparedCommand{}, fmt.Errorf("Lua selection conflicts with another decision")
		}

		request, err := selectionFromDecision(selection)

		if err != nil {
			return preparedCommand{}, err
		}

		if err := g.scripts.ApplyPending(); err != nil {
			return preparedCommand{}, err
		}

		return freePrepared(StepResult{
			Selection: request,
			View:      g.View(),
		}), nil
	}

	if confirmation, found := decision["confirmation"].(string); found {
		if confirmation == "" {
			return preparedCommand{}, fmt.Errorf("Lua command has empty confirmation")
		}

		target, _ := decision["confirmation_id"].(string)

		if err := g.scripts.ApplyPending(); err != nil {
			return preparedCommand{}, err
		}

		return freePrepared(StepResult{
			Confirmation:       confirmation,
			ConfirmationTarget: target,
			View:               g.View(),
		}), nil
	}

	if message, found := decision["message"].(string); found {
		kind, _ := decision["event_kind"].(string)

		if kind == "" {
			kind = "notice"
		}

		if err := g.scripts.ApplyPending(); err != nil {
			return preparedCommand{}, err
		}

		event := Event{
			Kind: kind,
			Text: message,
		}

		return freePrepared(g.noTimeEvent(event)), nil
	}

	if portal, found := decision["portal"]; found {
		if decision["intent"] != nil ||
			decision["selection"] != nil ||
			decision["message"] != nil ||
			decision["confirmation"] != nil {
			return preparedCommand{}, fmt.Errorf("Lua portal conflicts with another decision")
		}

		values, okay := portal.(map[string]any)

		if !okay {
			return preparedCommand{}, fmt.Errorf("Lua portal is not a record")
		}

		cost, err := decisionInteger(decision, "cost")

		if err != nil {
			return preparedCommand{}, err
		}

		if cost <= 0 {
			return preparedCommand{}, fmt.Errorf("Lua portal has invalid action cost")
		}

		prepared := spendingCommand(ecs.Intent{Kind: ecs.IntentWait}, Aut(cost))

		prepared.portal = values
		prepared.response.Events = preparationEvents

		return prepared, nil
	}

	if _, found := decision["intent"]; !found {
		return freePrepared(StepResult{View: g.View()}), nil
	}

	values, ok := decision["intent"].(map[string]any)

	if !ok {
		return preparedCommand{}, fmt.Errorf("Lua command intent is not a record")
	}

	kind, err := decisionInteger(values, "kind")

	if err != nil {
		return preparedCommand{}, err
	}

	intent := ecs.Intent{
		Kind: ecs.IntentKind(kind),
	}

	intent.DX, _ = optionalDecisionInteger(values, "dx")
	intent.DY, _ = optionalDecisionInteger(values, "dy")
	intent.Quantity, _ = optionalDecisionInteger(values, "quantity")
	intent.ItemID, err = decisionEntity(values["item_id"])

	if err != nil {
		return preparedCommand{}, err
	}

	intent.SpellID, _ = values["spell_id"].(string)
	intent.AbilityID, _ = values["ability_id"].(string)
	intent.TargetID, _ = values["target_id"].(string)
	intent.Cancelled, _ = values["cancelled"].(bool)
	intent.Forced, _ = values["forced"].(bool)

	cost, err := decisionInteger(decision, "cost")

	if err != nil {
		return preparedCommand{}, err
	}

	prepared := spendingCommand(intent, Aut(cost))

	prepared.waitedExplicitly, _ = decision["explicit_wait"].(bool)

	events, err := commandDecisionEvents(decision["events"])

	if err != nil {
		return preparedCommand{}, err
	}

	prepared.response.Events = append(preparationEvents, events...)

	if values, found := decision["delay"].(map[string]any); found {
		delay, err := equipmentDelayFromDecision(values)

		if err != nil {
			return preparedCommand{}, err
		}

		prepared.equipment = &delay
	}

	if target, found := decision["attack_target"].(akara.Entity); found {
		prepared.attackTarget = target
	}

	// Lua may spend a card or save a completed choice while preparing an
	// action. Commit those changes before BeginAction clears its staging
	// area for the timed Akara system pass.
	if err := g.scripts.ApplyPending(); err != nil {
		return preparedCommand{}, err
	}

	return prepared, nil
}

func (g *Game) pendingVaultItemAt(position *ecs.Position) string {
	if position == nil {
		return ""
	}

	level := g.levels[position.LevelID]

	if level == nil {
		return ""
	}

	for _, record := range level.vaultRecords {
		if record.Kind == vault.KindItem &&
			record.Pending &&
			record.X == position.X &&
			record.Y == position.Y {
			return record.Identity
		}
	}

	return ""
}

func commandDecisionEvents(value any) ([]Event, error) {
	if value == nil {
		return nil, nil
	}

	rows, ok := value.([]any)

	if !ok {
		return nil, fmt.Errorf("Lua command events are not a list")
	}

	events := make([]Event, 0, len(rows))

	for index, row := range rows {
		fields, ok := row.(map[string]any)

		if !ok {
			return nil, fmt.Errorf("Lua command event %d is not a record", index+1)
		}

		kind, kindOK := fields["kind"].(string)
		message, messageOK := fields["text"].(string)

		if !kindOK ||
			kind == "" ||
			!messageOK ||
			message == "" {
			return nil, fmt.Errorf("Lua command event %d has invalid kind or text", index+1)
		}

		events = append(events, Event{
			Kind: kind,
			Text: message,
		})
	}

	return events, nil
}

func decisionInteger(values map[string]any, field string) (int, error) {
	value, found := values[field].(int64)

	if !found {
		return 0, fmt.Errorf("Lua command field %s is not an integer", field)
	}

	return int(value), nil
}

func optionalDecisionInteger(values map[string]any, field string) (int, bool) {
	value, found := values[field].(int64)

	return int(value), found
}

func decisionEntity(value any) (akara.Entity, error) {
	switch typed := value.(type) {
	case nil:
		return 0, nil

	case akara.Entity:
		return typed, nil

	case int64:
		if typed >= 0 {
			return akara.Entity(typed), nil
		}
	}

	return 0, fmt.Errorf("Lua command item ID has invalid type %T", value)
}

func equipmentDelayFromDecision(values map[string]any) (ecs.EquipmentDelay, error) {
	remaining, err := decisionInteger(values, "remaining")

	if err != nil {
		return ecs.EquipmentDelay{}, err
	}

	item, err := decisionEntity(values["item_id"])

	if err != nil {
		return ecs.EquipmentDelay{}, err
	}

	old, err := decisionEntity(values["old_item_id"])

	if err != nil {
		return ecs.EquipmentDelay{}, err
	}

	slot, _ := values["slot"].(string)
	phase, _ := values["phase"].(string)

	return ecs.EquipmentDelay{
		ItemID:    item,
		OldItemID: old,
		Slot:      slot,
		Phase:     phase,
		Remaining: remaining,
	}, nil
}

func (g *Game) finishScriptEquipment(
	command Command,
	prepared preparedCommand,
	result StepResult,
) (_ StepResult, err error) {
	defer func() {
		if err != nil {
			g.scripts.DiscardPending()
		}
	}()

	input := map[string]any{
		"kind": int(command.Kind),
	}

	if delay := prepared.equipment; delay != nil {
		input["delay"] = map[string]any{
			"item_id":     delay.ItemID,
			"old_item_id": delay.OldItemID,
			"slot":        delay.Slot,
			"phase":       delay.Phase,
			"remaining":   delay.Remaining,
		}
	}

	response, err := g.scripts.Policy("command.equipment_finish", input)

	if err != nil {
		return StepResult{}, err
	}

	messages, ok := response["messages"].([]any)

	if !ok {
		empty, mapOK := response["messages"].(map[string]any)

		if mapOK && len(empty) == 0 {
			messages = nil
		} else {
			return StepResult{}, fmt.Errorf("Lua equipment finish has invalid messages")
		}
	}

	for _, value := range messages {
		_, ok := value.(string)

		if !ok {
			return StepResult{}, fmt.Errorf("Lua equipment message is %T", value)
		}
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return StepResult{}, err
	}

	for _, value := range messages {
		message := value.(string)

		result.Events = append(result.Events, Event{
			Kind: "equipment",
			Text: message,
		})

		g.messages = append(g.messages, message)
	}

	result.View = g.View()

	return result, nil
}
