package monster

import "fmt"

// JackalFollowerCount follows the one-to-three follower range in
// mon-place.cc:1779. random_var(1,4) excludes four; see random-var.cc:18-23.
func JackalFollowerCount(roller Roller) (int, error) {
	if roller == nil {
		return 0, fmt.Errorf("jackal band requires a roller")
	}

	roll, err := roller.Intn("bands", 3)

	if err != nil {
		return 0, err
	}

	if roll < 0 || roll >= 3 {
		return 0, fmt.Errorf("jackal follower roll %d outside [0,3)", roll)
	}

	return roll + 1, nil
}
