package game

import (
	"fmt"
	"sort"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"dcrawl-go/internal/visibility"
	"github.com/gravestench/akara"
)

// Keeping monsters away from an entry prevents an immediate spawn collision.
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
// actors. Named RNG streams keep monster choice, band size, and placement
// independent, and their states travel with the run's save.
func (g *Game) populateDungeon(entries map[int]point) error {
	factory := newOrdinaryMonsterFactory(g)
	levelIDs := make([]int, 0, len(g.levels))

	for id := range g.levels {
		levelIDs = append(levelIDs, id)
	}

	sort.Ints(levelIDs)

	for _, levelID := range levelIDs {
		level := g.levels[levelID]
		entry, found := entries[levelID]

		if !found || level.initialMonsters <= 0 {
			return fmt.Errorf("Dungeon:%d has no population entry or budget", levelID)
		}

		pool := g.catalog.DungeonMonsterPool(levelID, func(id string) bool {
			return !isOrdinaryAnimal(id)
		})

		if pool.TotalWeight() == 0 {
			return fmt.Errorf("Dungeon:%d has no supported population", levelID)
		}

		for slot := 0; slot < level.initialMonsters; slot++ {
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

			leader, err := factory.Spawn(monsterID, levelID, cell.x, cell.y)

			if err != nil {
				return err
			}

			level.initialActors++

			if monsterID == "MONS_JACKAL" {
				if err := g.spawnJackalFollowers(factory, level, leader, cell); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

// A source band is created after its leader. Each member gets up to 1000
// nearby placement attempts; an unavailable cell only skips that member.
func (g *Game) spawnJackalFollowers(
	factory ordinaryMonsterFactory,
	level *Level,
	leader akara.Entity,
	origin point,
) error {
	count, err := monster.JackalFollowerCount(g.rng)

	if err != nil {
		return err
	}

	visible, err := visibility.Compute(level.terrain, origin.x, origin.y, 7)

	if err != nil {
		return err
	}

	for member := 0; member < count; member++ {
		cell, found, err := g.findJackalFollowerCell(level, origin, visible)

		if err != nil {
			return err
		}

		if !found {
			continue
		}

		follower, err := factory.Spawn("MONS_JACKAL", level.ID, cell.x, cell.y)

		if err != nil {
			return err
		}

		_, err = g.stores.Followers.Set(follower, ecs.BandFollower{
			Leader: leader,
		})

		if err != nil {
			return err
		}

		level.initialActors++
	}

	return nil
}

func (g *Game) findJackalFollowerCell(
	level *Level,
	origin point,
	visible []bool,
) (point, bool, error) {
	for attempt := 0; attempt < 1000; attempt++ {
		xRoll, err := g.rng.Intn("placement", 7)

		if err != nil {
			return point{}, false, err
		}

		yRoll, err := g.rng.Intn("placement", 7)

		if err != nil {
			return point{}, false, err
		}

		cell := point{
			x: origin.x + xRoll - 3,
			y: origin.y + yRoll - 3,
		}

		if !level.Walkable(cell.x, cell.y) {
			continue
		}

		if !visible[cell.y*level.width+cell.x] {
			continue
		}

		if _, occupied := level.ActorAt(cell.x, cell.y); occupied {
			continue
		}

		return cell, true, nil
	}

	return point{}, false, nil
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
