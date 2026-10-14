package levelgen

import "fmt"

type trailStart struct {
	X      int
	Width  int
	Y      int
	Height int
}

var cardinalDirections = [4]Point{
	{
		X: 0,
		Y: -1,
	},

	{
		X: 1,
		Y: 0,
	},

	{
		X: 0,
		Y: 1,
	},

	{
		X: -1,
		Y: 0,
	},
}

// makeTrail follows _make_trail in dgn-layouts.cc:289-374. The source
// abandons a failed trail and later stair repair handles it; this bounded
// category reports the failure instead of returning a partial layout.
func (b *builder) makeTrail(start trailStart) (StairPair, error) {
	var position Point
	found := false

	for attempt := 0; attempt <= 200; attempt++ {
		position = Point{
			X: start.X + b.roll(start.Width),
			Y: start.Y + b.roll(start.Height),
		}

		if b.viableTrailStart(position) {
			found = true
			break
		}
	}

	if !found {
		return StairPair{}, fmt.Errorf("no viable start within 201 draws")
	}

	begin := position
	length := 0
	finish := 0

	for attempts := 0; finish < b.corrCount; attempts++ {
		if attempts >= 200 {
			return StairPair{}, fmt.Errorf(
				"corridor ended after %d of %d segments within 200 attempts",
				finish,
				b.corrCount,
			)
		}

		direction := b.chooseTrailDirection(position)

		if direction.X == 0 && direction.Y == 0 {
			continue
		}

		if direction.X == 0 || length == 0 {
			length = b.roll(b.corrLength) + 2
		}

		var err error
		position, err = b.carveTrailSegment(position, direction, length)

		if err != nil {
			return StairPair{}, err
		}

		if finish == b.corrCount-1 && b.grid[position.Y][position.X] != '.' {
			finish -= 2
		}

		finish++
	}

	return StairPair{
		Down: begin,
		Up:   position,
	}, nil
}

func (b *builder) chooseTrailDirection(position Point) Point {
	var direction Point

	if b.roll(2) == 0 {
		direction.X = b.trailDirection(position.X, width)
	} else {
		direction.Y = b.trailDirection(position.Y, height)
	}

	return direction
}

func (b *builder) carveTrailSegment(position, direction Point, length int) (Point, error) {
	for step := 0; step < length; step++ {
		direction = inwardDirection(position, direction)
		next := Point{
			X: position.X + direction.X,
			Y: position.Y + direction.Y,
		}

		beyond := Point{
			X: next.X + direction.X,
			Y: next.Y + direction.Y,
		}

		if !b.inBounds(next) || !b.inBounds(beyond) {
			return Point{}, fmt.Errorf("trail escaped the map")
		}

		if b.grid[beyond.Y][beyond.X] == '.' && !b.oneIn(b.intersectIn) {
			break
		}

		position = next

		if b.grid[position.Y][position.X] == '#' {
			b.grid[position.Y][position.X] = '.'
		}
	}

	return position, nil
}

func (b *builder) viableTrailStart(position Point) bool {
	terrain := b.grid[position.Y][position.X]

	if terrain != '#' && terrain != '.' {
		return false
	}

	for _, direction := range cardinalDirections {
		adjacent := Point{
			X: position.X + direction.X,
			Y: position.Y + direction.Y,
		}

		if b.inBounds(adjacent) && b.grid[adjacent.Y][adjacent.X] == '#' {
			return true
		}
	}

	return false
}

// _trail_random_dir chooses an inward direction near the edge, but a 2/5
// draw can still override the bias with either direction.
func (b *builder) trailDirection(position, bound int) int {
	direction := 0

	if position < 15 {
		direction = 1
	} else if position > bound-15 {
		direction = -1
	}

	if direction == 0 || b.chanceIn(2, 5) {
		if b.roll(2) == 0 {
			return -1
		}

		return 1
	}

	return direction
}

func inwardDirection(position, direction Point) Point {
	if position.X < 4 {
		direction = Point{X: 1}
	}

	if position.X > width-1-4 {
		direction = Point{X: -1}
	}

	if position.Y < 4 {
		direction = Point{Y: 1}
	}

	if position.Y > height-1-4 {
		direction = Point{Y: -1}
	}

	return direction
}

// connect carves an orthogonal shortest path. The pinned join_the_dots
// pathfinder uses a private subgenerator; this is its connectivity contract,
// not a claim of matching its exact cells or random sequence.
func (b *builder) connect(from, to Point) {
	position := from

	for position != to {
		horizontal := position.X != to.X
		vertical := position.Y != to.Y

		if horizontal && vertical {
			horizontal = b.roll(2) == 0
		}

		if horizontal {
			if position.X < to.X {
				position.X++
			} else {
				position.X--
			}
		} else {
			if position.Y < to.Y {
				position.Y++
			} else {
				position.Y--
			}
		}

		if b.grid[position.Y][position.X] == '#' {
			b.grid[position.Y][position.X] = '.'
		}
	}
}
