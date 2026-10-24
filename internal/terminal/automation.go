package terminal

import (
	"fmt"
	"time"

	tea "charm.land/bubbletea/v2"
	"crawl/internal/game"
)

// These wire IDs match constants/automation.lua in the bundled mod. Lua
// owns the rule; Go names the small protocol at its terminal boundary.
const (
	automationPolicy     = "terminal.automation"
	automationRun        = "run"
	automationRest       = "rest"
	automationExplore    = "explore"
	automationStartPhase = "start"
	automationNextPhase  = "next"
	automationStopAction = "stop"
)

// The terminal supplies only remembered or visible cells. Lua owns the
// route and stopping rules; Go neither looks ahead into unseen terrain nor
// duplicates a second movement or combat implementation.
func automationView(view game.View) map[string]any {
	cells := make([]any, len(view.Cells))

	for index, cell := range view.Cells {
		cells[index] = map[string]any{
			"feature":  cell.FeatureID,
			"state":    int64(cell.State),
			"walkable": cell.Walkable,
		}
	}

	entities := make([]any, 0, len(view.Entities))

	for _, entity := range view.Entities {
		entities = append(entities, map[string]any{
			"x":       entity.X,
			"y":       entity.Y,
			"role":    entity.Role,
			"hostile": entity.Hostile,
		})
	}

	clouds := make([]any, 0, len(view.Clouds))

	for _, cloud := range view.Clouds {
		clouds = append(clouds, map[string]any{
			"x": cloud.X,
			"y": cloud.Y,
		})
	}

	return map[string]any{
		"width":                view.Width,
		"height":               view.Height,
		"player_x":             view.PlayerX,
		"player_y":             view.PlayerY,
		"hp":                   view.PlayerHP,
		"max_hp":               view.PlayerMaxHP,
		"mp":                   view.PlayerMP,
		"max_mp":               view.PlayerMaxMP,
		"can_recover_hp":       view.CanRecoverHP,
		"can_recover_mp":       view.CanRecoverMP,
		"can_cross_lava":       view.CanCrossLava,
		"can_cross_deep_water": view.CanCrossDeepWater,
		"cells":                cells,
		"entities":             entities,
		"clouds":               clouds,
	}
}

// Start is a zero-turn UI decision. Each later tick submits one ordinary
// command through Game.Step, so existing timing, AI, saves, and messages
// continue to use the same path as a manually typed key.
func (m *AppModel) beginAutomation(decision map[string]any) tea.Cmd {
	mode, valid := decision["mode"].(string)

	if !valid || (mode != automationRun &&
		mode != automationRest && mode != automationExplore) {
		m.notice = "Input policy returned an invalid automatic mode."

		return nil
	}

	input := map[string]any{
		"phase": automationStartPhase,
		"mode":  mode,
		"view":  automationView(m.game.View()),
	}

	if mode == automationRun {
		dx, xOK := decision["dx"].(int64)
		dy, yOK := decision["dy"].(int64)

		if !xOK || !yOK || dx < -1 || dx > 1 ||
			dy < -1 || dy > 1 || dx == 0 && dy == 0 {
			m.notice = "Input policy returned an invalid run direction."

			return nil
		}

		input["dx"] = dx
		input["dy"] = dy
	}

	state, err := m.presentationRuntime.PolicyReadOnly(
		automationPolicy, input)

	if err != nil {
		m.notice = fmt.Sprintf("Automatic movement failed: %v", err)

		return nil
	}

	m.automationState = state
	m.notice = ""

	return m.nextAutomationTick()
}

// Incrementing the generation invalidates ticks left in Tea's queue when
// a key, modal, death, or blocked movement stops the current command.
func (m *AppModel) stopAutomation() {
	m.automationState = nil
	m.automationTickID++
}

// One timer fires for one decision. Scheduling a new timer only after a
// successful step prevents delayed ticks from accumulating extra turns.
func (m *AppModel) nextAutomationTick() tea.Cmd {
	m.automationTickID++
	id := m.automationTickID

	return tea.Tick(80*time.Millisecond, func(time.Time) tea.Msg {
		return automationTick{id: id}
	})
}

// Lua determines whether running, resting, or exploring continues. A
// refused command or prompt stops automation before it can loop forever.
func (m *AppModel) advanceAutomation() tea.Cmd {
	before := m.game.View()
	decision, err := m.presentationRuntime.PolicyReadOnly(
		automationPolicy,
		map[string]any{
			"phase": automationNextPhase,
			"state": m.automationState,
			"view":  automationView(before),
		},
	)

	if err != nil {
		m.stopAutomation()
		m.notice = fmt.Sprintf("Automatic movement failed: %v", err)

		return nil
	}

	if decision["action"] == automationStopAction {
		m.stopAutomation()

		return nil
	}

	if updated, found := decision["state"]; found {
		state, valid := updated.(map[string]any)

		if !valid {
			m.stopAutomation()
			m.notice = "Automatic movement returned invalid route state."

			return nil
		}

		m.automationState = state
	}

	command, err := playCommandFromDecision(decision)

	if err != nil || (command.Kind != game.CommandMove &&
		command.Kind != game.CommandWait) {
		m.stopAutomation()
		m.notice = "Automatic movement returned an invalid command."

		return nil
	}

	other := m.stepPlayCommand(command)
	after := m.game.View()

	if m.screen != ScreenPlay || after.CurrentAut == before.CurrentAut ||
		after.LevelID != before.LevelID || after.PlayerHP < before.PlayerHP ||
		after.EquipmentDelay != nil || after.LearningRemaining > 0 ||
		after.VampireRitualRemaining > 0 ||
		(command.Kind == game.CommandMove &&
			after.PlayerX == before.PlayerX &&
			after.PlayerY == before.PlayerY) {
		m.stopAutomation()

		return other
	}

	if remaining, valid := m.automationState["remaining"].(int64); valid &&
		remaining > 0 {
		m.automationState["remaining"] = remaining - 1
	}

	return tea.Batch(other, m.nextAutomationTick())
}
