package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

func (m *AppModel) applySessionDecision(action string, decision map[string]any) tea.Cmd {
	switch action {
	case "confirm":
		name, ok := decision["confirmation"].(string)

		if !ok || (name != "save" && name != "abandon") {
			m.notice = "Input policy returned an invalid confirmation."

			return nil
		}

		interrupt, err := inputInterruptTick(decision)

		if err != nil {
			m.notice = err.Error()

			return nil
		}

		if interrupt {
			m.equipmentTickID++
			m.spellTickID++
		}

		if name == "save" {
			m.openConfirmation(confirmSave)
		} else {
			m.openConfirmation(confirmAbandon)
		}

	case "save_exit":
		interrupt, err := inputInterruptTick(decision)

		if err != nil {
			m.notice = err.Error()

			return nil
		}

		if interrupt {
			m.equipmentTickID++
			m.spellTickID++
		}

		return m.saveAndExit()

	case "cancel_equipment":
		if _, ok := inputCommandKind(decision, game.CommandCancelEquipment); !ok {
			m.notice = "Input policy returned an invalid equipment command."

			return nil
		}

		m.equipmentTickID++

		return m.stepPlayCommand(game.Command{
			Kind: game.CommandCancelEquipment,
		})

	case "cancel_memorise":
		if _, ok := inputCommandKind(decision,
			game.CommandCancelMemorise); !ok {
			m.notice = "Input policy returned an invalid spell command."

			return nil
		}

		m.spellTickID++

		return m.stepPlayCommand(game.Command{
			Kind: game.CommandCancelMemorise,
		})

	case "choose_stat":
		id, ok := decision["id"].(string)

		if !ok ||
			(id != "str" &&
				id != "int" &&
				id != "dex") {
			m.notice = "Input policy returned an invalid stat."

			return nil
		}

		result, err := m.game.ChooseStat(id)

		if err != nil {
			m.notice = fmt.Sprintf("Stat choice failed: %v", err)

			return nil
		}

		m.notice = ""
		m.screen = ScreenPlay
		m.afterStep(result)

	case "confirm_cancel":
		m.confirm = confirmNone
		m.openScreen(ScreenPlay)

		if m.game != nil && m.game.View().EquipmentDelay != nil {
			return m.nextEquipmentTick()
		}

		if m.game != nil && m.game.View().LearningRemaining > 0 {
			return m.nextSpellTick()
		}

	case "confirm_accept":
		action := m.confirm

		m.confirm = confirmNone

		if action == confirmSave {
			return m.saveAndExit()
		}

		if action == confirmAbandon {
			m.screen = ScreenDeath
		}

	}

	return nil
}

func inputInterruptTick(decision map[string]any) (bool, error) {
	value, found := decision["interrupt_tick"]

	if !found {
		return false, nil
	}

	interrupt, ok := value.(bool)

	if !ok {
		return false, fmt.Errorf("input policy returned invalid equipment timing")
	}

	return interrupt, nil
}
