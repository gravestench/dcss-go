package terminal

import (
	"fmt"

	"dcrawl-go/internal/game"
	"github.com/mattn/go-runewidth"
)

type presentationPolicy func(string, map[string]any) (map[string]any, error)

func runPresentation(policy presentationPolicy, name string, input map[string]any) map[string]any {
	result, err := policy(name, input)

	if err != nil {
		panic(fmt.Errorf("presentation %s: %w", name, err))
	}

	return result
}

func policyNumber(value any) int {
	switch number := value.(type) {
	case int64:
		return int(number)

	case int:
		return number

	default:
		panic(fmt.Sprintf("presentation number has type %T", value))
	}
}

func policyRows(value any) []any {
	if value == nil {
		return nil
	}

	if empty, ok := value.(map[string]any); ok && len(empty) == 0 {
		return nil
	}

	rows, ok := value.([]any)

	if !ok {
		panic(fmt.Sprintf("presentation rows have type %T", value))
	}

	return rows
}

func policyRecord(value any) map[string]any {
	record, ok := value.(map[string]any)

	if !ok {
		panic(fmt.Sprintf("presentation record has type %T", value))
	}

	return record
}

func policyColor(value any) Color {
	return Color(policyNumber(value))
}

func clippedWrite(canvas *Canvas, x, y, width int, value string, fg, bg Color) {
	used := 0

	for _, glyph := range value {
		cells := runewidth.RuneWidth(glyph)

		if cells < 1 || used+cells > width {
			break
		}

		canvas.Put(x+used, y, glyph, fg, bg)
		used += cells
	}
}

// drawPresentation interprets screen instructions. Coordinates are relative
// to region; Canvas remains responsible for terminal cells and wide glyphs.
func drawPresentation(canvas *Canvas, region Region, result map[string]any) {
	for _, raw := range policyRows(result["writes"]) {
		write := policyRecord(raw)
		x := policyNumber(write["x"])
		y := policyNumber(write["y"])

		if y < 0 ||
			y >= region.H ||
			x >= region.W {
			continue
		}

		fg := policyColor(write["fg"])
		bg := Black

		if value, found := write["bg"]; found {
			bg = policyColor(value)
		}

		clippedWrite(canvas, region.X+x, region.Y+y, region.W-x, write["text"].(string), fg, bg)
	}

	for _, raw := range policyRows(result["meters"]) {
		meter := policyRecord(raw)
		maximum := policyNumber(meter["maximum"])

		if maximum <= 0 {
			continue
		}

		current := policyNumber(meter["current"])
		width := policyNumber(meter["width"])
		filled := policyColor(meter["filled"])
		empty := policyColor(meter["empty"])
		current = max(0, min(current, maximum))
		count := width * current / maximum
		x := region.X + policyNumber(meter["x"])
		y := region.Y + policyNumber(meter["y"])

		for index := range width {
			if index < count {
				canvas.Put(x+index, y, '=', filled, Black)
			} else {
				canvas.Put(x+index, y, '-', empty, Black)
			}
		}
	}

	for _, raw := range policyRows(result["wraps"]) {
		wrap := policyRecord(raw)
		writeWrapped(canvas,
			region.X+policyNumber(wrap["x"]),
			region.Y+policyNumber(wrap["y"]),
			policyNumber(wrap["width"]),
			policyNumber(wrap["height"]),
			wrap["text"].(string),
			policyColor(wrap["fg"]),
		)
	}
}

func inventoryInput(items []game.ItemView) []any {
	result := make([]any, 0, len(items))

	for _, item := range items {
		result = append(result, map[string]any{
			"id":       item.ID,
			"name":     item.Name,
			"class":    item.Class,
			"quantity": item.Quantity,
			"slot":     item.Slot,
		})
	}

	return result
}

func entityInput(entities []game.EntityView) []any {
	result := make([]any, 0, len(entities))

	for _, entity := range entities {
		result = append(result, map[string]any{
			"role": entity.Role,
			"name": entity.Name,
		})
	}

	return result
}

func skillInput(view game.View) []any {
	result := make([]any, 0, len(view.Skills))

	for _, skill := range view.Skills {
		result = append(result, map[string]any{
			"id":     skill.ID,
			"level":  skill.Level,
			"points": skill.Points,
		})
	}

	return result
}

func trainingInput(view game.View) map[string]any {
	settings := make([]any, 0, len(view.SkillTraining.Settings))

	for _, setting := range view.SkillTraining.Settings {
		settings = append(settings, map[string]any{
			"id":      setting.ID,
			"enabled": setting.Enabled,
			"focused": setting.Focused,
		})
	}

	return map[string]any{
		"manual":   view.SkillTraining.Manual,
		"settings": settings,
	}
}

func hudInput(view game.View) map[string]any {
	return map[string]any{
		"player_name":   view.PlayerName,
		"species_name":  view.SpeciesName,
		"player_hp":     view.PlayerHP,
		"player_max_hp": view.PlayerMaxHP,
		"player_mp":     view.PlayerMP,
		"player_max_mp": view.PlayerMaxMP,
		"player_ac":     view.PlayerAC,
		"player_ev":     view.PlayerEV,
		"player_sh":     view.PlayerSH,
		"gold":          view.Gold,
		"defense_known": view.DefenseKnown,
		"attributes": map[string]any{
			"strength":     view.Attributes.Strength,
			"intelligence": view.Attributes.Intelligence,
			"dexterity":    view.Attributes.Dexterity,
		},
		"experience_level":     view.ExperienceLevel,
		"next_level_percent":   view.NextLevelPercent,
		"level_id":             view.LevelID,
		"current_aut":          int(view.CurrentAut),
		"inventory":            inventoryInput(view.Inventory),
		"might_aut":            view.MightAut,
		"poison_amount_scaled": view.PoisonAmountScaled,
		"haste_aut":            view.HasteAut,
		"constricted":          view.Constricted,
	}
}
