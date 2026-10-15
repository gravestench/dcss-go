package terminal

import (
	"fmt"

	"charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

func (m *AppModel) applyGameplayDecision(action string, decision map[string]any) tea.Cmd {
	switch action {
	case "aim":
		kind, ok := inputCommandKind(decision,
			game.CommandFire, game.CommandThrow)

		if !ok {
			m.notice = "Input policy returned an invalid aim command."

			return nil
		}

		itemID, err := inputItemID(decision, kind == game.CommandThrow)

		if err != nil {
			m.notice = err.Error()

			return nil
		}

		if kind == game.CommandThrow && itemID == 0 {
			m.notice = "Input policy returned an invalid throw item."

			return nil
		}

		m.startAim(kind, itemID)

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
