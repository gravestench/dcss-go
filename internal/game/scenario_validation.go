package game

import "fmt"

func initialMonsterBudget(level *Level, scenarioID string) int {
	if level == nil {
		return 0
	}

	if scenarioID == populationScenarioID && level.initialMonsters == 0 {
		// Version-8 fixed population saves predate per-level budgets.
		return populationMonstersPerLevel
	}

	return level.initialMonsters
}

func initialActorBudget(level *Level, scenarioID string) int {
	if level == nil {
		return 0
	}

	if level.initialActors > 0 {
		return level.initialActors
	}

	// Older version-8 saves had one actor per population choice.
	return initialMonsterBudget(level, scenarioID)
}

func validateScenarioLevels(levels map[int]*Level, scenarioID string) error {
	for id, level := range levels {
		choices := initialMonsterBudget(level, scenarioID)

		if scenarioID == generatedDungeonScenarioID ||
			scenarioID == populationScenarioID {
			if level.initialActors != 0 &&
				(level.initialActors < choices || level.initialActors > 4*choices) {
				return fmt.Errorf("Dungeon:%d has invalid initial actor count", id)
			}
		} else if level.initialActors != 0 {
			return fmt.Errorf("fixture Dungeon:%d has an initial actor count", id)
		}
	}

	if scenarioID != generatedDungeonScenarioID {
		for id, level := range levels {
			for _, link := range level.StairLinks() {
				if link.Unavailable != "" {
					return fmt.Errorf("fixed Dungeon:%d has an unavailable stair", id)
				}
			}
		}
	}

	switch scenarioID {
	case generatedDungeonScenarioID:
		return validateGeneratedDungeonLevels(levels)

	case populationScenarioID:
		for id, level := range levels {
			if level.initialMonsters != 0 &&
				level.initialMonsters != populationMonstersPerLevel {
				return fmt.Errorf("fixed Dungeon:%d has invalid monster budget", id)
			}
		}

	default:
		for id, level := range levels {
			if level.initialMonsters != 0 {
				return fmt.Errorf("fixture Dungeon:%d has a monster budget", id)
			}
		}
	}

	return nil
}

func validateGeneratedDungeonLevels(levels map[int]*Level) error {
	first := levels[1]
	second := levels[2]

	if len(levels) != 2 || first == nil || second == nil {
		return fmt.Errorf("generated Dungeon save needs exactly D:1-2")
	}

	for depth, level := range levels {
		if level.width != 80 ||
			len(level.terrain) != 70 ||
			len(level.StairLinks()) != 6 {
			return fmt.Errorf("generated Dungeon:%d has invalid geometry or stair count", depth)
		}

		maximum := 36

		if depth == 2 {
			maximum = 30
		}

		if level.initialMonsters < 3 || level.initialMonsters > maximum {
			return fmt.Errorf("generated Dungeon:%d has invalid monster budget", depth)
		}

		upCount, downCount := 0, 0

		for _, link := range level.StairLinks() {
			glyph := level.terrain[link.Y][link.X]

			if glyph == '<' {
				upCount++
			} else {
				downCount++
			}

			if depth == 1 && glyph == '<' {
				if link.Unavailable != exitDungeonUnavailable {
					return fmt.Errorf("generated Dungeon:1 has an invalid exit")
				}

				continue
			}

			if depth == 2 && glyph == '>' {
				if link.Unavailable != dungeonThreeUnavailable {
					return fmt.Errorf("generated Dungeon:2 has an invalid exit")
				}

				continue
			}

			if !reciprocalGeneratedStair(levels, depth, link) {
				return fmt.Errorf("generated Dungeon:%d has an unpaired stair", depth)
			}
		}

		if upCount != 3 || downCount != 3 {
			return fmt.Errorf("generated Dungeon:%d needs three stair pairs", depth)
		}
	}

	return nil
}

func reciprocalGeneratedStair(levels map[int]*Level, depth int, link StairLink) bool {
	target := levels[link.ToLevelID]

	if target == nil || link.Unavailable != "" || link.ToLevelID != 3-depth {
		return false
	}

	other, found := target.StairAt(link.ToX, link.ToY)

	if !found ||
		other.ToLevelID != depth ||
		other.ToX != link.X ||
		other.ToY != link.Y {
		return false
	}

	fromGlyph := levels[depth].terrain[link.Y][link.X]
	toGlyph := target.terrain[link.ToY][link.ToX]

	return depth == 1 && fromGlyph == '>' && toGlyph == '<' ||
		depth == 2 && fromGlyph == '<' && toGlyph == '>'
}
