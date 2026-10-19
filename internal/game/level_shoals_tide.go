package game

import (
	"fmt"

	"crawl/internal/save"
	"crawl/internal/terrain"
)

const (
	shoalsBranchID      = "BRANCH_SHOALS"
	shoalsFloorHeight   = 0
	shoalsShallowHeight = -30
	shoalsDeepHeight    = -31
	shoalsRockHeight    = 135
	shoalsStoneHeight   = 400
)

// InitShoalsTide derives a minimal elevation map from authored terrain. A
// Shoals generator can replace these values with its smooth island heights.
// Keeping elevations independent of current cells lets repeated tides reveal
// the same coast, even after water has temporarily covered the floor.
func (l *Level) InitShoalsTide() {
	if l.shoalsHeights != nil {
		return
	}

	l.shoalsHeights = make([][]int, len(l.terrain))

	for y, row := range l.terrain {
		l.shoalsHeights[y] = make([]int, len(row))

		for x, feature := range row {
			l.shoalsHeights[y][x] = shoalsFeatureHeight(feature)
		}
	}

	l.tideVelocity = 2
}

// shoalsFeatureHeight matches the fixed feature thresholds in DCSS. An
// explicit heightmap can contain intermediate elevations between thresholds.
func shoalsFeatureHeight(feature terrain.ID) int {
	switch feature {
	case terrain.StoneWall:
		return shoalsStoneHeight

	case terrain.ShallowWater:
		return shoalsShallowHeight

	case terrain.DeepWater, terrain.OpenSea:
		return shoalsDeepHeight

	case terrain.Floor:
		return shoalsFloorHeight

	default:
		if terrain.Walkable(feature) {
			return shoalsFloorHeight
		}

		return shoalsRockHeight
	}
}

// SetShoalsHeights accepts a generator's elevations before the tide starts.
func (l *Level) SetShoalsHeights(heights [][]int) error {
	if len(heights) != len(l.terrain) {
		return fmt.Errorf("level %d Shoals heightmap has wrong row count", l.ID)
	}

	copyRows := make([][]int, len(heights))

	for y, row := range heights {
		if len(row) != l.width {
			return fmt.Errorf("level %d Shoals heightmap row %d has wrong width", l.ID, y)
		}

		copyRows[y] = append([]int(nil), row...)
	}

	l.shoalsHeights = copyRows

	if l.tideVelocity == 0 {
		l.tideVelocity = 2
	}

	return nil
}

func (l *Level) ShoalsHeightAt(x, y int) (int, bool) {
	if l.shoalsHeights == nil || !l.inBounds(x, y) {
		return 0, false
	}

	return l.shoalsHeights[y][x], true
}

func (l *Level) ShoalsTideClock() (height, velocity int, lastAut int64, ok bool) {
	if l.shoalsHeights == nil {
		return 0, 0, 0, false
	}

	return l.tideHeight, l.tideVelocity, l.tideLastAut, true
}

func (l *Level) SetShoalsTideClock(height, velocity int, lastAut int64) error {
	if l.shoalsHeights == nil ||
		height < -36 ||
		height > 50 ||
		velocity == 0 ||
		lastAut < l.tideLastAut {
		return fmt.Errorf("level %d has invalid Shoals tide clock", l.ID)
	}

	l.tideHeight = height
	l.tideVelocity = velocity
	l.tideLastAut = lastAut

	return nil
}

func (l *Level) shoalsTideRecord() *save.ShoalsTideRecord {
	if l.shoalsHeights == nil {
		return nil
	}

	heights := make([][]int, len(l.shoalsHeights))

	for y, row := range l.shoalsHeights {
		heights[y] = append([]int(nil), row...)
	}

	return &save.ShoalsTideRecord{
		Heights:  heights,
		Height:   l.tideHeight,
		Velocity: l.tideVelocity,
		LastAut:  l.tideLastAut,
	}
}
