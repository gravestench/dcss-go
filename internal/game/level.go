package game

import (
	"fmt"
	"sort"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"crawl/internal/vault"
	"github.com/gravestench/akara"
)

// Level owns terrain, stair links, away time, and its actor occupancy index.
// Position remains the source of truth for actor location.
type Level struct {
	ID            int
	BranchID      string
	LocalDepth    int
	terrain       [][]terrain.ID
	remembered    []terrain.ID
	seen          []bool
	detectedItems []bool
	width         int
	mappingLevel  int

	// Population choices may generate bands with multiple actors.
	initialMonsters int
	initialActors   int
	spawnExclusions []point

	positions *akara.Store[ecs.Position]
	actors    map[point]akara.Entity

	// nil while active or before the player first visits this floor.
	awaySinceAut *Aut
	stairs       map[point]StairLink
	vaultID      string
	vaultIDs     []string
	vaultRecords []vault.Record
	cellColours  map[point]string

	// Shoals heights are authored terrain elevations. The tide changes the
	// visible feature, but never overwrites the elevation beneath it.
	shoalsHeights [][]int
	tideHeight    int
	tideVelocity  int
	tideLastAut   int64
}

type point struct {
	x int
	y int
}

// StairLink connects a stair cell to an arrival cell on another level.
// The level owns its outgoing links; the world validates destinations.
type StairLink struct {
	X           int
	Y           int
	ToLevelID   int
	ToX         int
	ToY         int
	Pending     bool
	Exit        bool
	Unavailable string
	// Source feature identity is carried beside the generic linked-stair grid
	// cell until the renderer and branch travel policy use the exact feature.
	TargetBranchID string
	SourceFeature  string
}

func NewLevel(id int, cells [][]terrain.ID, positions *akara.Store[ecs.Position]) (*Level, error) {
	if id <= 0 ||
		positions == nil ||
		len(cells) == 0 ||
		len(cells[0]) == 0 {
		return nil, fmt.Errorf("invalid level definition")
	}

	width := len(cells[0])

	for y, row := range cells {
		if len(row) != width {
			return nil, fmt.Errorf("level %d row %d has width %d, want %d", id, y, len(row), width)
		}

		for x, feature := range row {
			if !terrain.Valid(feature) {
				return nil, fmt.Errorf("level %d unknown terrain %q at (%d,%d)", id, feature, x, y)
			}
		}
	}

	owned := make([][]terrain.ID, len(cells))

	for y, row := range cells {
		owned[y] = append([]terrain.ID(nil), row...)
	}

	return &Level{
		ID:            id,
		terrain:       owned,
		remembered:    make([]terrain.ID, width*len(cells)),
		seen:          make([]bool, width*len(cells)),
		detectedItems: make([]bool, width*len(cells)),
		width:         width,

		positions: positions,
		actors:    make(map[point]akara.Entity),

		stairs:      make(map[point]StairLink),
		cellColours: make(map[point]string),
	}, nil
}

// CellColour returns an explicit terrain tint, if one was placed by a vault
// or changed by a live Lua system. Terrain itself remains in the grid.
func (l *Level) CellColour(x, y int) (string, bool) {
	if !l.inBounds(x, y) {
		return "", false
	}

	cell := point{
		x: x,
		y: y,
	}

	colour, found := l.cellColours[cell]

	return colour, found
}

// SetCellColour accepts an empty ID to clear an override during rollback.
func (l *Level) SetCellColour(x, y int, colour string) error {
	if !l.inBounds(x, y) {
		return fmt.Errorf("level %d has no cell at (%d,%d)", l.ID, x, y)
	}

	cell := point{
		x: x,
		y: y,
	}

	if colour == "" {
		delete(l.cellColours, cell)
	} else {
		l.cellColours[cell] = colour
	}

	return nil
}

