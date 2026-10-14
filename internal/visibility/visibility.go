// Package visibility computes DCSS-style sight over opaque dungeon terrain.
package visibility

import (
	"fmt"
	"math"
	"sort"
)

const maxRadius = 8

type offset struct {
	x, y int
}
type rayCell struct {
	offset
	enter float64
}
type ray []offset

// The source enumerates rational rays in one quadrant, then mirrors them.
// Their diamond-grid footprints are immutable after construction.
var candidateRays = buildRays()

func gcd(a, b int) int {
	for b != 0 {
		a, b = b, a%b
	}

	return a
}

func diamondEntry(sx, sy, dx, dy float64, x, y int) (float64, bool) {
	lo, hi := 0.0, math.Inf(1)
	clip := func(value, slope, center float64) bool {
		low, high := center-0.5, center+0.5

		if slope == 0 {
			return value > low && value < high
		}

		a, b := (low-value)/slope, (high-value)/slope

		if a > b {
			a, b = b, a
		}

		if a > lo {
			lo = a
		}

		if b < hi {
			hi = b
		}

		return hi-lo > 1e-10
	}

	if !clip(sx+sy, dx+dy, float64(x+y+1)) {
		return 0, false
	}

	if !clip(sx-sy, dx-dy, float64(x-y)) {
		return 0, false
	}

	return lo, hi-lo > 1e-10
}

func footprint(sx, sy, dx, dy float64) ray {
	var cells []rayCell

	for y := 0; y <= maxRadius; y++ {
		for x := 0; x <= maxRadius; x++ {
			if x == 0 && y == 0 {
				continue
			}

			if enter, ok := diamondEntry(sx, sy, dx, dy, x, y); ok {
				cells = append(cells, rayCell{
					offset{
						x: x,
						y: y,
					},
					enter,
				})
			}
		}
	}

	sort.Slice(cells, func(i, j int) bool {
		return cells[i].enter < cells[j].enter
	})
	result := make(ray, 0, len(cells))
	previous := offset{}

	for _, cell := range cells {
		if cell.x-previous.x > 1 || cell.y-previous.y > 1 {
			return nil
		}

		result = append(result, cell.offset)
		previous = cell.offset
	}

	return result
}

func buildRays() []ray {
	seen := map[string]bool{}
	var result []ray
	add := func(sx, sy, dx, dy float64) {
		cells := footprint(sx, sy, dx, dy)

		if len(cells) == 0 {
			return
		}

		key := make([]byte, len(cells))

		for i, c := range cells {
			key[i] = byte(c.x*9 + c.y)
		}

		if seen[string(key)] {
			return
		}

		seen[string(key)] = true
		result = append(result, cells)
	}
	add(0.5, 0.5, 0, 1)
	add(0.5, 0.5, 1, 0)
	const maxAngle = 2*maxRadius - 2

	for xAngle := 1; xAngle <= maxAngle; xAngle++ {
		for yAngle := 1; yAngle <= maxAngle; yAngle++ {
			if gcd(xAngle, yAngle) != 1 {
				continue
			}

			for intercept := 1; intercept < 2*yAngle; intercept++ {
				start := float64(intercept) / float64(2*yAngle)
				add(start, 0.5, float64(xAngle), float64(yAngle))
				add(0.5, start, float64(yAngle), float64(xAngle))
			}
		}
	}

	return result
}

// Compute returns a row-major mask of cells visible from the origin.
func Compute(rows []string, originX, originY, radius int) ([]bool, error) {
	if radius < 1 || radius > maxRadius {
		return nil, fmt.Errorf("visibility radius %d outside 1..%d", radius, maxRadius)
	}

	if len(rows) == 0 || len(rows[0]) == 0 {
		return nil, fmt.Errorf("empty terrain")
	}

	width := len(rows[0])

	for y, row := range rows {
		if len(row) != width {
			return nil, fmt.Errorf("terrain row %d has width %d, want %d", y, len(row), width)
		}

		for x := 0; x < width; x++ {
			switch row[x] {
			case '#', '.', '+', '\'', '<', '>':
			default:
				return nil, fmt.Errorf("unknown terrain %q at (%d,%d)", row[x], x, y)
			}
		}
	}

	if originX < 0 || originX >= width || originY < 0 || originY >= len(rows) ||
		rows[originY][originX] == '#' || rows[originY][originX] == '+' {
		return nil, fmt.Errorf("invalid sight origin (%d,%d)", originX, originY)
	}

	visible := make([]bool, width*len(rows))
	visible[originY*width+originX] = true

	for _, sign := range [][2]int{
		{1, 1},
		{-1, 1},
		{-1, -1},
		{1, -1},
	} {
		for _, ray := range candidateRays {
			for _, cell := range ray {
				if cell.x > radius || cell.y > radius {
					break
				}

				x, y := originX+sign[0]*cell.x, originY+sign[1]*cell.y

				if x < 0 || x >= width || y < 0 || y >= len(rows) {
					break
				}

				visible[y*width+x] = true

				if rows[y][x] == '#' || rows[y][x] == '+' {
					break
				}
			}
		}
	}

	return visible, nil
}
