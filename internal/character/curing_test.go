package character

import (
	"fmt"
	"testing"
)

type curingRoller struct {
	bound, value, calls int
}

func (r *curingRoller) Intn(stream string, bound int) (int, error) {
	if stream != "potion" || bound != r.bound {
		return 0, fmt.Errorf("unexpected curing draw %q/%d", stream, bound)
	}
	r.calls++
	return r.value, nil
}

func TestCuringHealsSourceRangeAndCapsAtMax(t *testing.T) {
	for _, tc := range []struct {
		current, max, roll, want int
	}{
		{1, 18, 0, 6}, {1, 18, 6, 12}, {15, 18, 6, 18}, {18, 18, 0, 18},
	} {
		rng := &curingRoller{bound: 7, value: tc.roll}
		got, err := CuringHP(rng, tc.current, tc.max)
		if err != nil || got != tc.want || rng.calls != 1 {
			t.Fatalf("HP %d/%d roll %d: got %d, err %v, calls %d; want %d", tc.current, tc.max, tc.roll, got, err, rng.calls, tc.want)
		}
	}
}

func TestCuringRejectsInvalidHPAndRollWithoutDraw(t *testing.T) {
	for _, tc := range []struct{ current, max int }{{-1, 18}, {19, 18}, {1, 0}, {0, 18}} {
		rng := &curingRoller{bound: 7}
		if _, err := CuringHP(rng, tc.current, tc.max); err == nil || rng.calls != 0 {
			t.Fatalf("accepted HP %d/%d, draws %d", tc.current, tc.max, rng.calls)
		}
	}
	rng := &curingRoller{bound: 7, value: 7}
	if _, err := CuringHP(rng, 1, 18); err == nil {
		t.Fatal("accepted out-of-range potion roll")
	}
}