func validStairDestination(link StairLink) bool {
	if link.Exit {
		return !link.Pending &&
			link.Unavailable == "" &&
			link.ToLevelID == 0 &&
			link.ToX == 0 &&
			link.ToY == 0
	}

	if link.Pending {
		return link.Unavailable == "" &&
			link.ToLevelID > 0 &&
			link.ToX == 0 &&
			link.ToY == 0
	}

	if link.Unavailable != "" {
		return link.ToLevelID == 0 &&
			link.ToX == 0 &&
			link.ToY == 0
	}

	return link.ToLevelID > 0 &&
		link.ToX >= 0 &&
		link.ToY >= 0
}

func (l *Level) AddStairLink(link StairLink) error {
	if !l.inBounds(link.X, link.Y) ||
		!terrain.IsLinkedStair(l.terrain[link.Y][link.X]) {
		return fmt.Errorf("level %d has invalid stair link at (%d,%d)", l.ID, link.X, link.Y)
	}

	if !validStairDestination(link) {
		return fmt.Errorf("level %d has invalid stair destination at (%d,%d)", l.ID, link.X, link.Y)
	}

	if (link.TargetBranchID == "") != (link.SourceFeature == "") {
		return fmt.Errorf("level %d has incomplete branch stair identity", l.ID)
	}

	location := point{
		x: link.X,
		y: link.Y,
	}

	if prior, duplicate := l.stairs[location]; duplicate {
		return fmt.Errorf("level %d has duplicate stair link at (%d,%d): existing %+v, new %+v",
			l.ID, link.X, link.Y, prior, link)
	}

	l.stairs[location] = link

	return nil
}

