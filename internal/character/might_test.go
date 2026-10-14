package character

import (
	"fmt"
	"testing"
)

type mightRoller struct {
	value, calls int
}

func (r *mightRoller) Intn(stream string, bound int) (int, error) {
	if stream != "potion" || bound != 40 {
		return 0, fmt.Errorf("unexpected %s/%d", stream, bound)
	}
	r.calls++
	return r.value, nil
}

func TestMightPotionDurationAndCap(t *testing.T) {
	for _, tc := range []struct {
		old, roll, want int
		message         string
	}{
		{
			old:     0,
			roll:    0,
			want:    350,
			message: "You feel very mighty all of a sudden.",
		},
		{
			old:     0,
			roll:    39,
			want:    740,
			message: "You feel very mighty all of a sudden.",
		},
		{
			old:     350,
			roll:    39,
			want:    800,
			message: "You feel mightier all of a sudden.",
		},
	} {
		rng := &mightRoller{value: tc.roll}
		got, message, err := MightPotionDuration(rng, tc.old)
		if err != nil || got != tc.want || message != tc.message || rng.calls != 1 {
			t.Fatalf("old %d roll %d: duration %d, message %q, draws %d, err %v", tc.old, tc.roll, got, message, rng.calls, err)
		}
	}
}

func TestMightDurationDecay(t *testing.T) {
	for _, tc := range []struct {
		old, cost, want int
		ended           bool
	}{
		{
			old:   350,
			cost:  10,
			want:  340,
			ended: false,
		},
		{
			old:   9,
			cost:  9,
			want:  0,
			ended: true,
		},
		{
			old:   9,
			cost:  10,
			want:  0,
			ended: true,
		},
		{
			old:   0,
			cost:  10,
			want:  0,
			ended: false,
		},
	} {
		got, ended, err := DecayMight(tc.old, tc.cost)
		if err != nil || got != tc.want || ended != tc.ended {
			t.Fatalf("decay %d by %d = %d/%v, %v", tc.old, tc.cost, got, ended, err)
		}
	}
}

func TestMightRulesRejectInvalidStateBeforeDrawing(t *testing.T) {
	rng := &mightRoller{value: 0}
	for _, old := range []int{-1, 801} {
		if _, _, err := MightPotionDuration(rng, old); err == nil || rng.calls != 0 {
			t.Fatalf("old %d accepted or drew", old)
		}
	}
	if _, _, err := DecayMight(1, -1); err == nil {
		t.Fatal("negative cost accepted")
	}
}
