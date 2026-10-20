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

	return &save.TemplePlanRecord{
		MapID:          mapID,
		AltarCount:     count,
		MainGodIDs:     main,
		OverflowGodIDs: overflow,
	}, nil
}

// Reconstruct the same table shape the Lua validator and future Temple
// generation use. Empty Go slices remain ordered empty Lua arrays.
func luaTemplePlan(source *save.TemplePlanRecord) map[string]any {
	return map[string]any{
		"map_id":           source.MapID,
		"altar_count":      source.AltarCount,
		"main_god_ids":     append([]string{}, source.MainGodIDs...),
		"overflow_god_ids": append([]string{}, source.OverflowGodIDs...),
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
