package game

import (
	"fmt"
	"sort"
)

// The fixed map starts the player and places the D:2 arrival at (1,1).
// Keeping monsters away from that cell prevents an immediate spawn collision.
const spawnDistanceFromEntry = 5

func (g *Game) spawnFixtureAnimals() error {
	factory := newOrdinaryMonsterFactory(g)
	if _, err := factory.Spawn("MONS_RAT", 1, 4, 1); err != nil {
		return err
	}
	if _, err := factory.Spawn("MONS_QUOKKA", 2, 14, 7); err != nil {
		return err
	}
	if _, err := factory.Spawn("MONS_FRILLED_LIZARD", 2, 14, 1); err != nil {
		return err
	}
	return nil
}

// populateDungeon reads immutable source weights, then creates live Akara
// actors. The two named RNG streams keep monster choice independent of map
// placement, and their states already travel with the run's save.
func (g *Game) populateDungeon() error {
	factory := newOrdinaryMonsterFactory(g)
	levelIDs := make([]int, 0, len(g.levels))
	for id := range g.levels {
		levelIDs = append(levelIDs, id)
	}
	sort.Ints(levelIDs)

	entry := point{
		x: 1,
		y: 1,
	}
	for _, levelID := range levelIDs {
		level := g.levels[levelID]
		pool := g.catalog.DungeonMonsterPool(levelID, func(id string) bool {
			return !isOrdinaryAnimal(id)
		})
		if pool.TotalWeight() == 0 {
			return fmt.Errorf("Dungeon:%d has no supported population", levelID)
		}

		for slot := 0; slot < populationMonstersPerLevel; slot++ {
			cells := level.spawnCellsAwayFrom(entry, spawnDistanceFromEntry)
			if len(cells) == 0 {
				return fmt.Errorf("Dungeon:%d has no free monster spawn cell", levelID)
			}
			roll, err := g.rng.Intn("population", pool.TotalWeight())
			if err != nil {
				return err
			}
			monsterID, err := pool.Pick(roll)
			if err != nil {
				return err
			}
			cellIndex, err := g.rng.Intn("placement", len(cells))
			if err != nil {
				return err
			}
			cell := cells[cellIndex]
			if _, err := factory.Spawn(monsterID, levelID, cell.x, cell.y); err != nil {
				return err
			}
		}
	}
	return nil
}

func (l *Level) spawnCellsAwayFrom(entry point, minimumDistance int) []point {
	var cells []point
	for y, row := range l.terrain {
		for x := range row {
			if row[x] != '.' || !farEnoughFromEntry(x, y, entry, minimumDistance) {
				continue
			}
			if _, occupied := l.ActorAt(x, y); occupied {
				continue
			}
			cells = append(cells, point{
				x: x,
				y: y,
			})
		}
	}
	return cells
}

func farEnoughFromEntry(x, y int, entry point, minimumDistance int) bool {
	dx := x - entry.x
	if dx < 0 {
		dx = -dx
	}
	dy := y - entry.y
	if dy < 0 {
		dy = -dy
	}
	return max(dx, dy) >= minimumDistance
}
