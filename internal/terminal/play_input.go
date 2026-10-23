package terminal

import (
	"fmt"

	tea "charm.land/bubbletea/v2"
	"crawl/internal/game"
)

func (m *AppModel) handlePlayKey(key string) tea.Cmd {
	if m.game == nil {
		m.notice = "No game is running."

		return nil
	}

	if m.game.View().EquipmentDelay != nil {
		return m.routeInput("equipment_delay", key)
	}

	if m.game.View().LearningRemaining > 0 {
		return m.routeInput("memorisation_delay", key)
	}

	if m.game.View().VampireRitualRemaining > 0 {
		return m.routeInput("vampire_delay", key)
	}

	if m.pendingDoor != 0 {
		return m.routeInput("door", key)
	}

	if key == ">" || key == "<" {
		view := m.game.View()
		onAltar := altarAtPlayer(view)
		onShop := false

		if key == ">" && !onAltar {
			shop, err := m.game.ShopAtPlayer("type")

			if err != nil {
				m.notice = fmt.Sprintf("Shop failed: %v", err)

				return nil
			}

			onShop = shop.Available
		}

		return m.routeInput("play", key, map[string]any{
			"on_altar": onAltar,
			"on_shop":  onShop,
		})
	}

	return m.routeInput("play", key)
}

// The view already presents saved source altar records at exact map cells.
// Input only needs their location; Lua prayer reads the authoritative record.
func altarAtPlayer(view game.View) bool {
	for _, entity := range view.Entities {
		if entity.Role == "altar" &&
			entity.X == view.PlayerX &&
			entity.Y == view.PlayerY {
			return true
		}
	}

	return false
}

var inputScreens = map[string]ScreenID{
	"startup":          ScreenStartup,
	"species":          ScreenSpecies,
	"background":       ScreenBackground,
	"weapon":           ScreenWeapon,
	"name":             ScreenName,
	"play":             ScreenPlay,
	"shop":             ScreenShop,
	"inventory":        ScreenInventory,
	"skills":           ScreenSkills,
	"mutations":        ScreenMutations,
	"help":             ScreenHelp,
	"quaff":            ScreenQuaff,
	"read":             ScreenRead,
	"selection":        ScreenSelection,
	"evoke_wand":       ScreenEvokeWand,
	"drop":             ScreenDrop,
	"wield":            ScreenWield,
	"throw":            ScreenThrow,
	"wear":             ScreenWear,
	"take_off":         ScreenTakeOff,
	"put_on":           ScreenPutOn,
	"remove_jewellery": ScreenRemoveJewellery,
	"spell_cast":       ScreenSpells,
	"spell_force":      ScreenSpells,
	"spell_memorise":   ScreenSpells,
	"abilities":        ScreenAbilities,
	"ability_confirm":  ScreenAbilityConfirm,
	"action_confirm":   ScreenActionConfirm,
}

var gameInputActions = map[string]bool{
	"aim":                    true,
	"cancel_equipment":       true,
	"cancel_memorise":        true,
	"cancel_vampire":         true,
	"change_skill":           true,
	"choose_stat":            true,
	"confirm":                true,
	"confirm_accept":         true,
	"confirm_cancel":         true,
	"cycle_aim":              true,
	"door":                   true,
	"drop_quantity":          true,
	"finish_door":            true,
	"fire_aim":               true,
	"item_step":              true,
	"selection_choose":       true,
	"selection_cancel":       true,
	"cancel_read_aim":        true,
	"move_aim":               true,
	"mutation_page":          true,
	"mutation_detail":        true,
	"mutation_close_detail":  true,
	"save_exit":              true,
	"step":                   true,
	"spell_step":             true,
	"ability_step":           true,
	"confirm_ability":        true,
	"ability_confirm_accept": true,
	"action_confirm_accept":  true,
	"action_confirm_cancel":  true,
	"toggle_skill_focus":     true,
	"toggle_skill_mode":      true,
	"spend_experience_skill": true,
}

func (m *AppModel) routeInput(screen, key string, extra ...map[string]any) tea.Cmd {
	input := map[string]any{
		"screen": screen,
		"key":    key,
	}

	for _, fields := range extra {
		for name, value := range fields {
			input[name] = value
		}
	}

	decision, err := m.presentationRuntime.PolicyReadOnly("terminal.input", input)

	if err != nil {
		m.notice = fmt.Sprintf("Input policy failed: %v", err)

		return nil
	}

	return m.applyInputDecision(decision)
}

func (m *AppModel) routeInventoryInput(screen, key string) tea.Cmd {
	if m.game == nil {
		m.notice = "Input policy requested inventory before game start."

		return nil
	}

	return m.routeInput(screen, key, map[string]any{
		"inventory":     inventoryInput(m.game.View().Inventory),
		"drop_quantity": m.dropQuantity,
	})
}

