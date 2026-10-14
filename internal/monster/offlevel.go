package monster

import "fmt"

// OffLevelRecovery applies Crawl's source rate in hundredths of HP per away
// turn. HD-1 ordinary animals use 10; fast-regenerating worms use 100.
// Source: monster.cc:2928-2955 and timed-effects.cc:749.
func OffLevelRecovery(roller Roller, turns, rate int) (int, error) {
	const maximumInt = int(^uint(0) >> 1)

	if roller == nil || turns < 0 || rate <= 0 || rate > 100 ||
		turns > maximumInt/rate {
		return 0, fmt.Errorf("invalid off-level recovery turns %d at rate %d", turns, rate)
	}

	units := turns * rate
	whole := units / 100
	remainder := units % 100

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
