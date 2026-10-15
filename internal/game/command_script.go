package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// prepareScriptCommand decodes the one generic Lua command decision. The
// command language and its validation live in the effective mod ruleset.
func (g *Game) prepareScriptCommand(command Command) (_ preparedCommand, err error) {
	defer func() {
		if err != nil {
			g.scripts.DiscardPending()
		}
	}()

	decision, err := g.scripts.Policy("command.prepare", map[string]any{
		"kind":     int(command.Kind),
		"dx":       command.DX,
		"dy":       command.DY,
		"item_id":  command.ItemID,
		"quantity": command.Quantity,
		"spell_id": command.SpellID,
	})

	if err != nil {
		return preparedCommand{}, err
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

		return freeCommand(g.noTimeEvent(event)), nil
	}

	if _, found := decision["intent"]; !found {
		return freeCommand(StepResult{View: g.View()}), nil
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
	intent.Forced, _ = values["forced"].(bool)

	cost, err := decisionInteger(decision, "cost")

	if err != nil {
		return preparedCommand{}, err
	}

	prepared := spendingCommand(intent, Aut(cost))

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

	return prepared, nil
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
