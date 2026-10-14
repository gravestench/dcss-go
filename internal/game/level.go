package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// Level owns terrain and its actor occupancy index. Position remains the source of truth.
type Level struct {
	ID         int
	terrain    []string
	remembered []byte
	width      int
	positions  *akara.Store[ecs.Position]
	actors     map[point]akara.Entity
}

type point struct{ x, y int }

func NewLevel(id int, rows []string, positions *akara.Store[ecs.Position]) (*Level, error) {
	if id <= 0 || positions == nil || len(rows) == 0 || len(rows[0]) == 0 {
		return nil, fmt.Errorf("invalid level definition")
	}
	width := len(rows[0])
	for y, row := range rows {
		if len(row) != width {
			return nil, fmt.Errorf("level %d row %d has width %d, want %d", id, y, len(row), width)
		}
		for x := range row {
			switch row[x] {
			case '#', '.', '<', '>':
			default:
				return nil, fmt.Errorf("level %d unknown terrain %q at (%d,%d)", id, row[x], x, y)
			}
		}
	}
	return &Level{ID: id, terrain: append([]string(nil), rows...), remembered: make([]byte, width*len(rows)), width: width, positions: positions, actors: make(map[point]akara.Entity)}, nil
}

func (l *Level) inBounds(x, y int) bool {
	return y >= 0 && y < len(l.terrain) && x >= 0 && x < l.width
}

func (l *Level) Walkable(x, y int) bool {
	return l.inBounds(x, y) && l.terrain[y][x] != '#'
}

func (l *Level) ActorAt(x, y int) (akara.Entity, bool) {
	actor, ok := l.actors[point{x, y}]
	return actor, ok
}

func (l *Level) PlaceActor(entity akara.Entity, x, y int) error {
	if !l.Walkable(x, y) {
		return fmt.Errorf("level %d location (%d,%d) is blocked", l.ID, x, y)
	}
	if _, occupied := l.ActorAt(x, y); occupied {
		return fmt.Errorf("level %d location (%d,%d) is occupied", l.ID, x, y)
	}
	if l.positions.Has(entity) {
		return fmt.Errorf("entity %d is already positioned", entity)
	}
	if _, err := l.positions.Set(entity, ecs.Position{LevelID: l.ID, X: x, Y: y}); err != nil {
		return err
	}
	l.actors[point{x, y}] = entity
	return nil
}

func (l *Level) MoveActor(entity akara.Entity, x, y int) error {
	position, found := l.positions.Get(entity)
	if !found || position.LevelID != l.ID || l.actors[point{position.X, position.Y}] != entity {
		return fmt.Errorf("entity %d is not indexed on level %d", entity, l.ID)
	}
	if !l.Walkable(x, y) {
		return fmt.Errorf("level %d location (%d,%d) is blocked", l.ID, x, y)
	}
	if other, occupied := l.ActorAt(x, y); occupied && other != entity {
		return fmt.Errorf("level %d location (%d,%d) is occupied", l.ID, x, y)
	}
	delete(l.actors, point{position.X, position.Y})
	position.X, position.Y = x, y
	l.actors[point{x, y}] = entity
	return nil
}

func (l *Level) RemoveActor(entity akara.Entity) error {
	position, found := l.positions.Get(entity)
	if !found || position.LevelID != l.ID || l.actors[point{position.X, position.Y}] != entity {
		return fmt.Errorf("entity %d is not indexed on level %d", entity, l.ID)
	}
	delete(l.actors, point{position.X, position.Y})
	l.positions.Remove(entity)
	return nil
}

// KnownRows returns the player's remembered terrain. Spaces mean unseen cells.
func (l *Level) KnownRows() []string {
	rows := make([]string, len(l.terrain))
	for y := range rows {
		row := make([]byte, l.width)
		for x := range row {
			if glyph := l.remembered[y*l.width+x]; glyph != 0 {
				row[x] = glyph
			} else {
				row[x] = ' '
			}
		}
		rows[y] = string(row)
	}
	return rows
}

// LoadKnownRows validates and replaces saved map knowledge without exposing
// live terrain at cells the player has not seen.
func (l *Level) LoadKnownRows(rows []string) error {
	if len(rows) != len(l.terrain) {
		return fmt.Errorf("level %d has %d known rows, want %d", l.ID, len(rows), len(l.terrain))
	}
	known := make([]byte, l.width*len(rows))
	for y, row := range rows {
		if len(row) != l.width {
			return fmt.Errorf("level %d known row %d has width %d, want %d", l.ID, y, len(row), l.width)
		}
		for x := 0; x < len(row); x++ {
			switch row[x] {
			case ' ':
			case '#', '.', '<', '>':
				known[y*l.width+x] = row[x]
			default:
				return fmt.Errorf("level %d invalid remembered terrain %q at (%d,%d)", l.ID, row[x], x, y)
			}
		}
	}
	l.remembered = known
	return nil
}

func (l *Level) Remember(visible []bool) error {
	if len(visible) != len(l.remembered) {
		return fmt.Errorf("level %d sight mask has %d cells, want %d", l.ID, len(visible), len(l.remembered))
	}
	for y, row := range l.terrain {
		for x := 0; x < l.width; x++ {
			if visible[y*l.width+x] {
				l.remembered[y*l.width+x] = row[x]
			}
		}
	}
	return nil
}

// FindUniqueTerrain finds the sole stair of a given kind on a fixed floor.
func (l *Level) FindUniqueTerrain(glyph byte) (x, y int, ok bool) {
	found := false
	for row, terrain := range l.terrain {
		for column := 0; column < l.width; column++ {
			if terrain[column] != glyph {
				continue
			}
			if found {
				return 0, 0, false
			}
			x, y, found = column, row, true
		}
	}
	return x, y, found
}
