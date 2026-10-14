package levelgen

// makeRooms follows the two room passes in dgn-layouts.cc:108-124. The
// source's rare large-room and diamond branches cannot run on D:1-2.
func (b *builder) makeRooms() {
	doorLevel := b.roll(11)
	roomSize := 4 + b.roll(5)
	roomSize += b.roll(6)

	// random2avg(29, 2) draws 29 and then 30 before integer division.
	ordinaryCount := 5 + (b.roll(29)+b.roll(30))/2
	roomCount := ordinaryCount
	if b.roll(636+49) < 49 {
		roomCount = 100
	}

	if b.roll(636+49+15) < 15 {
		roomCount = 1
	}

	b.makeRandomRooms(roomCount, 2+b.roll(8), doorLevel, 50, 40, roomSize)
	b.makeRandomRooms(1+b.roll(3), 1, doorLevel, 55, 45, 6)
}

// The source retries failed room candidates and skips a room after 31
// failures. With no vault masks on these first two levels, every candidate
// rectangle is in bounds and needs only the perimeter connection check.
func (b *builder) makeRandomRooms(count, maxDoors, doorLevel, maxX, maxY, maxRoomSize int) {
	failures := 0
	for completed := 0; completed < count; {
		left := 8 + b.roll(maxX)
		top := 8 + b.roll(maxY)
		right := left + 2 + b.roll(maxRoomSize)
		bottom := top + 2 + b.roll(maxRoomSize)

		if b.makeRoom(left, top, right, bottom, maxDoors, doorLevel) {
			completed++
			continue
		}

		failures++
		if failures > 30 {
			failures = 0
			completed++
		}
	}
}

func (b *builder) makeRoom(left, top, right, bottom, maxDoors, doorLevel int) bool {
	connections := 0
	diagonal := 0
	for x := left; x <= right; x++ {
		if b.goodDoorSpot(x, top) {
			connections++
		}

		if b.goodDoorSpot(x, bottom) {
			connections++
		}
	}

	for y := top + 1; y < bottom; y++ {
		if b.goodDoorSpot(left, y) {
			connections++
		}

		if b.goodDoorSpot(right, y) {
			connections++
		}
	}

	for _, corner := range [4]Point{
		{
			X: left,
			Y: top,
		},
		{
			X: right,
			Y: top,
		},
		{
			X: left,
			Y: bottom,
		},
		{
			X: right,
			Y: bottom,
		},
	} {
		if b.goodDoorSpot(corner.X, corner.Y) {
			diagonal++
		}
	}

	if maxDoors == 1 && connections+diagonal > 1 {
		return false
	}

	if connections == 0 || connections > maxDoors {
		return false
	}

	for y := top; y <= bottom; y++ {
		for x := left; x <= right; x++ {
			// Closed doors are solid and do not have dry floor in the
			// source, so a room absorbs them as ordinary floor.
			if b.grid[y][x] == '#' || b.grid[y][x] == '+' {
				b.grid[y][x] = '.'
			}
		}
	}

	// The adjacent corridor becomes a door only when walls flank it. This
	// leaves room openings that are wider than one cell as ordinary floor.
	for y := top + 1; y < bottom; y++ {
		b.maybeDoor(left-1, y, 0, 1, doorLevel)
		b.maybeDoor(right+1, y, 0, 1, doorLevel)
	}

	for x := left + 1; x < right; x++ {
		b.maybeDoor(x, top-1, 1, 0, doorLevel)
		b.maybeDoor(x, bottom+1, 1, 0, doorLevel)
	}

	return true
}

func (b *builder) goodDoorSpot(x, y int) bool {
	terrain := b.grid[y][x]
	return terrain == '.' || terrain == '+'
}

func (b *builder) maybeDoor(x, y, flankX, flankY, doorLevel int) {
	if b.grid[y][x] != '.' ||
		!b.solid(x-flankX, y-flankY) ||
		!b.solid(x+flankX, y+flankY) {
		return
	}

	if b.chanceIn(doorLevel, 10) {
		b.grid[y][x] = '+'
	}
}

func (b *builder) solid(x, y int) bool {
	return b.grid[y][x] == '#' || b.grid[y][x] == '+'
}