// Resolve a frontier stair exactly once when its destination floor is built.
// The world validates the reciprocal landing after both levels are present.
func (l *Level) ResolveStairLink(x, y, toX, toY int) error {
	location := point{
		x: x,
		y: y,
	}

	link, found := l.stairs[location]

	if !found ||
		!link.Pending ||
		toX < 0 ||
		toY < 0 {
		return fmt.Errorf("level %d cannot resolve stair at (%d,%d)", l.ID, x, y)
	}

	link.ToX = toX
	link.ToY = toY
	link.Pending = false
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

func (l *Level) SetVaultID(id string) error {
	if id == "" || l.vaultID != "" {
		return fmt.Errorf("level %d has invalid vault identity %q", l.ID, id)
	}

	l.vaultID = id

	return nil
}

func (l *Level) VaultID() string {
	return l.vaultID
}

// SetVaultIDs records every map that placed successfully on this level,
// including controllers whose empty MAP generated no cell records.
func (l *Level) SetVaultIDs(ids []string) error {
	for _, id := range ids {
		if id == "" {
			return fmt.Errorf("level %d has an empty placed vault ID", l.ID)
		}
	}

	l.vaultIDs = append([]string(nil), ids...)

	return nil
}

// VaultIDs returns a copy because map-use history must survive later level
// edits unchanged for source uniqueness and save continuation.
func (l *Level) VaultIDs() []string {
	return append([]string(nil), l.vaultIDs...)
}

// AddVaultRecord accepts supplemental maps on floors with no primary vault.
// The record's source ID identifies its author independently of vaultID.
func (l *Level) AddVaultRecord(record vault.Record) error {
	if err := record.Validate(l.width, len(l.terrain)); err != nil {
		return fmt.Errorf("level %d: %w", l.ID, err)
	}

	l.vaultRecords = append(l.vaultRecords, vault.Clone([]vault.Record{record})[0])

	return nil
}

func (l *Level) VaultRecords() []vault.Record {
	return vault.Clone(l.vaultRecords)
}

func validateStairLinks(levels map[int]*Level) error {
	return validateStairLinksWithUnlinked(levels, nil)
}

// Rootless portal floors use visible stone stairs as command sources but
// route through Lua policy instead of a saved reciprocal link. The caller
// supplies their IDs from validated portal state before restore.
func validateStairLinksWithUnlinked(
	levels map[int]*Level,
	unlinked map[int]bool,
) error {
	ids := make([]int, 0, len(levels))

	for id := range levels {
		ids = append(ids, id)
	}

	sort.Ints(ids)

	for _, id := range ids {
		level := levels[id]

		for y, row := range level.terrain {
			for x := range row {
				if !terrain.IsLinkedStair(row[x]) {
					continue
				}

				if unlinked[id] && row[x] == terrain.StairsDown {
					continue
				}

				if _, found := level.StairAt(x, y); !found {
					return fmt.Errorf("level %d missing stair link at (%d,%d)", id, x, y)
				}
			}
		}

		for _, link := range level.StairLinks() {
			if link.Exit {
				continue
			}

			if link.Unavailable != "" {
				continue
			}

			if link.Pending {
				if link.ToLevelID <= 0 || levels[link.ToLevelID] != nil {
					return fmt.Errorf("level %d has invalid pending stair at (%d,%d)",
						id, link.X, link.Y)
				}

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
	return y >= 0 &&
		y < len(l.terrain) &&
		x >= 0 &&
		x < l.width
}

func (l *Level) Cells() [][]terrain.ID {
	cells := make([][]terrain.ID, len(l.terrain))

	for y, row := range l.terrain {
		cells[y] = append([]terrain.ID(nil), row...)
	}

	return cells
}

func (l *Level) Walkable(x, y int) bool {
	return l.inBounds(x, y) && terrain.Walkable(l.terrain[y][x])
}

// ClearProjectilePath traces the cell-centre ray between two actors. Walls,
// closed doors, and other actors stop an ordinary physical projectile.
func (l *Level) ClearProjectilePath(fromX, fromY, toX, toY int) bool {
	if !l.Walkable(fromX, fromY) ||
		!l.Walkable(toX, toY) ||
		(fromX == toX && fromY == toY) {
		return false
	}

	dx := max(toX-fromX, fromX-toX)
	dy := max(toY-fromY, fromY-toY)
	stepX := 1
	stepY := 1

	if toX < fromX {
		stepX = -1
	}

	if toY < fromY {
		stepY = -1
	}

	x, y := fromX, fromY
	stepsX, stepsY := 0, 0

	for stepsX < dx || stepsY < dy {
		crossing := (1+2*stepsX)*dy - (1+2*stepsY)*dx

		if crossing <= 0 {
			x += stepX
			stepsX++
		}

		if crossing >= 0 {
			y += stepY
			stepsY++
		}

		if !l.Walkable(x, y) {
			return false
		}

		if x == toX && y == toY {
			return true
		}

		if _, occupied := l.ActorAt(x, y); occupied {
			return false
		}
	}

	return true
}

// OpenDoor changes the entire four-connected closed-door group, as the pinned
// terrain.cc:751-785 does for a multi-cell door. Known cells also update when
// an opened segment lies outside current sight.
func (l *Level) OpenDoor(x, y int) (int, error) {
	cells, err := l.doorGroup(x, y, terrain.ClosedDoor)

	if err != nil {
		return 0, err
	}

	l.changeDoorCells(cells, terrain.OpenDoor)

	return len(cells), nil
}

// CloseDoor changes one connected open-door group after the caller has moved
// floor items away. No actor may stand in any segment of the group.
func (l *Level) CloseDoor(x, y int) (int, error) {
	cells, err := l.doorGroup(x, y, terrain.OpenDoor)

	if err != nil {
		return 0, err
	}

	for _, cell := range cells {
		if _, occupied := l.ActorAt(cell.x, cell.y); occupied {
			return 0, fmt.Errorf("level %d door at (%d,%d) has an actor", l.ID, cell.x, cell.y)
		}
	}

	l.changeDoorCells(cells, terrain.ClosedDoor)

	return len(cells), nil
}

// doorGroup follows find_connected_identical in terrain.cc:751-785.
func (l *Level) doorGroup(x, y int, feature terrain.ID) ([]point, error) {
	if !l.inBounds(x, y) || l.terrain[y][x] != feature {
		return nil, fmt.Errorf("level %d has no %q door at (%d,%d)", l.ID, feature, x, y)
	}

	queue := []point{
		{
			x: x,
			y: y,
		},
	}

	seen := make(map[point]bool)
	var cells []point

	for len(queue) > 0 {
		cell := queue[0]
		queue = queue[1:]

		if seen[cell] ||
			!l.inBounds(cell.x, cell.y) ||
			l.terrain[cell.y][cell.x] != feature {
			continue
		}

		seen[cell] = true
		cells = append(cells, cell)
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

	// The C++ source stores connected cells in an ordered set. Its coordinate
	// comparison sorts by x, then y, which sets blocker and item-push order.
	sort.Slice(cells, func(i, j int) bool {
		if cells[i].x == cells[j].x {
			return cells[i].y < cells[j].y
		}

		return cells[i].x < cells[j].x
	})

	return cells, nil
}

func (l *Level) changeDoorCells(cells []point, feature terrain.ID) {
	for _, cell := range cells {
		l.terrain[cell.y][cell.x] = feature

		index := cell.y*l.width + cell.x

		if l.remembered[index] != terrain.Unseen {
			l.remembered[index] = feature
		}
	}
}

// SetCell is the grid mutation primitive used by Lua generation and terrain
// policy. It keeps explored terrain in sync with the authoritative grid.
func (l *Level) SetCell(x, y int, feature terrain.ID) error {
	if !l.inBounds(x, y) {
		return fmt.Errorf("level %d has no cell at (%d,%d)", l.ID, x, y)
	}

	if !terrain.Valid(feature) {
		return fmt.Errorf("level %d has invalid terrain %q", l.ID, feature)
	}

	occupant, found := l.ActorAt(x, y)

	if found && !terrain.Walkable(feature) {
		return fmt.Errorf("terrain %q would block actor %d", feature, occupant)
	}

	_, linked := l.StairAt(x, y)

	if linked &&
		!terrain.IsLinkedStair(feature) {
		return fmt.Errorf("terrain would remove stair link at (%d,%d)", x, y)
	}

	l.changeDoorCells([]point{
		{
			x: x,
			y: y,
		},
	}, feature)

	return nil
}

func (l *Level) ActorAt(x, y int) (akara.Entity, bool) {
	actor, ok := l.actors[point{
		x: x,
		y: y,
	}]

	return actor, ok
}

func (l *Level) PlaceActor(entity akara.Entity, x, y int) error {
	if !l.Walkable(x, y) &&
		(!l.inBounds(x, y) || l.terrain[y][x] != terrain.MalignGateway) {
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

	if !found ||
		position.LevelID != l.ID || l.actors[point{
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

	if !found ||
		position.LevelID != l.ID || l.actors[point{
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

// KnownCells returns the player's remembered feature IDs. Empty IDs are unseen.
func (l *Level) KnownCells() [][]terrain.ID {
	cells := make([][]terrain.ID, len(l.terrain))

	for y := range cells {
		start := y * l.width

		cells[y] = append([]terrain.ID(nil), l.remembered[start:start+l.width]...)
	}

	return cells
}

// SeenCells records actual sight separately from magic-mapped terrain.
// Mapped cells can become newly seen later and trigger exploration effects.
func (l *Level) SeenCells() [][]bool {
	cells := make([][]bool, len(l.terrain))

	for y := range cells {
		start := y * l.width

		cells[y] = append([]bool(nil), l.seen[start:start+l.width]...)
	}

	return cells
}

func (l *Level) DetectedItems() [][]bool {
	cells := make([][]bool, len(l.terrain))

	for y := range cells {
		start := y * l.width

		cells[y] = append([]bool(nil), l.detectedItems[start:start+l.width]...)
	}

	return cells
}

func (l *Level) LoadDetectedItems(cells [][]bool) error {
	if len(cells) != len(l.terrain) {
		return fmt.Errorf("level %d has %d detected item rows, want %d", l.ID, len(cells), len(l.terrain))
	}

	detected := make([]bool, l.width*len(cells))

	for y, row := range cells {
		if len(row) != l.width {
			return fmt.Errorf("level %d detected item row %d has width %d, want %d", l.ID, y, len(row), l.width)
		}

		copy(detected[y*l.width:(y+1)*l.width], row)
	}

	l.detectedItems = detected

	return nil
}

func (l *Level) DetectItem(x, y int) error {
	if !l.inBounds(x, y) {
		return fmt.Errorf("level %d cannot detect item at (%d,%d)", l.ID, x, y)
	}

	l.detectedItems[y*l.width+x] = true

	return nil
}

// LoadKnownCells validates and replaces saved map knowledge without exposing
// live terrain at cells the player has not seen.
func (l *Level) LoadKnownCells(cells [][]terrain.ID) error {
	if len(cells) != len(l.terrain) {
		return fmt.Errorf("level %d has %d known rows, want %d", l.ID, len(cells), len(l.terrain))
	}

	known := make([]terrain.ID, l.width*len(cells))

	for y, row := range cells {
		if len(row) != l.width {
			return fmt.Errorf("level %d known row %d has width %d, want %d", l.ID, y, len(row), l.width)
		}

		for x, feature := range row {
			if feature != terrain.Unseen && !terrain.Valid(feature) {
				return fmt.Errorf("level %d invalid remembered terrain %q at (%d,%d)", l.ID, feature, x, y)
			}

			known[y*l.width+x] = feature
		}
	}

	l.remembered = known

	return nil
}

func (l *Level) LoadSeenCells(cells [][]bool) error {
	if len(cells) != len(l.terrain) {
		return fmt.Errorf("level %d has %d seen rows, want %d", l.ID, len(cells), len(l.terrain))
	}

	seen := make([]bool, l.width*len(cells))

	for y, row := range cells {
		if len(row) != l.width {
			return fmt.Errorf("level %d seen row %d has width %d, want %d", l.ID, y, len(row), l.width)
		}

		for x, value := range row {
			index := y*l.width + x

			if value && l.remembered[index] == terrain.Unseen {
				return fmt.Errorf("level %d seen cell (%d,%d) lacks known terrain", l.ID, x, y)
			}

			seen[index] = value
		}
	}

	l.seen = seen

	return nil
}

func (l *Level) Remember(visible []bool) ([]point, error) {
	if len(visible) != len(l.remembered) {
		return nil, fmt.Errorf(
			"level %d sight mask has %d cells, want %d",
			l.ID,
			len(visible),
			len(l.remembered),
		)
	}

	newlySeen := make([]point, 0)

	for y, row := range l.terrain {
		for x := 0; x < l.width; x++ {
			index := y*l.width + x

			if visible[index] {
				l.remembered[index] = row[x]
				l.detectedItems[index] = false

				if !l.seen[index] {
					l.seen[index] = true
					newlySeen = append(newlySeen, point{
						x: x,
						y: y,
					})
				}
			}
		}
	}

	return newlySeen, nil
}

// MapCell remembers terrain without treating it as actually seen. Solid
// interior cells remain hidden until one of their neighbours opens.
func (l *Level) MapCell(x, y int) error {
	if !l.inBounds(x, y) {
		return fmt.Errorf("level %d cannot map cell (%d,%d)", l.ID, x, y)
	}

	index := y*l.width + x

	if l.seen[index] || l.remembered[index] != terrain.Unseen {
		return nil
	}

	feature := l.terrain[y][x]

	if !terrain.Walkable(feature) && feature != terrain.ClosedDoor {
		open := false

		for dy := -1; dy <= 1 && !open; dy++ {
			for dx := -1; dx <= 1; dx++ {
				if dx == 0 && dy == 0 {
					continue
				}

				nx, ny := x+dx, y+dy

				if l.inBounds(nx, ny) &&
					(!terrain.Opaque(l.terrain[ny][nx]) ||
						l.terrain[ny][nx] == terrain.ClosedDoor) {
					open = true
					break
				}
			}
		}

		if !open {
			return nil
		}
	}

	l.remembered[index] = feature

	return nil
}
