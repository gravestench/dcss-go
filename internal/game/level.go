package game

import (
	"fmt"
	"sort"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// Level owns terrain, stair links, away time, and its actor occupancy index.
// Position remains the source of truth for actor location.
type Level struct {
	ID         int
	terrain    []string
	remembered []byte
	width      int
	// Initial generation budget bounds earned XP during save validation.
	initialMonsters int
	positions       *akara.Store[ecs.Position]
	actors          map[point]akara.Entity
	// nil while active or before the player first visits this floor.
	awaySinceAut *Aut
	stairs       map[point]StairLink
}

type point struct {
	x, y int
}

// StairLink connects a stair cell to an arrival cell on another level.
// The level owns its outgoing links; the world validates destinations.
type StairLink struct {
	X           int
	Y           int
	ToLevelID   int
	ToX         int
	ToY         int
	Unavailable string
}

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
			case '#', '.', '+', '\'', '<', '>':
			default:
				return nil, fmt.Errorf("level %d unknown terrain %q at (%d,%d)", id, row[x], x, y)
			}
		}
	}

	return &Level{
		ID:         id,
		terrain:    append([]string(nil), rows...),
		remembered: make([]byte, width*len(rows)),
		width:      width,
		positions:  positions,
		actors:     make(map[point]akara.Entity),
		stairs:     make(map[point]StairLink),
	}, nil
}

func (l *Level) AddStairLink(link StairLink) error {
	if !l.inBounds(link.X, link.Y) ||
		(l.terrain[link.Y][link.X] != '<' && l.terrain[link.Y][link.X] != '>') {
		return fmt.Errorf("level %d has invalid stair link at (%d,%d)", l.ID, link.X, link.Y)
	}

	boundary := link.Unavailable != ""

	if boundary && (link.ToLevelID != 0 || link.ToX != 0 || link.ToY != 0) ||
		!boundary && (link.ToLevelID <= 0 || link.ToX < 0 || link.ToY < 0) {
		return fmt.Errorf("level %d has invalid stair destination at (%d,%d)", l.ID, link.X, link.Y)
	}

	location := point{
		x: link.X,
		y: link.Y,
	}

	if _, duplicate := l.stairs[location]; duplicate {
		return fmt.Errorf("level %d has duplicate stair link at (%d,%d)", l.ID, link.X, link.Y)
	}

	l.stairs[location] = link

	return nil
}

func (l *Level) StairAt(x, y int) (StairLink, bool) {
	link, found := l.stairs[point{
		x: x,
		y: y,
	}]

	return link, found
}

func (l *Level) StairLinks() []StairLink {
	links := make([]StairLink, 0, len(l.stairs))

	for _, link := range l.stairs {
		links = append(links, link)
	}

	sort.Slice(links, func(i, j int) bool {
		if links[i].Y != links[j].Y {
			return links[i].Y < links[j].Y
		}

		return links[i].X < links[j].X
	})

	return links
}

func validateStairLinks(levels map[int]*Level) error {
	ids := make([]int, 0, len(levels))

	for id := range levels {
		ids = append(ids, id)
	}

	sort.Ints(ids)

	for _, id := range ids {
		level := levels[id]

		for y, row := range level.terrain {
			for x := range row {
				if row[x] != '<' && row[x] != '>' {
					continue
				}

				if _, found := level.StairAt(x, y); !found {
					return fmt.Errorf("level %d missing stair link at (%d,%d)", id, x, y)
				}
			}
		}

		for _, link := range level.StairLinks() {
			if link.Unavailable != "" {
				continue
			}

			target := levels[link.ToLevelID]

			if target == nil || !target.Walkable(link.ToX, link.ToY) {
				return fmt.Errorf(
					"level %d stair at (%d,%d) has invalid destination %d:(%d,%d)",
					id, link.X, link.Y, link.ToLevelID, link.ToX, link.ToY,
				)
			}
		}
	}

	return nil
}

func (l *Level) inBounds(x, y int) bool {
	return y >= 0 && y < len(l.terrain) && x >= 0 && x < l.width
}

func (l *Level) Walkable(x, y int) bool {
	return l.inBounds(x, y) && l.terrain[y][x] != '#' && l.terrain[y][x] != '+'
}

// OpenDoor changes the entire four-connected closed-door group, as the pinned
// terrain.cc:751-785 does for a multi-cell door. Known cells also update when
// an opened segment lies outside current sight.
func (l *Level) OpenDoor(x, y int) (int, error) {
	if !l.inBounds(x, y) || l.terrain[y][x] != '+' {
		return 0, fmt.Errorf("level %d has no closed door at (%d,%d)", l.ID, x, y)
	}

	queue := []point{
		{
			x: x,
			y: y,
		},
	}
	opened := 0

	for len(queue) > 0 {
		cell := queue[0]
		queue = queue[1:]

		if !l.inBounds(cell.x, cell.y) || l.terrain[cell.y][cell.x] != '+' {
			continue
		}

		row := []byte(l.terrain[cell.y])
		row[cell.x] = '\''
		l.terrain[cell.y] = string(row)
		opened++

		index := cell.y*l.width + cell.x

		if l.remembered[index] != 0 {
			l.remembered[index] = '\''
		}

		queue = append(queue,
			point{
				x: cell.x + 1,
				y: cell.y,
			},
			point{
				x: cell.x - 1,
				y: cell.y,
			},
			point{
				x: cell.x,
				y: cell.y + 1,
			},
			point{
				x: cell.x,
				y: cell.y - 1,
			},
		)
	}

	return opened, nil
}

func (l *Level) ActorAt(x, y int) (akara.Entity, bool) {
	actor, ok := l.actors[point{
		x: x,
		y: y,
	}]

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

	if _, err := l.positions.Set(entity, ecs.Position{
		LevelID: l.ID,
		X:       x,
		Y:       y,
	}); err != nil {
		return err
	}

	l.actors[point{
		x: x,
		y: y,
	}] = entity

	return nil
}

func (l *Level) MoveActor(entity akara.Entity, x, y int) error {
	position, found := l.positions.Get(entity)

	if !found || position.LevelID != l.ID || l.actors[point{
		x: position.X,
		y: position.Y,
	}] != entity {
		return fmt.Errorf("entity %d is not indexed on level %d", entity, l.ID)
	}

	if !l.Walkable(x, y) {
		return fmt.Errorf("level %d location (%d,%d) is blocked", l.ID, x, y)
	}

	if other, occupied := l.ActorAt(x, y); occupied && other != entity {
		return fmt.Errorf("level %d location (%d,%d) is occupied", l.ID, x, y)
	}

	delete(l.actors, point{
		x: position.X,
		y: position.Y,
	})
	position.X = x
	position.Y = y
	l.actors[point{
		x: x,
		y: y,
	}] = entity

	return nil
}

func (l *Level) RemoveActor(entity akara.Entity) error {
	position, found := l.positions.Get(entity)

	if !found || position.LevelID != l.ID || l.actors[point{
		x: position.X,
		y: position.Y,
	}] != entity {
		return fmt.Errorf("entity %d is not indexed on level %d", entity, l.ID)
	}

	delete(l.actors, point{
		x: position.X,
		y: position.Y,
	})
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
			case '#', '.', '+', '\'', '<', '>':
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
