package levelgen

import "fmt"

const width = 80

const height = 70

// Point identifies a cell in a Dungeon terrain grid.
type Point struct {
	X int
	Y int
}

// StairPair keeps the source's stair index across adjacent levels.
type StairPair struct {
	Up   Point
	Down Point
}

// Layout is terrain output. The game session later owns travel links and
// entities, so generation has no Akara or live-level dependency.
type Layout struct {
	Rows   []string
	Stairs [3]StairPair
}

type builder struct {
	grid        [height][width]byte
	next        func() uint64
	badRandom   bool
	corrLength  int
	corrCount   int
	intersectIn int
}

// BasicDungeon ports the geometry of layout_basic for Dungeon:1-2. Other
// Dungeon layouts and vaults require separate source-backed implementations.
func BasicDungeon(depth int, next func() uint64) (Layout, error) {
	if depth < 1 ||
		depth > 2 || next == nil {
		return Layout{}, fmt.Errorf("basic Dungeon layout needs depth 1 or 2 and a random source")
	}

	var lastErr error

	for attempt := 0; attempt < 16; attempt++ {
		b := &builder{next: next}

		for y := range b.grid {
			for x := range b.grid[y] {
				b.grid[y][x] = '#'
			}
		}

		stairs, err := b.build(depth)

		if b.badRandom {
			return Layout{}, fmt.Errorf("random source failed to provide a bounded draw")
		}

		if err != nil {
			lastErr = err
			continue
		}

		rows := make([]string, height)

		for y := range rows {
			rows[y] = string(b.grid[y][:])
		}

		return Layout{
			Rows:   rows,
			Stairs: stairs,
		}, nil
	}

	return Layout{}, fmt.Errorf("Dungeon:%d layout failed after 16 attempts: %w", depth, lastErr)
}

func (b *builder) build(depth int) ([3]StairPair, error) {
	// dgn-layouts.cc:49-56. random2(0) in the source returns zero.
	b.corrLength = 2 + b.roll(14)

	if b.oneIn(100) {
		b.corrCount = 500 + b.roll(500)
	} else {
		b.corrCount = 30 + b.roll(200)
	}

	if b.oneIn(20) {
		b.intersectIn = 400
	} else {
		b.intersectIn = b.roll(20)
	}

	starts := [3]trailStart{
		{
			X:      35,
			Width:  30,
			Y:      35,
			Height: 20,
		},

		{
			X:      10,
			Width:  15,
			Y:      10,
			Height: 15,
		},

		{
			X:      50,
			Width:  20,
			Y:      10,
			Height: 15,
		},
	}

	var stairs [3]StairPair
	occupied := make(map[Point]bool, len(stairs)*2)

	for index, start := range starts {
		pair, err := b.makeTrail(start)

		if err != nil {
			return stairs, fmt.Errorf("Dungeon:%d trail %d: %w", depth, index+1, err)
		}

		if occupied[pair.Down] ||
			occupied[pair.Up] || pair.Down == pair.Up {
			return stairs, fmt.Errorf("Dungeon:%d trail %d overlaps another stair", depth, index+1)
		}

		occupied[pair.Down] = true
		occupied[pair.Up] = true
		stairs[index] = pair

		b.grid[pair.Down.Y][pair.Down.X] = '>'
		b.grid[pair.Up.Y][pair.Up.X] = '<'
	}

	// dungeon.cc:5709 connects every pair of down-stair trail starts.
	for first := 0; first < len(stairs); first++ {
		for second := first + 1; second < len(stairs); second++ {
			b.connect(stairs[first].Down, stairs[second].Down)
		}
	}

	b.makeRooms()

	// _builder_extras chooses river_type on D:1-2 but cannot alter terrain
	// until absdepth0 > 8. Keep that source draw after room generation.
	b.oneIn(5 + depth - 1)

	if !b.stairsConnected(stairs) {
		return stairs, fmt.Errorf("Dungeon:%d basic layout has disconnected stairs", depth)
	}

	return stairs, nil
}

func (b *builder) roll(n int) int {
	if n <= 1 || b.badRandom {
		return 0
	}

	bound := uint64(n)
	threshold := -bound % bound

	for attempt := 0; attempt < 16; attempt++ {
		value := b.next()

		if value >= threshold {
			return int(value % bound)
		}
	}

	b.badRandom = true

	return 0
}

func (b *builder) oneIn(n int) bool {
	return b.roll(n) == 0
}

func (b *builder) chanceIn(chance, total int) bool {
	if chance <= 0 {
		return false
	}

	if chance >= total {
		return true
	}

	return b.roll(total) < chance
}

func (b *builder) inBounds(point Point) bool {
	return point.X > 0 && point.X < width-1 && point.Y > 0 && point.Y < height-1
}

func (b *builder) stairsConnected(stairs [3]StairPair) bool {
	start := stairs[0].Down
	visited := map[Point]bool{start: true}
	queue := []Point{start}

	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]

		for _, direction := range cardinalDirections {
			next := Point{
				X: current.X + direction.X,
				Y: current.Y + direction.Y,
			}

			if !b.inBounds(next) ||
				visited[next] || b.grid[next.Y][next.X] == '#' {
				continue
			}

			visited[next] = true
			queue = append(queue, next)
		}
	}

	for _, pair := range stairs {
		if !visited[pair.Down] || !visited[pair.Up] {
			return false
		}
	}

	return true
}