func (m *AppModel) applyInputDecision(decision map[string]any) tea.Cmd {
	action, ok := decision["action"].(string)

	if !ok {
		m.notice = "Input policy returned no action."

		return nil
	}

	if m.game == nil && gameInputActions[action] {
		m.notice = "Input policy requested a game action before game start."

		return nil
	}

	switch action {
	case "none", "return_screen", "return_to_startup", "notice", "screen":
		return m.applyNavigationDecision(action, decision)

	case "confirm", "save_exit", "cancel_equipment", "choose_stat",
		"cancel_memorise", "cancel_vampire", "confirm_cancel", "confirm_accept":
		return m.applySessionDecision(action, decision)

	case "aim", "door", "step", "spell_step", "ability_step",
		"confirm_ability", "ability_confirm_accept",
		"action_confirm_accept", "action_confirm_cancel",
		"cancel_read_aim":
		return m.applyGameplayDecision(action, decision)

	case "drop_quantity", "item_step":
		return m.applyItemDecision(action, decision)

	case "selection_choose", "selection_cancel":
		return m.applySelectionDecision(action, decision)

	case "fire_aim", "cycle_aim", "move_aim", "cancel_door",
		"finish_door":
		return m.applySpatialDecision(action, decision)

	case "focus", "quit", "load_saved", "start_new", "name_edit",
		"select_choice", "select_weapon", "return_weapon", "start_game":
		return m.applyPregameDecision(action, decision)

	case "toggle_skill_mode", "toggle_skill_focus", "change_skill",
		"spend_experience_skill":
		return m.applySkillDecision(action, decision)

	case "mutation_page", "mutation_detail", "mutation_close_detail":
		return m.applyMutationDecision(action, decision)

	default:
		m.notice = fmt.Sprintf("Input policy returned unsupported action %q.", action)
	}

	return nil
}

func (m *AppModel) openScreen(screen ScreenID) {
	m.screen = screen
	m.notice = ""
}

func (m *AppModel) openReturnableScreen(screen ScreenID) {
	m.previous = m.screen
	m.openScreen(screen)
}

func (m *AppModel) openConfirmation(action confirmation) {
	m.confirm = action
	m.openScreen(ScreenConfirm)
}

func (m *AppModel) stepPlayCommand(command game.Command) tea.Cmd {
	result, err := m.game.Step(command)

	if err != nil {
		m.notice = fmt.Sprintf("Action failed: %v", err)

		return nil
	}

	m.notice = ""

	if result.Selection != nil {
		// A choice is a new input step. The answer to the previous prompt
		// must not become the answer to this one after a replay.
		command.TargetID = ""
		command.Cancelled = false
		command.Forced = false
		m.pendingAction = command
		m.pendingSelection = result.Selection

		if result.Selection.Kind == "cell" {
			m.startAim(command.Kind, command.ItemID)
		} else {
			m.openScreen(ScreenSelection)
		}

		return nil
	}

	if result.Confirmation != "" {
		command.TargetID = result.ConfirmationTarget
		command.Cancelled = false
		command.Forced = false
		m.pendingAction = command
		m.pendingActionPrompt = result.Confirmation
		m.openScreen(ScreenActionConfirm)

		return nil
	}

	if result.Spent == 0 && len(result.Events) > 0 {
		m.notice = result.Events[0].Text

		return nil
	}

	m.afterStep(result)

	if result.Spent > 0 &&
		m.screen == ScreenPlay &&
		command.Kind == game.CommandMove {
		shop, err := m.game.ShopAtPlayer("type")

		if err != nil {
			m.notice = fmt.Sprintf("Shop failed: %v", err)
		} else if shop.Available {
			m.openShop()
		}
	}

	if result.View.EquipmentDelay != nil && m.screen == ScreenPlay {
		return m.nextEquipmentTick()
	}

	if result.View.LearningRemaining > 0 && m.screen == ScreenPlay {
		return m.nextSpellTick()
	}

	if result.View.VampireRitualRemaining > 0 && m.screen == ScreenPlay {
		return m.nextVampireTick()
	}

	return nil
}

func (m *AppModel) afterStep(result game.StepResult) {
	if result.View.PlayerDead {
		m.screen = ScreenDeath
	} else if result.View.Outcome == "won" {
		m.screen = ScreenVictory
	} else if result.View.Outcome == "left" {
		m.screen = ScreenLeft
	} else if result.View.PendingStatLevel != 0 {
		m.screen = ScreenStatChoice
	} else if result.View.PendingSkillExperience > 0 {
		m.screen = ScreenSkills
	}
}
