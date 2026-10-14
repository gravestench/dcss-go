package monster

import (
	"fmt"
	"testing"
)

type scriptedRoll struct {
	bound int
	value int
}
type scriptedRoller struct {
	rolls []scriptedRoll
}

func (s *scriptedRoller) Intn(stream string, bound int) (int, error) {
	if stream != "monster_hp" || len(s.rolls) == 0 || s.rolls[0].bound != bound {
		return 0, fmt.Errorf("unexpected roll %s/%d, remaining %+v", stream, bound, s.rolls)
	}

	value := s.rolls[0].value
	s.rolls = s.rolls[1:]

	return value, nil
}

func TestRatHPSourceRollOrderAndBounds(t *testing.T) {
	for _, tc := range []struct {
		name  string
		rolls []scriptedRoll
		want  int
	}{
		{
			name: "minimum",
			rolls: append([]scriptedRoll{
				{
					bound: 100,
					value: 25,
				},
				{
					bound: 16,
					value: 0,
				},
			}, append(sevenRolls(17, 0), scriptedRoll{
				bound: 10,
				value: 7,
			})...),
			want: 1,
		},
		{
			name: "maximum",
			rolls: append([]scriptedRoll{
				{
					bound: 100,
					value: 25,
				},
				{
					bound: 16,
					value: 15,
				},
			}, append(sevenRolls(17, 16), scriptedRoll{
				bound: 10,
				value: 0,
			})...),
			want: 4,
		},
		{
			name: "variance-round-up",
			rolls: append([]scriptedRoll{
				{
					bound: 100,
					value: 0,
				},
				{
					bound: 18,
					value: 9,
				},
			}, append(sevenRolls(19, 9), scriptedRoll{
				bound: 10,
				value: 0,
			})...),
			want: 3,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rng := &scriptedRoller{rolls: tc.rolls}
			hp, err := RollHP(rng, 25)

			if err != nil || hp != tc.want || len(rng.rolls) != 0 {
				t.Fatalf("HP = %d, err %v, rolls %+v", hp, err, rng.rolls)
			}
		})
	}
}

func sevenRolls(bound, value int) []scriptedRoll {
	rolls := make([]scriptedRoll, 7)

	for i := range rolls {
		rolls[i] = scriptedRoll{
			bound: bound,
			value: value,
		}
	}

	return rolls
}

func TestRollHPRejectsInvalidInputsAndRolls(t *testing.T) {
	for _, avg := range []int{-1, 0} {
		if _, err := RollHP(&scriptedRoller{}, avg); err == nil {
			t.Fatalf("average %d accepted", avg)
		}
	}

	if _, err := RollHP(nil, 25); err == nil {
		t.Fatal("nil roller accepted")
	}

	if _, err := RollHP(&scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 100,
				value: 100,
			},
		},
	}, 25); err == nil {
		t.Fatal("out-of-range roll accepted")
	}
}
