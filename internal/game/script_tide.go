package game

import "fmt"

func (grid scriptGrid) ShoalsHeight(levelID, x, y int) (int, bool) {
	level := grid.levels[levelID]

	if level == nil {
		return 0, false
	}

	return level.ShoalsHeightAt(x, y)
}

func (grid scriptGrid) ShoalsTideClock(levelID int) (
	height, velocity int,
	lastAut int64,
	ok bool,
) {
	level := grid.levels[levelID]

	if level == nil {
		return 0, 0, 0, false
	}

	return level.ShoalsTideClock()
}

func (grid scriptGrid) SetShoalsTideClock(
	levelID, height, velocity int,
	lastAut int64,
) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing Shoals level %d", levelID)
	}

	return level.SetShoalsTideClock(height, velocity, lastAut)
}
