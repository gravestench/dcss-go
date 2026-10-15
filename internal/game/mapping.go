package game

import (
	"fmt"
)

const sourceMapWidth = 80

// mapDifficulty ports hash_with_seed from the pinned source's hash.cc.
// Passive mapping uses a stable per-cell roll so exploration order and
// save/restore never change which terrain the player can discover.
func mapDifficulty(seed uint32, x, y int) int64 {
	const multiplier uint32 = 0x5bd1e995

	hash := uint32(8)
	terms := [2]uint32{
		seed,
		uint32(y*sourceMapWidth + x),
	}

	for _, term := range terms {
		term *= multiplier
		term ^= term >> 24
		term *= multiplier
		hash *= multiplier
		hash ^= term
	}

	hash ^= hash >> 13
	hash *= multiplier
	hash ^= hash >> 15

	return int64(hash % 100)
}

func (g *Game) mapDifficulties(level *Level) []any {
	seed := uint32(g.seed&0x7fffffff) ^ uint32(level.ID)
	difficulties := make([]any, 0, level.width*len(level.terrain))

	for y, row := range level.terrain {
		for x := range row {
			difficulties = append(difficulties, mapDifficulty(seed, x, y))
		}
	}

	return difficulties
}

func (g *Game) mappingLevel() (int, error) {
	result, err := g.scripts.Policy("world.mapping_level", nil)

	if err != nil {
		return 0, err
	}

	level, ok := result["level"].(int64)

	if !ok ||
		level < 0 ||
		level > 100 {
		return 0, fmt.Errorf("Lua passive mapping level is invalid")
	}

	return int(level), nil
}

func (g *Game) applyExploration(level *Level, newlySeen []point) error {
	mappingLevel, err := g.mappingLevel()

	if err != nil {
		return err
	}

	origins := newlySeen

	if mappingLevel > level.mappingLevel {
		origins = make([]point, 0)

		for y := range level.terrain {
			for x := 0; x < level.width; x++ {
				if level.seen[y*level.width+x] {
					origins = append(origins, point{
						x: x,
						y: y,
					})
				}
			}
		}
	}

	if len(newlySeen) == 0 &&
		(mappingLevel == 0 || len(origins) == 0) {
		level.mappingLevel = mappingLevel

		return nil
	}

	listed := make([]any, 0, len(origins))

	for _, origin := range origins {
		listed = append(listed, map[string]any{
			"x": origin.x,
			"y": origin.y,
		})
	}

	input := map[string]any{
		"count":      len(newlySeen),
		"width":      level.width,
		"height":     len(level.terrain),
		"origins":    listed,
		"difficulty": []any{},
	}

	if mappingLevel > 0 && len(origins) > 0 {
		input["difficulty"] = g.mapDifficulties(level)
	}

	output, err := g.scripts.Policy("world.on_seen", input)

	if err != nil {
		return err
	}

	mapped, err := gridPoints(output["mapped"], "passive mapping")

	if err != nil {
		g.scripts.DiscardPending()

		return err
	}

	for _, cell := range mapped {
		if !level.inBounds(cell.x, cell.y) {
			g.scripts.DiscardPending()

			return fmt.Errorf("Lua passive mapping returned out-of-bounds cell")
		}
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return err
	}

	for _, cell := range mapped {
		if err := level.MapCell(cell.x, cell.y); err != nil {
			return err
		}
	}

	level.mappingLevel = mappingLevel

	return nil
}

func gridPoints(value any, source string) ([]point, error) {
	if empty, ok := value.(map[string]any); ok && len(empty) == 0 {
		return nil, nil
	}

	entries, ok := value.([]any)

	if !ok {
		return nil, fmt.Errorf("Lua %s returned invalid cells", source)
	}

	cells := make([]point, 0, len(entries))

	for _, entry := range entries {
		fields, ok := entry.(map[string]any)

		if !ok {
			return nil, fmt.Errorf("Lua %s returned invalid cell", source)
		}

		x, xOK := fields["x"].(int64)
		y, yOK := fields["y"].(int64)

		if !xOK ||
			!yOK ||
			x < 0 ||
			y < 0 {
			return nil, fmt.Errorf("Lua %s returned invalid coordinates", source)
		}

		cells = append(cells, point{
			x: int(x),
			y: int(y),
		})
	}

	return cells, nil
}
