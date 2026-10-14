package monster

import (
	"fmt"
	"testing"
)

type freezeRoller struct {
	value int
	calls int
}

func (r *freezeRoller) Intn(stream string, bound int) (int, error) {
	if stream != "monster_spell" || bound != 5 {
		return 0, fmt.Errorf("unexpected Freeze roll %s/%d", stream, bound)
	}

	r.calls++

	return r.value, nil
}

func TestEndoplasmFreezeRollsOneFiveSidedDie(t *testing.T) {
	for _, test := range []struct {
		roll int
		want int
	}{
		{
			roll: 0,
			want: 1,
		},

		{
			roll: 4,
			want: 5,
		},
	} {
		roller := &freezeRoller{value: test.roll}
		damage, err := FreezeDamage(roller, 1)

		if err != nil ||
			damage != test.want ||
			roller.calls != 1 {
			t.Fatalf("Freeze damage %d, calls %d, error %v",
				damage, roller.calls, err)
		}
	}
}
