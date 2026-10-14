package levelgen

import (
	"reflect"
	"testing"
)

func sequence(seed uint64) func() uint64 {
	return func() uint64 {
		seed += 0x9e3779b97f4a7c15
		value := seed
		value = (value ^ (value >> 30)) * 0xbf58476d1ce4e5b9
		value = (value ^ (value >> 27)) * 0x94d049bb133111eb

		return value ^ (value >> 31)
	}
}

func TestBasicDungeonRejectsUnsupportedInputs(t *testing.T) {
	for _, depth := range []int{0, 3} {
		if _, err := BasicDungeon(depth, sequence(1)); err == nil {
			t.Fatalf("accepted Dungeon depth %d", depth)
		}
	}

	if _, err := BasicDungeon(1, nil); err == nil {
		t.Fatal("accepted nil random source")
	}
}

func TestBasicDungeonBoundsFailedSourceDraws(t *testing.T) {
	_, err := BasicDungeon(1, func() uint64 {
		return 0
	})

	if err == nil {
		t.Fatal("constant random source produced a valid layout")
	}
}

func TestBasicDungeonProducesStableConnectedGeometry(t *testing.T) {
	for _, depth := range []int{1, 2} {
		for seed := uint64(1); seed <= 128; seed++ {
			first, err := BasicDungeon(depth, sequence(seed))

			if err != nil {
				t.Fatalf("D:%d seed %d: %v", depth, seed, err)
			}

			second, err := BasicDungeon(depth, sequence(seed))

			if err != nil || !reflect.DeepEqual(first, second) {
				t.Fatalf("D:%d seed %d is not deterministic: %v", depth, seed, err)
			}

			assertBasicLayout(t, first)
		}
	}
}

func TestRoomRequiresAPerimeterConnectionAndCanMakeANarrowDoor(t *testing.T) {
	b := &builder{next: sequence(1)}

	for y := range b.grid {
		for x := range b.grid[y] {
			b.grid[y][x] = '#'
		}
	}

	if b.makeRoom(8, 8, 12, 12, 1, 10) {
		t.Fatal("accepted a room with no corridor connection")
	}

	b.grid[10][7] = '.'
	b.grid[10][8] = '.'
	b.grid[9][9] = '+'

	if !b.makeRoom(8, 8, 12, 12, 1, 10) {
		t.Fatal("rejected a room with one corridor connection")
	}

	if b.grid[10][7] != '+' || b.grid[9][9] != '.' {
		t.Fatalf("narrow entrance and room interior = %q, %q", b.grid[10][7], b.grid[9][9])
	}
}

func TestBasicDungeonCanPlaceClosedDoors(t *testing.T) {
	doors := 0

	for seed := uint64(1); seed <= 32; seed++ {
		layout, err := BasicDungeon(1, sequence(seed))

		if err != nil {
			t.Fatal(err)
		}

		for _, row := range layout.Rows {
			for _, terrain := range row {
				if terrain == '+' {
					doors++
				}
			}
		}
	}

	if doors == 0 {
		t.Fatal("no source-shaped rooms placed a closed door")
	}
}

func assertBasicLayout(t *testing.T, layout Layout) {
	t.Helper()

	if len(layout.Rows) != 70 {
		t.Fatalf("got %d rows, want 70", len(layout.Rows))
	}

	stairs := make(map[Point]byte)

	for index, pair := range layout.Stairs {
		for _, entry := range []struct {
			point Point
			glyph byte
		}{
			{
				point: pair.Up,
				glyph: '<',
			},

			{
				point: pair.Down,
				glyph: '>',
			},
		} {
			if _, duplicate := stairs[entry.point]; duplicate {
				t.Fatalf("stair pair %d duplicates %v", index, entry.point)
			}

			stairs[entry.point] = entry.glyph
		}
	}

	for y, row := range layout.Rows {
		if len(row) != 80 {
			t.Fatalf("row %d has width %d, want 80", y, len(row))
		}

		for x := range row {
			terrain := row[x]

			if (x == 0 ||
				y == 0 ||
				x == 79 ||
				y == 69) &&
				terrain != '#' {
				t.Fatalf("non-rock border at (%d,%d): %q", x, y, terrain)
			}

			switch terrain {
			case '#', '.', '+', '<', '>':

			default:
				t.Fatalf("unknown terrain %q at (%d,%d)", terrain, x, y)
			}
		}
	}

	for point, glyph := range stairs {
		if layout.Rows[point.Y][point.X] != glyph {
			t.Fatalf("stair %v has %q, want %q", point, layout.Rows[point.Y][point.X], glyph)
		}
	}

	start := layout.Stairs[0].Down
	visited := map[Point]bool{start: true}
	queue := []Point{start}

	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]

		for _, direction := range []Point{
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
		} {
			next := Point{
				X: current.X + direction.X,
				Y: current.Y + direction.Y,
			}

			if next.X < 0 ||
				next.X >= 80 ||
				next.Y < 0 ||
				next.Y >= 70 ||
				visited[next] || layout.Rows[next.Y][next.X] == '#' {
				continue
			}

			visited[next] = true
			queue = append(queue, next)
		}
	}

	for point := range stairs {
		if !visited[point] {
			t.Fatalf("stair %v is disconnected", point)
		}
	}
}
