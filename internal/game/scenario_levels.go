package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/levelgen"
	"github.com/gravestench/akara"
)

const exitDungeonUnavailable = "Leaving the Dungeon is unavailable in the Go port."

const dungeonThreeUnavailable = "Dungeon:3 is unavailable in the Go port."

// scenarioLevels contains the terrain-specific part of a new run. The common
// scenario constructor owns entities and systems after this setup returns.
type scenarioLevels struct {
	levels            map[int]*Level
	entry             point
	populationEntries map[int]point
	curing            point
	heal              point
}

func buildScenarioLevels(
	scenarioID string,
	positions *akara.Store[ecs.Position],
	rng *RNGStreams,
) (scenarioLevels, error) {
	switch scenarioID {
	case ordinaryAnimalScenarioID, populationScenarioID:
		return buildFixedScenarioLevels(scenarioID, positions)

	case generatedDungeonScenarioID:
		return buildGeneratedDungeonLevels(positions, rng)

	default:
		return scenarioLevels{}, fmt.Errorf("unsupported scenario ID %q", scenarioID)
	}
}

func buildFixedScenarioLevels(
	scenarioID string,
	positions *akara.Store[ecs.Position],
) (scenarioLevels, error) {
	first, err := NewLevel(1, []string{
		"#################",
		"#.......#.......#",
		"#.#.....#.......#",
		"#......>#.......#",
		"#...............#",
		"#.......#.......#",
		"#.......#.......#",
		"#.......#.......#",
		"#################",
	}, positions)

	if err != nil {
		return scenarioLevels{}, err
	}

	second, err := NewLevel(2, []string{
		"#################",
		"#<......#.......#",
		"#.......#.......#",
		"#.......#.......#",
		"#...............#",
		"#.......#.......#",
		"#.......#.......#",
		"#.......#.......#",
		"#################",
	}, positions)

	if err != nil {
		return scenarioLevels{}, err
	}

	if err := first.AddStairLink(StairLink{
		X:         7,
		Y:         3,
		ToLevelID: 2,
		ToX:       1,
		ToY:       1,
	}); err != nil {
		return scenarioLevels{}, err
	}

	if err := second.AddStairLink(StairLink{
		X:         1,
		Y:         1,
		ToLevelID: 1,
		ToX:       7,
		ToY:       3,
	}); err != nil {
		return scenarioLevels{}, err
	}

	levels := map[int]*Level{
		1: first,
		2: second,
	}

	if err := validateStairLinks(levels); err != nil {
		return scenarioLevels{}, err
	}

	if scenarioID == populationScenarioID {
		first.initialMonsters = populationMonstersPerLevel
		second.initialMonsters = populationMonstersPerLevel
	}

	entry := point{
		x: 1,
		y: 1,
	}

	return scenarioLevels{
		levels: levels,
		entry:  entry,
		populationEntries: map[int]point{
			1: entry,
			2: entry,
		},
		curing: point{
			x: 4,
			y: 2,
		},
		heal: point{
			x: 2,
			y: 1,
		},
	}, nil
}

