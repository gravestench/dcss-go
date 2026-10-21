package terminal

import (
	"fmt"

	"charm.land/bubbletea/v2"
	"crawl/internal/game"
)

func (m *AppModel) applyGameplayDecision(action string, decision map[string]any) tea.Cmd {
	switch action {
	case "aim":
		kind, ok := inputCommandKind(decision,
			game.CommandFire, game.CommandThrow,
			game.CommandCast, game.CommandForceCast,
			game.CommandAbility, game.CommandEvokeWand)

		if !ok {
			m.notice = "Input policy returned an invalid aim command."

			return nil
		}

		itemID, err := inputItemID(decision,
			kind == game.CommandThrow || kind == game.CommandEvokeWand)

		if err != nil {
			m.notice = err.Error()

			return nil
		}

		if kind == game.CommandThrow && itemID == 0 {
			m.notice = "Input policy returned an invalid throw item."

			return nil
		}

		if kind == game.CommandEvokeWand && itemID == 0 {
			m.notice = "Input policy returned an invalid wand."

			return nil
		}

		spellID := ""
		abilityID := ""

		if kind == game.CommandCast || kind == game.CommandForceCast {
			selected, valid := decision["spell_id"].(string)

			if !valid || selected == "" {
				m.notice = "Input policy returned an invalid spell."

				return nil
			}

			spellID = selected
		}

		if kind == game.CommandAbility {
			selected, valid := decision["ability_id"].(string)

			if !valid || selected == "" {
				m.notice = "Input policy returned an invalid ability."

				return nil
			}

			abilityID = selected
		}

		m.startAim(kind, itemID)
		m.aimSpellID = spellID
		m.aimAbilityID = abilityID

	case "door":
		kind, ok := inputCommandKind(decision, game.CommandOpenDoor,
			game.CommandCloseDoor)

		if !ok {
			m.notice = "Input policy returned an invalid door command."

			return nil
		}

		return m.startDoorCommand(kind)

	case "step":
		command, err := playCommandFromDecision(decision)

		if err != nil {
			m.notice = fmt.Sprintf("Input policy returned an invalid command: %v", err)

			return nil
		}

		return m.stepPlayCommand(command)

	case "spell_step":
		return m.applySpellStep(decision)

	case "ability_step":
		return m.applyAbilityStep(decision)

	case "confirm_ability":
		return m.beginAbilityConfirmation(decision)

	case "ability_confirm_accept":
		return m.acceptAbilityConfirmation()

	case "action_confirm_accept":
		return m.acceptActionConfirmation()

	case "action_confirm_cancel":
		m.pendingAction = game.Command{}
		m.pendingActionPrompt = ""
		m.openScreen(ScreenPlay)

	case "cancel_read_aim":
		if m.screen != ScreenAim ||
			m.pendingSelection == nil ||
			m.pendingSelection.Kind != "cell" {
			m.notice = "No scroll target is pending."

			return nil
		}

		command := m.pendingAction

		command.Cancelled = true
		m.pendingAction = game.Command{}
		m.pendingSelection = nil
		m.openScreen(ScreenPlay)

		return m.stepPlayCommand(command)

	}

	return nil
}

func inputCommandKind(decision map[string]any, allowed ...game.CommandKind) (game.CommandKind, bool) {
	raw, ok := decision["kind"].(int64)

	if !ok {
		return 0, false
	}

	for _, kind := range allowed {
		if raw == int64(kind) {
			return kind, true
		}
	}

	return 0, false
}

func playCommandFromDecision(decision map[string]any) (game.Command, error) {
	kind, ok := inputCommandKind(decision,
		game.CommandMove,
		game.CommandWait,
		game.CommandPickup,
		game.CommandUpstairs,
		game.CommandDownstairs,
		game.CommandPray,
	)

	if !ok {
		return game.Command{}, fmt.Errorf("unsupported command kind %v", decision["kind"])
	}

	command := game.Command{
		Kind: kind,
	}

	if kind == game.CommandMove {
		dx, dy, err := inputDirection(decision)

		if err != nil {
			return game.Command{}, err
		}

		command.DX = dx
		command.DY = dy

		return command, nil
	}

	if _, found := decision["dx"]; found {
		return game.Command{}, fmt.Errorf("non-movement command has a direction")
	}

	if _, found := decision["dy"]; found {
		return game.Command{}, fmt.Errorf("non-movement command has a direction")
	}

	return command, nil
}
