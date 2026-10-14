package monster

import (
	"fmt"
	"testing"
)

type scriptedRoll struct{ bound, value int }
type scriptedRoller struct{ rolls []scriptedRoll }

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
		{"minimum", append([]scriptedRoll{{100, 25}, {16, 0}}, append(sevenRolls(17, 0), scriptedRoll{
			10,
			7,
		})...), 1},
		{"maximum", append([]scriptedRoll{{100, 25}, {16, 15}}, append(sevenRolls(17, 16), scriptedRoll{
			10,
			0,
		})...), 4},
		{"variance-round-up", append([]scriptedRoll{{100, 0}, {18, 9}}, append(sevenRolls(19, 9), scriptedRoll{
			10,
			0,
		})...), 3},
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
			bound,
			value,
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
	if _, err := RollHP(&scriptedRoller{rolls: []scriptedRoll{{100, 100}}}, 25); err == nil {
		t.Fatal("out-of-range roll accepted")
	}
}