func buildGeneratedDungeonLevels(
	positions *akara.Store[ecs.Position],
	rng *RNGStreams,
) (scenarioLevels, error) {
	firstLayout, err := levelgen.BasicDungeon(1, func() uint64 {
		return rng.next("layout")
	})

	if err != nil {
		return scenarioLevels{}, err
	}

	secondLayout, err := levelgen.BasicDungeon(2, func() uint64 {
		return rng.next("layout")
	})

	if err != nil {
		return scenarioLevels{}, err
	}

	first, err := NewLevel(1, firstLayout.Rows, positions)

	if err != nil {
		return scenarioLevels{}, err
	}

	second, err := NewLevel(2, secondLayout.Rows, positions)

	if err != nil {
		return scenarioLevels{}, err
	}

	if err := linkGeneratedStairs(first, second, firstLayout, secondLayout); err != nil {
		return scenarioLevels{}, err
	}

	first.initialMonsters, err = sourceDungeonMonsterCount(rng, 1)

	if err != nil {
		return scenarioLevels{}, err
	}

	second.initialMonsters, err = sourceDungeonMonsterCount(rng, 2)

	if err != nil {
		return scenarioLevels{}, err
	}

	entry := point{
		x: firstLayout.Stairs[0].Up.X,
		y: firstLayout.Stairs[0].Up.Y,
	}

	secondEntry := point{
		x: secondLayout.Stairs[0].Up.X,
		y: secondLayout.Stairs[0].Up.Y,
	}

	curing, err := nearestOpenFloor(first, entry)

	if err != nil {
		return scenarioLevels{}, err
	}

	heal, err := nearestOpenFloor(second, secondEntry)

	if err != nil {
		return scenarioLevels{}, err
	}

	levels := map[int]*Level{
		1: first,
		2: second,
	}

	if err := validateStairLinks(levels); err != nil {
		return scenarioLevels{}, err
	}

	return scenarioLevels{
		levels: levels,
		entry:  entry,
		populationEntries: map[int]point{
			1: entry,
			2: secondEntry,
		},
		curing: curing,
		heal:   heal,
	}, nil
}

func linkGeneratedStairs(first, second *Level, firstMap, secondMap levelgen.Layout) error {
	for index := range firstMap.Stairs {
		firstPair := firstMap.Stairs[index]
		secondPair := secondMap.Stairs[index]

		if err := first.AddStairLink(StairLink{
			X:           firstPair.Up.X,
			Y:           firstPair.Up.Y,
			Unavailable: exitDungeonUnavailable,
		}); err != nil {
			return err
		}

		if err := first.AddStairLink(StairLink{
			X:         firstPair.Down.X,
			Y:         firstPair.Down.Y,
			ToLevelID: 2,
			ToX:       secondPair.Up.X,
			ToY:       secondPair.Up.Y,
		}); err != nil {
			return err
		}

		if err := second.AddStairLink(StairLink{
			X:         secondPair.Up.X,
			Y:         secondPair.Up.Y,
			ToLevelID: 1,
			ToX:       firstPair.Down.X,
			ToY:       firstPair.Down.Y,
		}); err != nil {
			return err
		}

		if err := second.AddStairLink(StairLink{
			X:           secondPair.Down.X,
			Y:           secondPair.Down.Y,
			Unavailable: dungeonThreeUnavailable,
		}); err != nil {
			return err
		}
	}

	return nil
}

// The source's _num_mons_wanted rolls three Dungeon-specific dice before
// clamping to 60. At D:1-2 the largest possible roll is below that clamp.
func sourceDungeonMonsterCount(rng *RNGStreams, depth int) (int, error) {
	dieSize := 12

	if depth == 2 {
		dieSize = 10
	} else if depth != 1 {
		return 0, fmt.Errorf("unsupported Dungeon population depth %d", depth)
	}

	count := 0

	for die := 0; die < 3; die++ {
		roll, err := rng.Intn("population-count", dieSize)

		if err != nil {
			return 0, err
		}

		count += roll + 1
	}

	return count, nil
}

// Find an item cell reachable from its arrival stair without placing the item
// on a stair or behind a completely disconnected pocket.
func nearestOpenFloor(level *Level, start point) (point, error) {
	queue := []point{start}
	seen := map[point]bool{start: true}
	directions := [4]point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	}

	for len(queue) > 0 {
		cell := queue[0]
		queue = queue[1:]

		if level.terrain[cell.y][cell.x] == '.' {
			return cell, nil
		}

		for _, delta := range directions {
			next := point{
				x: cell.x + delta.x,
				y: cell.y + delta.y,
			}

			if !level.inBounds(next.x, next.y) || seen[next] || level.terrain[next.y][next.x] == '#' {
				continue
			}

			seen[next] = true
			queue = append(queue, next)
		}
	}

	return point{}, fmt.Errorf("Dungeon:%d has no reachable open floor", level.ID)
}
