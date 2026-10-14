package monster

import "fmt"

// OffLevelRecovery is the HD-1 ordinary animal case of Crawl's off-level
// regeneration. Its natural rate resolves to 10 hundredths of HP per turn.
// Source: monster.cc:2928-2955 and timed-effects.cc:749.
func OffLevelRecovery(roller Roller, turns int) (int, error) {
	if roller == nil || turns < 0 {
		return 0, fmt.Errorf("invalid off-level recovery turns %d", turns)
	}

	whole := turns / 10
	remainder := turns % 10 * 10

	if remainder == 0 {
		return whole, nil
	}

	roll, err := roller.Intn("offlevel", 100)

	if err != nil {
		return 0, err
	}

	if roll < remainder {
		whole++
	}

	return whole, nil
}

// OffLevelMoveCount follows the source's speed-scaled, 50-step catch-up cap.
// Source: timed-effects.cc:516-519.
func OffLevelMoveCount(turns, speed int) int {
	if turns <= 0 || speed <= 0 {
		return 0
	}

	if turns > 499/speed {
		return 50
	}

	return turns * speed / 10
}
