package game

import (
	"fmt"

	"crawl/internal/save"
)

// cloneTemplePlan protects the game's future Temple allocation from edits
// to a Snapshot returned to callers.
func cloneTemplePlan(source *save.TemplePlanRecord) *save.TemplePlanRecord {
	if source == nil {
		return nil
	}

	copy := *source
	copy.MainGodIDs = append([]string(nil), source.MainGodIDs...)
	copy.OverflowGodIDs = append([]string(nil), source.OverflowGodIDs...)
	copy.OverflowSchedule = make([]save.OverflowGroupRecord,
		len(source.OverflowSchedule))

	for index, group := range source.OverflowSchedule {
		copy.OverflowSchedule[index] = save.OverflowGroupRecord{
			Depth:  group.Depth,
			GodIDs: append([]string(nil), group.GodIDs...),
		}
	}

	return &copy
}

// decodeTempleGodIDs accepts a Lua array, including the empty table shape
// returned for a rare map with no altars or no overflow gods.
func decodeTempleGodIDs(value any, label string) ([]string, error) {
	values, err := luaScenarioList(value, label)

	if err != nil {
		return nil, err
	}

	ids := make([]string, 0, len(values))

	for index, value := range values {
		id, ok := value.(string)

		if !ok || id == "" {
			return nil, fmt.Errorf("Temple %s has invalid god at %d", label, index)
		}

		ids = append(ids, id)
	}

	return ids, nil
}

// Decode Lua's ordered schedule without making Go responsible for god or
// depth policy. The effective Lua validator checks those meanings next.
func decodeOverflowSchedule(value any) ([]save.OverflowGroupRecord, error) {
	values, err := luaScenarioList(value, "Temple overflow schedule")

	if err != nil {
		return nil, err
	}

	groups := make([]save.OverflowGroupRecord, 0, len(values))

	for index, value := range values {
		raw, ok := value.(map[string]any)

		if !ok {
			return nil, fmt.Errorf("Temple overflow group %d is invalid", index)
		}

		depth, err := decisionInteger(raw, "depth")

		if err != nil {
			return nil, fmt.Errorf("Temple overflow group %d: %w", index, err)
		}

		gods, err := decodeTempleGodIDs(raw["god_ids"], "overflow group")

		if err != nil {
			return nil, err
		}

		groups = append(groups, save.OverflowGroupRecord{
			Depth:  depth,
			GodIDs: gods,
		})
	}

	return groups, nil
}

// Keep the Lua-to-Go boundary concerned with field shapes. The effective
// Lua map and god catalogs own the semantic validation below.
func decodeLuaTemplePlan(value any) (*save.TemplePlanRecord, error) {
	raw, ok := value.(map[string]any)

	if !ok {
		return nil, fmt.Errorf("Lua generation returned no Temple plan")
	}

	mapID, ok := raw["map_id"].(string)

	if !ok || mapID == "" {
		return nil, fmt.Errorf("Lua Temple plan has no map ID")
	}

	count, err := decisionInteger(raw, "altar_count")

	if err != nil {
		return nil, fmt.Errorf("Lua Temple plan: %w", err)
	}

	main, err := decodeTempleGodIDs(raw["main_god_ids"], "main gods")

	if err != nil {
		return nil, err
	}

	overflow, err := decodeTempleGodIDs(raw["overflow_god_ids"], "overflow gods")

	if err != nil {
		return nil, err
	}

	schedule, err := decodeOverflowSchedule(raw["overflow_schedule"])

	if err != nil {
		return nil, err
	}

	return &save.TemplePlanRecord{
		MapID:            mapID,
		AltarCount:       count,
		MainGodIDs:       main,
		OverflowGodIDs:   overflow,
		OverflowSchedule: schedule,
	}, nil
}

// Reconstruct the same table shape the Lua validator and future Temple
// generation use. Empty Go slices remain ordered empty Lua arrays.
func luaTemplePlan(source *save.TemplePlanRecord) map[string]any {
	schedule := make([]any, 0, len(source.OverflowSchedule))

	for _, group := range source.OverflowSchedule {
		schedule = append(schedule, map[string]any{
			"depth":   group.Depth,
			"god_ids": append([]string{}, group.GodIDs...),
		})
	}

	return map[string]any{
		"map_id":            source.MapID,
		"altar_count":       source.AltarCount,
		"main_god_ids":      append([]string{}, source.MainGodIDs...),
		"overflow_god_ids":  append([]string{}, source.OverflowGodIDs...),
		"overflow_schedule": schedule,
	}
}

// A restored plan is accepted only after the effective Lua rules prove
// that its map, count, and complete god partition remain valid.
func (g *Game) acceptTemplePlan(source *save.TemplePlanRecord) error {
	if source == nil {
		return fmt.Errorf("generated save has no Temple plan")
	}

	_, err := g.scripts.Policy("world.validate_temple_plan", map[string]any{
		"temple_plan": luaTemplePlan(source),
	})

	if err != nil {
		return fmt.Errorf("invalid Temple plan: %w", err)
	}

	g.templePlan = cloneTemplePlan(source)

	return nil
}

// New-game Lua output enters the same validator as saved JSON, so the two
// paths cannot disagree about the Temple's planned altar identities.
func (g *Game) acceptLuaTemplePlan(value any) error {
	chosen, err := decodeLuaTemplePlan(value)

	if err != nil {
		return err
	}

	return g.acceptTemplePlan(chosen)
}
