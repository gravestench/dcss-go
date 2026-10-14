package terminal

import "dcrawl-go/internal/game"

func fullRegion(canvas *Canvas) Region {
	return Region{
		W: canvas.width,
		H: canvas.height,
	}
}

func drawInventoryModal(
	canvas *Canvas,
	view game.View,
	mode string,
	quantity string,
	policy presentationPolicy,
) {
	result := runPresentation(policy, "presentation.inventory_modal", map[string]any{
		"mode":      mode,
		"inventory": inventoryInput(view.Inventory),
		"quantity":  quantity,
		"height":    canvas.height,
	})

	drawPresentation(canvas, fullRegion(canvas), result)
}

func DrawInventory(canvas *Canvas, view game.View, policy presentationPolicy) {
	drawInventoryModal(canvas, view, "inventory", "", policy)
}

func DrawDrop(canvas *Canvas, view game.View, quantity string, policy presentationPolicy) {
	drawInventoryModal(canvas, view, "drop", quantity, policy)
}

func DrawWield(canvas *Canvas, view game.View, policy presentationPolicy) {
	drawInventoryModal(canvas, view, "wield", "", policy)
}

func DrawArmour(canvas *Canvas, view game.View, remove bool, policy presentationPolicy) {
	mode := "wear"

	if remove {
		mode = "take_off"
	}

	drawInventoryModal(canvas, view, mode, "", policy)
}

func DrawQuaff(canvas *Canvas, view game.View, policy presentationPolicy) {
	drawInventoryModal(canvas, view, "quaff", "", policy)
}

func DrawSkills(canvas *Canvas, view game.View, focusAction bool, policy presentationPolicy) {
	percent := make(map[string]any, len(view.SkillPercent))

	for id, value := range view.SkillPercent {
		percent[id] = value
	}

	result := runPresentation(policy, "presentation.skills", map[string]any{
		"species_id":     view.SpeciesID,
		"skills":         skillInput(view),
		"skill_training": trainingInput(view),
		"skill_percent":  percent,
		"focus_action":   focusAction,
		"height":         canvas.height,
	})

	drawPresentation(canvas, fullRegion(canvas), result)
}

func DrawHelp(canvas *Canvas, policy presentationPolicy) {
	result := runPresentation(policy, "presentation.help", map[string]any{})
	drawPresentation(canvas, fullRegion(canvas), result)
}

func (m *AppModel) drawConfirm(canvas *Canvas) {
	result := runPresentation(m.presentationPolicy, "presentation.confirm", map[string]any{
		"abandon": m.confirm == confirmAbandon,
	})

	drawPresentation(canvas, fullRegion(canvas), result)
}

func (m *AppModel) handleModalKey(key string) {
	switch key {
	case "esc":
		m.screen = ScreenPlay
		m.notice = ""

	case "?":
		m.previous = m.screen
		m.screen = ScreenHelp
		m.notice = ""

	default:
		m.notice = "This menu control is unavailable in the Go port."
	}
}

func (m *AppModel) drawModalNotice(canvas *Canvas) {
	if m.notice != "" {
		m.drawStatus(canvas, "modal_notice")
	}
}
